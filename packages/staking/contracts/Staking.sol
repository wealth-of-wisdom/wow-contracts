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

    mapping(bytes32 stakerAndBandLevel => uint16[] bandId)
        internal s_stakerBands;
    mapping(uint16 bandId => StakerBandData) internal s_stakerBand;
    mapping(uint16 poolId => Pool) internal s_poolData; // Pool data, poolId - 1-9lvl
    mapping(uint16 bandLevel => Band) internal s_bandData; // Band data, bandLevel - 1-9lvl

    FundDistribution[] internal s_fundDistributionData; // Any added funds data

    IERC20 internal s_usdtToken; // Token to be payed as reward
    IERC20 internal s_usdcToken; // Token to be payed as reward
    IERC20 internal s_wowToken; // Token to be staked

    uint256[] shares; // in 10**6 integrals, for divident calculation

    uint16 internal s_nextBandId;
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

    modifier mBandExists(uint16 bandLevel) {
        if (bandLevel == 0 || bandLevel > s_totalBands) {
            revert Errors.Staking__InvalidBand(bandLevel);
        }
        _;
    }

    modifier mBandBelongsToUser(address user, uint16 bandId) {
        if (s_stakerBand[bandId].owner == user) {
            revert Errors.Staking__InvalidBandId(bandId);
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
     * @param bandAllocationPercentage Percentage of the pool to be distributed to each band
     */
    function setPool(
        uint16 poolId,
        uint48 distributionPercentage,
        uint48[] memory bandAllocationPercentage
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
        pool.bandAllocationPercentage = bandAllocationPercentage;

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
        mBandExists(bandLevel)
    {
        // Checks: amount must be in pool bounds
        if (accessiblePools.length > s_totalPools)
            revert Errors.Staking__MaximumLevelExceeded();

        // Checks: checks if timespan valid
        if (stakingTimespan < MONTH) {
            revert Errors.Staking__InvalidStakingTimespan(stakingTimespan);
        }

        // Effects: set band storage
        s_bandData[bandLevel] = Band({
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
     * @param   distributionPeriodStart  when distribution period started
     * @param   distributionPeriodEnd  when the distribution period ends
     */
    function distributeFunds(
        IERC20 token,
        uint256 amount,
        uint256 distributionPeriodStart,
        uint256 distributionPeriodEnd
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mTokenExists(token)
        mAmountNotZero(amount)
        mAmountNotZero(distributionPeriodStart)
        mAmountNotZero(distributionPeriodEnd)
    {
        // Effects: set fund distribution data
        FundDistribution memory fundDistributionData = FundDistribution({
            token: token,
            amount: amount,
            distributionPeriodStart: distributionPeriodStart,
            distributionPeriodEnd: distributionPeriodEnd
        });
        s_fundDistributionData.push(fundDistributionData);

        // Effects: distribute funds to pools
        uint16 totalPools = s_totalPools;
        for (uint16 poolId; poolId < totalPools; poolId++) {
            // amount * (100% * 10**6) / (distribution % * 10**6)
            uint256 poolAmount = ((amount *
                s_poolData[poolId].distributionPercentage) /
                PERCENTAGE_PRECISION);

            if (token == s_usdtToken) {
                s_poolData[poolId].totalUsdtPoolTokenAmount += poolAmount;
            } else {
                s_poolData[poolId].totalUsdcPoolTokenAmount += poolAmount;
            }
        }

        // Interaction: transfer the tokens to contract
        token.safeTransfer(address(this), amount);

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
    ) external mBandExists(bandLevel) mStakingTypeExists(stakingType) {
        Band memory bandData = _stakeBand(stakingType, bandLevel, msg.sender);
        // Interaction: transfer transaction funds to contract
        s_wowToken.safeTransferFrom(msg.sender, address(this), bandData.price);
        emit StakingSuccess(msg.sender, bandLevel);
    }

    /**
     * @notice  Unstake tokens at any time and claim earned rewards
     * @param   bandLevel  band level number
     * @param   bandId  Id of the band (0-max uint)
     */
    function unstake(
        uint16 bandLevel,
        uint16 bandId
    ) external mBandExists(bandLevel) {
        _unstakeBand(bandLevel, bandId, msg.sender);

        // Interaction: transfer transaction funds to user
        // @todo:
        // _claimRewards();
        // s_wowToken.safeTransferFrom(address(this), msg.sender, rewards+band.price);
        emit UnstakingSuccess(msg.sender, bandLevel);
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
        mBandExists(bandLevel)
        onlyRole(VESTING_ROLE)
        mStakingTypeExists(stakingType)
    {
        _stakeBand(stakingType, bandLevel, user);
        emit StakingSuccess(user, bandLevel);
    }

    /**
     * @notice  Unstake tokens at any time and claim earned rewards
     * @param   bandLevel  band level number
     * @param   bandId  Id of the band (0-max uint)
     * @param   user  address of user staking vested tokens
     */
    function unstakeVested(
        uint16 bandLevel,
        uint16 bandId,
        address user
    ) external mBandExists(bandLevel) onlyRole(VESTING_ROLE) {
        _unstakeBand(bandLevel, bandId, user);
        // @todo:
        // _claimRewards();
        // s_wowToken.safeTransferFrom(address(this), msg.sender, rewards);
        emit UnstakingSuccess(msg.sender, bandLevel);
    }

    //WIP
    // function deleteVestingUserData(
    //     address user
    // ) external onlyRole(VESTING_ROLE) {
    //     for (uint256 bandLevel; bandLevel < s_totalBands; bandLevel++) {
    //         bytes32 hashedStakerBandAndLevel = _getStakerBandAndLevelHash(
    //             user,
    //             bandLevel
    //         );
    //         delete s_bandOwnership[bandId];
    //     }
    // }

    /**
     * @notice  Upgradea any owned band to a new level
     * @param   oldBandLevel  Old band level in need of an upgrade
     * @param   newBandLevel  New band level being upgraded to
     * @param   bandId  Band Id being upgraded
     */
    function upgradeBand(
        uint16 oldBandLevel,
        uint16 newBandLevel,
        uint16 bandId
    )
        external
        mBandExists(oldBandLevel)
        mBandExists(newBandLevel)
        mBandBelongsToUser(msg.sender, bandId)
    {
        (
            Band memory oldBandData,
            Band memory newBandData,
            uint256 oldPoolLength,
            uint256 newPoolLength
        ) = _updateDataForBandLevelChange(oldBandLevel, newBandLevel, bandId);

        // Interaction: transfer transaction funds to contract
        uint256 priceDifference = newBandData.price - oldBandData.price;
        s_wowToken.safeTransferFrom(msg.sender, address(this), priceDifference);
        emit BandStateChanged(msg.sender, oldBandLevel, newBandLevel);
    }

    /**
     * @notice  Downgrade any owned band to a new level
     * @param   oldBandLevel  Old band level in need of an downgrade
     * @param   newBandLevel  New band level being downgraded to
     * @param   bandId  Band Id being downgraded
     */
    function downgradeBand(
        uint16 oldBandLevel,
        uint16 newBandLevel,
        uint16 bandId
    )
        external
        mBandExists(oldBandLevel)
        mBandExists(newBandLevel)
        mBandBelongsToUser(msg.sender, bandId)
    {
        (
            Band memory oldBandData,
            Band memory newBandData,
            uint256 oldPoolLength,
            uint256 newPoolLength
        ) = _updateDataForBandLevelChange(oldBandLevel, newBandLevel, bandId);

        // Interaction: transfer transaction funds to contract
        uint256 priceDifference = oldBandData.price - newBandData.price;
        s_wowToken.safeTransferFrom(address(this), msg.sender, priceDifference);
        emit BandStateChanged(msg.sender, oldBandLevel, newBandLevel);
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
            uint48[] memory bandAllocationPercentage,
            uint256 usdtTokenAmount,
            uint256 usdcTokenAmount
        )
    {
        Pool storage pool = s_poolData[poolId];
        distributionPercentage = pool.distributionPercentage;
        bandAllocationPercentage = pool.bandAllocationPercentage;
        usdtTokenAmount = pool.totalUsdtPoolTokenAmount;
        usdcTokenAmount = pool.totalUsdcPoolTokenAmount;
    }

    function getBand(
        uint16 bandId
    )
        external
        view
        returns (
            uint256 price,
            uint16[] memory accessiblePools,
            uint256 stakingTimespan
        )
    {
        Band storage band = s_bandData[bandId];
        price = band.price;
        accessiblePools = band.accessiblePools;
        stakingTimespan = band.stakingTimespan;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _getStakerBandAndLevelHash(
        address staker,
        uint16 bandLevel
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(staker, bandLevel));
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL  FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _stakeBand(
        StakingTypes stakingType,
        uint16 bandLevel,
        address user
    ) internal returns (Band memory bandData) {
        bytes32 hashedStakerBandAndLevel = _getStakerBandAndLevelHash(
            user,
            bandLevel
        );
        uint16 bandId = s_nextBandId++;
        s_stakerBands[hashedStakerBandAndLevel].push(bandId);
        bandData = s_bandData[bandLevel];

        // Effects: set staker and pool data
        s_stakerBand[bandId] = StakerBandData({
            stakingType: stakingType,
            owner: user,
            bandLevel: bandLevel,
            stakingStartTimestamp: block.timestamp,
            usdtRewardsClaimed: 0,
            usdcRewardsClaimed: 0
        });

        // @todo add user if needed
    }

    function _unstakeBand(
        uint16 bandLevel,
        uint16 bandId,
        address user
    ) internal mBandBelongsToUser(user, bandId) {
        Band memory bandData = s_bandData[bandLevel];
        bytes32 hashedStakerBandAndLevel = _getStakerBandAndLevelHash(
            user,
            bandLevel
        );

        //Effects: loop trough bandIds and remove required Id
        uint16[] storage bandIds = s_stakerBands[hashedStakerBandAndLevel];
        uint256 allBandIdsLength = s_stakerBands[hashedStakerBandAndLevel]
            .length;
        for (uint256 i; i < allBandIdsLength; i++) {
            if (bandIds[i] == bandId) {
                bandIds[i] = bandIds[allBandIdsLength - 1];
                bandIds.pop();
                break;
            }
        }
        s_stakerBands[hashedStakerBandAndLevel].push(bandId);
        delete s_stakerBand[bandId];

        // @todo remove user if needed
    }

    function _updateDataForBandLevelChange(
        uint16 oldBandLevel,
        uint16 newBandLevel,
        uint16 bandId
    )
        internal
        returns (
            Band memory oldBandData,
            Band memory newBandData,
            uint256 oldPoolLength,
            uint256 newPoolLength
        )
    {
        s_stakerBand[bandId].owner = msg.sender;
        s_stakerBand[bandId].bandLevel = newBandLevel;

        // Effects: get bands and pools that need to be upgraded
        oldBandData = s_bandData[oldBandLevel];
        newBandData = s_bandData[newBandLevel];

        oldPoolLength = oldBandData.accessiblePools.length;
        newPoolLength = newBandData.accessiblePools.length;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR UPGRADER ROLE
    //////////////////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {
        /// @dev This function is empty but uses a modifier to restrict access
    }
}
