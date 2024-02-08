//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IStaking} from "./interfaces/IStaking.sol";
import {Errors} from "./libraries/Errors.sol";

contract Staking is
    IStaking,
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    /*//////////////////////////////////////////////////////////////////////////
                                    LIBRARIES
    //////////////////////////////////////////////////////////////////////////*/

    using SafeERC20 for IERC20; // Wrappers around ERC20 operations that throw on failure
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    /*//////////////////////////////////////////////////////////////////////////
                                PRIVATE CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 private constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 private constant VESTING_ROLE = keccak256("VESTING_ROLE");
    uint128 private constant DECIMALS = 10 ** 6;
    uint128 private constant MONTH = 30 days;
    uint48 private constant PERCENTAGE_PRECISION = 10 ** 8; // 100% = 10**8

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    // Map user => bool (if user is staking)
    // 0 - false (not staking), 1 - true (is staking)
    EnumerableMap.AddressToUintMap internal s_users;

    mapping(address staker => uint256[] bandId) internal s_stakerBands;
    mapping(uint256 bandId => StakerBandData) internal s_bands;
    mapping(uint16 poolId => Pool) internal s_poolData; // Pool data, poolId - 1-9lvl
    mapping(uint16 bandLevel => Band) internal s_bandLevelData; // Band data, bandLevel - 1-9lvl

    FundDistribution[] internal s_fundDistributionData; // Any added funds data
    mapping(bytes32 distributionIdAndPoolId => PoolDistribution) s_poolsDistribution;
    mapping(bytes32 distributionIdWithPoolIdAndStaker => StakerShares) s_stakerShares;

    IERC20 internal s_usdtToken; // Token to be payed as reward
    IERC20 internal s_usdcToken; // Token to be payed as reward
    IERC20 internal s_wowToken; // Token to be staked

    uint256[] sharesInMonth; // in 10**6 integrals, for divident calculation

    uint256 internal s_nextBandId;
    uint256 internal s_nextDistributionId;
    uint16 internal s_totalPools;
    uint16 internal s_totalBands;

    /*//////////////////////////////////////////////////////////////////////////
                            STORAGE FOR FUTURE UPGRADES
    //////////////////////////////////////////////////////////////////////////*/

    uint256[50] private __gap;

    /*//////////////////////////////////////////////////////////////////////////
                                  MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier mAddressNotZero(address addr) {
        if (addr == address(0)) {
            revert Errors.Staking__ZeroAddress();
        }
        _;
    }

    modifier mAmountNotZero(uint256 amount) {
        if (amount == 0) {
            revert Errors.Staking__ZeroAmount();
        }
        _;
    }

    modifier mBandLevelExists(uint16 bandLevel) {
        if (bandLevel == 0 || bandLevel > s_totalBands) {
            revert Errors.Staking__InvalidBandLevel(bandLevel);
        }
        _;
    }

    modifier mBandOwner(address user, uint256 bandId) {
        if (s_bands[bandId].owner != user) {
            revert Errors.Staking__NotBandOwner(bandId, user);
        }
        _;
    }

    modifier mPoolExists(uint16 poolId) {
        if (poolId == 0 || poolId > s_totalPools) {
            revert Errors.Staking__InvalidPoolId(poolId);
        }
        _;
    }

    modifier mStakingTypeExists(StakingTypes stakingType) {
        if (
            StakingTypes.FIX != stakingType || StakingTypes.FLEXI != stakingType
        ) revert Errors.Staking__InvalidStakingType();
        _;
    }

    modifier mTokenExists(IERC20 token) {
        if (token != s_usdtToken && token != s_usdcToken) {
            revert Errors.Staking__NonExistantToken();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(
        IERC20 usdtToken,
        IERC20 usdcToken,
        IERC20 wowToken,
        uint16 totalPools,
        uint16 totalBands
    )
        external
        initializer
        mAddressNotZero(address(usdtToken))
        mAddressNotZero(address(usdcToken))
        mAddressNotZero(address(wowToken))
        mAmountNotZero(totalPools)
        mAmountNotZero(totalBands)
    {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        // Effects: set the roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        // Effects: set the storage
        s_usdtToken = usdtToken;
        s_usdcToken = usdcToken;
        s_wowToken = wowToken;

        s_totalPools = totalPools;
        s_totalBands = totalBands;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS FOR DEFAULT ADMIN
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Set data for a pool which will be used for rewards distribution
     * @notice There can be only one pool with the same id
     * @notice When called for the first time, the pool will be created
     * @notice When called for the second time, the pool data will be overwritten
     * @param poolId Id of the pool (1-9)
     * @param distributionPercentage Percentage of the total rewards to be distributed to this pool
     */
    function setPool(
        uint16 poolId,
        uint48 distributionPercentage
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mPoolExists(poolId) {
        // Checks: distribution percentage should not exceed 100%
        if (distributionPercentage > PERCENTAGE_PRECISION) {
            revert Errors.Staking__InvalidDistributionPercentage(
                distributionPercentage
            );
        }
        // Effects: set the storage
        Pool storage pool = s_poolData[poolId];
        pool.distributionPercentage = distributionPercentage;

        // Effects: emit event
        emit PoolSet(poolId);
    }

    /**
     * @notice  Sets data of the selected band
     * @param   bandLevel  band level number
     * @param   price  band purchase price
     * @param   accessiblePools  list of pools that become
     *          accessible after band purchase
     * @param   stakingTimespan  time in months for how long
     *          staking will be conducted
     */
    function setBand(
        uint16 bandLevel,
        uint256 price,
        uint16[] memory accessiblePools,
        uint256 stakingTimespan
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAmountNotZero(price)
        mBandLevelExists(bandLevel)
    {
        // Checks: amount must be in pool bounds
        if (accessiblePools.length > s_totalPools)
            revert Errors.Staking__MaximumLevelExceeded();

        // Checks: checks if timespan valid
        if (stakingTimespan < MONTH) {
            revert Errors.Staking__InvalidStakingTimespan(stakingTimespan);
        }

        // Effects: set band storage
        s_bandLevelData[bandLevel] = Band({
            price: price,
            accessiblePools: accessiblePools,
            stakingTimespan: stakingTimespan
        });

        // Effects: emit event
        emit BandSet(bandLevel);
    }

    /**
     * @notice  Sets new total amount of bands used for staking
     * @param   newTotalBandsAmount  total amount of bands used for staking
     */
    function setTotalBandAmount(
        uint16 newTotalBandsAmount
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAmountNotZero(newTotalBandsAmount)
    {
        s_totalBands = newTotalBandsAmount;
        emit TotalBandAmountSet(newTotalBandsAmount);
    }

    /**
     * @notice  Sets new total amount of pools used for staking
     * @param   newTotalPoolAmount  total amount of pools used for staking
     */
    function setTotalPoolAmount(
        uint16 newTotalPoolAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAmountNotZero(newTotalPoolAmount) {
        s_totalPools = newTotalPoolAmount;
        emit TotalPoolAmountSet(newTotalPoolAmount);
    }

    /**
     * @notice  Administrator function for transfering funds
     *          to contract for pool distribution
     * @param   token  USDT/USDC token
     * @param   amount  amount to be distributed to pools
     */
    function distributeFunds(
        IERC20 token,
        uint256 amount
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mTokenExists(token)
        mAmountNotZero(amount)
    {
        uint256 distributionId = s_nextDistributionId++;

        // Effects: set fund distribution data
        FundDistribution memory fundDistribution = FundDistribution({
            id: distributionId,
            token: token,
            amount: amount,
            timestamp: block.timestamp
        });
        s_fundDistributionData.push(fundDistribution);

        uint16 totalPools = s_totalPools;

        // Loop through all pools and set the amount of tokens
        for (uint16 poolId; poolId < totalPools; poolId++) {
            bytes32 configHash = _getPoolHash(distributionId, poolId);

            // amount * (distribution % * 10**6) / (100% * 10**6)
            uint256 poolTokens = ((amount *
                s_poolData[poolId].distributionPercentage) /
                PERCENTAGE_PRECISION);

            // Effects: set pool distribution data
            PoolDistribution storage poolDistribution = s_poolsDistribution[
                configHash
            ];
            poolDistribution.token = token;
            poolDistribution.tokensAmount = poolTokens;
        }

        uint256 usersAmount = s_users.length();

        // Loop through all users and set the amount of shares
        for (uint256 userIndex; userIndex < usersAmount; userIndex++) {
            (address user, ) = s_users.at(userIndex);
            uint256[] memory bandIds = s_stakerBands[user];
            uint256 bandsAmount = bandIds.length;

            // Loop through all bands that user owns and set the amount of shares
            for (uint256 bandIndex; bandIndex < bandsAmount; bandIndex++) {
                uint256 bandId = bandIds[bandIndex];
                StakerBandData memory band = s_bands[bandId];
                uint256 userShares;

                // If staking type is FLEXI calculate shares based months passed
                if (band.stakingType == StakingTypes.FLEXI) {
                    // Calculate months that passed since staking start
                    uint256 monthsPassed = (block.timestamp -
                        band.stakingStartTimestamp) / MONTH;

                    // If at least 1 month passed, calculate shares based on months
                    if (monthsPassed > 0) {
                        userShares = sharesInMonth[monthsPassed - 1];
                    }
                }
                // Else type is FIX
                else {
                    // For FIX type, shares are set at the start and do not change over time
                    userShares = band.startingSharesAmount;
                }

                // If user has shares, add them to the pool
                if (userShares > 0) {
                    uint16[] memory pools = s_bandLevelData[band.bandLevel]
                        .accessiblePools;
                    uint256 poolsAmount = pools.length;

                    // Loop through all pools and set the amount of shares
                    for (
                        uint16 poolIndex;
                        poolIndex < poolsAmount;
                        poolIndex++
                    ) {
                        uint16 poolId = pools[poolIndex];
                        bytes32 poolConfigHash = _getPoolHash(
                            distributionId,
                            poolId
                        );

                        bytes32 stakerConfigHash = _getStakerHash(
                            distributionId,
                            poolId,
                            user
                        );

                        // Effects: increase pool shares
                        s_poolsDistribution[poolConfigHash]
                            .sharesAmount += userShares;

                        // Effects: increase user shares
                        s_stakerShares[stakerConfigHash].shares += userShares;
                    }
                }
            }
        }

        // Interaction: transfer the tokens to contract
        token.safeTransferFrom(msg.sender, address(this), amount);

        // Effects: emit event
        emit FundsDistributed(token, amount);
    }

    /**
     * @notice Withdraw the given amount of tokens from the contract
     * @param token Token to withdraw
     * @param amount Amount to withdraw
     */
    function withdrawTokens(
        IERC20 token,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Checks: the amount must be greater than 0
        if (amount == 0) {
            revert Errors.Staking__ZeroAmount();
        }

        uint256 balance = token.balanceOf(address(this));

        // Checks: the contract must have enough balance to withdraw
        if (balance < amount) {
            revert Errors.Staking__InsufficientContractBalance(balance, amount);
        }

        // Interaction: transfer the tokens to the sender
        token.safeTransfer(msg.sender, amount);

        emit TokensWithdrawn(token, msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice  Stake and lock tokens to earn rewards
     * @param   stakingType  enumerable type for flexi or fixed staking
     * @param   bandLevel  band level number
     */
    function stake(
        StakingTypes stakingType,
        uint16 bandLevel
    ) external mBandLevelExists(bandLevel) mStakingTypeExists(stakingType) {
        uint256 price = s_bandLevelData[bandLevel].price;

        // Effects: Create a new band and add it to the user
        _stakeBand(stakingType, bandLevel, msg.sender);

        // Interaction: transfer transaction funds to contract
        s_wowToken.safeTransferFrom(msg.sender, address(this), price);

        // Effects: emit event
        emit Staked(msg.sender, bandLevel, stakingType, false);
    }

    /**
     * @notice  Unstake tokens at any time and claim earned rewards
     * @param   bandId  Id of the band (0-max uint)
     */
    function unstake(uint256 bandId) external mBandOwner(msg.sender, bandId) {
        // Effects: delete band data
        _unstakeBand(bandId, msg.sender);

        // Interaction: transfer transaction funds to user
        // @todo: transfer rewards and initial price
        // _claimRewards();
        // s_wowToken.safeTransferFrom(address(this), msg.sender, rewards+band.price);

        // Effects: emit event
        emit Unstaked(msg.sender, bandId, false);
    }

    /**
     * @notice  Stakes vesting contract tokens to ear rewards
     * @param   stakingType  enumerable type for flexi or fixed staking
     * @param   bandLevel  band level number
     * @param   user  address of user staking vested tokens
     */
    function stakeVested(
        StakingTypes stakingType,
        uint16 bandLevel,
        address user
    )
        external
        onlyRole(VESTING_ROLE)
        mBandLevelExists(bandLevel)
        mStakingTypeExists(stakingType)
    {
        // Effects: Create a new band and add it to the user
        _stakeBand(stakingType, bandLevel, user);

        // Effects: emit event
        emit Staked(user, bandLevel, stakingType, true);
    }

    /**
     * @notice  Unstake tokens at any time and claim earned rewards
     * @param   bandId  Id of the band (0-max uint)
     * @param   user  address of user staking vested tokens
     */
    function unstakeVested(
        uint256 bandId,
        address user
    ) external onlyRole(VESTING_ROLE) mBandOwner(user, bandId) {
        // Effects: delete band data
        _unstakeBand(bandId, user);

        // @todo: transfer rewards
        // _claimRewards();
        // s_wowToken.safeTransferFrom(address(this), msg.sender, rewards);

        // Effects: emit event
        emit Unstaked(user, bandId, true);
    }

    // WIP
    // function deleteVestingUserData(
    //     address user
    // ) external onlyRole(VESTING_ROLE) {
    //     for (uint256 bandLevel; bandLevel < s_totalBands; bandLevel++) {
    //         bytes32 hashedStakerBandAndLevel = _getStakerAndBandLevelHash(
    //             user,
    //             bandLevel
    //         );
    //         delete s_bandOwnership[bandId];
    //     }
    // }

    /**
     * @notice  Upgradea any owned band to a new level
     * @param   bandId  Band Id being upgraded
     * @param   newBandLevel  New band level being upgraded to
     */
    function upgradeBand(
        uint256 bandId,
        uint16 newBandLevel
    ) external mBandOwner(msg.sender, bandId) mBandLevelExists(newBandLevel) {
        uint16 oldBandLevel = s_bands[bandId].bandLevel;

        // Checks: new band level must be higher than the old one
        if (newBandLevel <= oldBandLevel) {
            revert Errors.Staking__InvalidBandLevel(newBandLevel);
        }

        uint256 oldPrice = s_bandLevelData[oldBandLevel].price;
        uint256 newPrice = s_bandLevelData[newBandLevel].price;
        uint256 priceDifference = newPrice - oldPrice;

        // Effects: update band level
        s_bands[bandId].bandLevel = newBandLevel;

        // Interaction: transfer transaction funds to contract
        s_wowToken.safeTransferFrom(msg.sender, address(this), priceDifference);

        // Effects: emit event
        emit BandUpgaded(msg.sender, bandId, oldBandLevel, newBandLevel);
    }

    /**
     * @notice  Downgrade any owned band to a new level
     * @param   bandId  Band Id being downgraded
     * @param   newBandLevel  New band level being downgraded to
     */
    function downgradeBand(
        uint256 bandId,
        uint16 newBandLevel
    ) external mBandOwner(msg.sender, bandId) mBandLevelExists(newBandLevel) {
        uint16 oldBandLevel = s_bands[bandId].bandLevel;

        // Checks: new band level must be higher than the old one
        if (newBandLevel >= oldBandLevel) {
            revert Errors.Staking__InvalidBandLevel(newBandLevel);
        }

        uint256 oldPrice = s_bandLevelData[oldBandLevel].price;
        uint256 newPrice = s_bandLevelData[newBandLevel].price;
        uint256 priceDifference = oldPrice - newPrice;

        // Effects: update band level
        s_bands[bandId].bandLevel = newBandLevel;

        // Interaction: transfer transaction funds to contract
        s_wowToken.safeTransfer(msg.sender, priceDifference);

        // Effects: emit event
        emit BandDowngraded(msg.sender, bandId, oldBandLevel, newBandLevel);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the USDT token which is used for rewards distribution
     * @return IERC20 USDT token
     */
    function getTokenUSDT() external view returns (IERC20) {
        return s_usdtToken;
    }

    /**
     * @notice Returns the USDC token which is used for rewards distribution
     * @return IERC20 USDC token
     */
    function getTokenUSDC() external view returns (IERC20) {
        return s_usdcToken;
    }

    /**
     * @notice Returns the WOW token which is used staking by users
     * @return IERC20 WOW token
     */
    function getTokenWOW() external view returns (IERC20) {
        return s_wowToken;
    }

    /**
     * @notice Returns the total amount of pools users can stake in
     * @return uint16 Total amount of pools
     */
    function getTotalPools() external view returns (uint16) {
        return s_totalPools;
    }

    /**
     * @notice Returns the total amount of bands users can buy for staking
     * @return uint16 Total amount of bands
     */
    function getTotalBands() external view returns (uint16) {
        return s_totalBands;
    }

    function getPool(
        uint16 poolId
    )
        external
        view
        returns (
            uint48 distributionPercentage,
            uint256 usdtTokenAmount,
            uint256 usdcTokenAmount
        )
    {
        Pool memory pool = s_poolData[poolId];
        distributionPercentage = pool.distributionPercentage;
        usdtTokenAmount = pool.totalUsdtPoolTokenAmount;
        usdcTokenAmount = pool.totalUsdcPoolTokenAmount;
    }

    function getBand(
        uint16 bandLevel
    )
        external
        view
        returns (
            uint256 price,
            uint16[] memory accessiblePools,
            uint256 stakingTimespan
        )
    {
        Band memory band = s_bandLevelData[bandLevel];
        price = band.price;
        accessiblePools = band.accessiblePools;
        stakingTimespan = band.stakingTimespan;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL  FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _stakeBand(
        StakingTypes stakingType,
        uint16 bandLevel,
        address user
    ) internal {
        // Effects: increment bandId (variable is set before incrementing to start from 0)
        uint256 bandId = s_nextBandId++;

        // Effects: set staker band data
        StakerBandData storage band = s_bands[bandId];
        band.stakingType = stakingType;
        band.owner = user;
        band.bandLevel = bandLevel;
        band.stakingStartTimestamp = block.timestamp;

        // Effects: add bandId to the user
        s_stakerBands[user].push(bandId);

        // If currently added band is the first one for the user
        if (s_stakerBands[user].length == 1) {
            // Effects: add user to the map
            s_users.set(user, 1);
        }

        // Effects: emit event
        emit BandStaked(user, bandLevel, bandId);
    }

    function _unstakeBand(uint256 bandId, address user) internal {
        uint16 bandLevel = s_bands[bandId].bandLevel;

        // Effects: delete band data
        delete s_bands[bandId];

        // Effects: loop trough bandIds and remove required Id
        uint256[] storage bandIds = s_stakerBands[user];
        uint256 bandsIdsAmount = bandIds.length;
        for (uint256 i; i < bandsIdsAmount; i++) {
            if (bandIds[i] == bandId) {
                bandIds[i] = bandIds[bandsIdsAmount - 1];
                bandIds.pop();
                break;
            }
        }

        // If user had only one band left
        if (bandsIdsAmount == 1) {
            // Effects: remove user from the map
            s_users.remove(user);
        }

        // Effects: emit event
        emit BandUnstaked(user, bandLevel, bandId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR UPGRADER ROLE
    //////////////////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {
        /// @dev This function is empty but uses a modifier to restrict access
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _getPoolHash(
        uint256 distributionId,
        uint16 poolId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(distributionId, poolId));
    }

    function _getStakerHash(
        uint256 distributionId,
        uint16 poolId,
        address staker
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(distributionId, poolId, staker));
    }
}
