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
    uint48 private constant MONTH = 30 days;
    uint48 private constant SHARE = 1e6; // 1 share = 10^6
    uint48 private constant PERCENTAGE_PRECISION = 1e8; // 100% = 10^8

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    // Map user => bool (if user is staking)
    // 0 - false (not staking), 1 - true (is staking)
    EnumerableMap.AddressToUintMap internal s_users;

    // Map user => all the band ids that user owns
    mapping(address staker => uint256[] bandIds) internal s_stakerBands;

    // Map single band id => band data
    mapping(uint256 bandId => StakerBandData) internal s_bands;

    // Map pool id (1-9) => pool data
    mapping(uint16 poolId => Pool) internal s_poolData;

    // Map band level (1-9) => band data
    mapping(uint16 bandLevel => Band) internal s_bandLevelData;

    // Map token => all fund distributions
    // Array of all distributions is used for storing shares and tokens info
    mapping(IERC20 token => FundDistribution[]) internal s_fundDistributions;

    // Map single distribution id => pool id => pool distribution data
    mapping(bytes32 distributionIdAndPoolId => PoolDistribution)
        internal s_poolsDistribution;

    // Map single distribution id => pool id => staker address => staker shares data
    mapping(bytes32 distributionIdWithPoolIdAndStaker => StakerShares)
        internal s_stakerShares;

    // Token to be payed as reward
    IERC20 internal s_usdtToken;

    // Token to be payed as reward
    IERC20 internal s_usdcToken;

    // Token to be staked
    IERC20 internal s_wowToken;

    // Array of 24 integers, each representing the amount of shares
    // User owns in the pool for each month. Used for FLEXI staking
    // 0 index represents shares after 1 month, 1 index represents shares after 2 months, etc.
    // in 10**6 = 1 share
    uint48[] internal sharesInMonth;

    // Next unique band id to be used
    uint256 internal s_nextBandId;

    // Next unique distribution id to be used
    uint256 internal s_nextDistributionId;

    // Total amount of pools used for staking (currently, 9)
    uint16 internal s_totalPools;

    // Total amount of bands used for staking (currently, 9)
    uint16 internal s_totalBandLevels;

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
        if (bandLevel == 0 || bandLevel > s_totalBandLevels) {
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

    modifier mNotFixStakingType(uint256 bandId) {
        if (StakingTypes.FIX == s_bands[bandId].stakingType) {
            revert Errors.Staking__CantModifyFixTypeBand();
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
            StakingTypes.FIX != stakingType && StakingTypes.FLEXI != stakingType
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
        uint16 totalBandLevels
    )
        external
        initializer
        mAddressNotZero(address(usdtToken))
        mAddressNotZero(address(usdcToken))
        mAddressNotZero(address(wowToken))
        mAmountNotZero(totalPools)
        mAmountNotZero(totalBandLevels)
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
        s_totalBandLevels = totalBandLevels;
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
        emit PoolSet(poolId, distributionPercentage);
    }

    /**
     * @notice  Sets data of the selected band
     * @param   bandLevel  band level number
     * @param   price  band purchase price
     * @param   accessiblePools  list of pools that become
     *          accessible after band purchase
     */
    function setBandLevel(
        uint16 bandLevel,
        uint256 price,
        uint16[] calldata accessiblePools
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mBandLevelExists(bandLevel)
        mAmountNotZero(price)
    {
        // Checks: amount must be in pool bounds
        if (accessiblePools.length > s_totalPools) {
            revert Errors.Staking__MaximumLevelExceeded();
        }

        // Effects: set band storage
        s_bandLevelData[bandLevel] = Band({
            price: price,
            accessiblePools: accessiblePools
        });

        // Effects: emit event
        emit BandLevelSet(bandLevel, price, accessiblePools);
    }

    /**
     * @notice  Sets the total amount of shares that user is going to have
     *          at the end of each month of staking. Used for FLEXI staking
     * @param   totalSharesInMonth  array of shares for each month
     */
    function setSharesInMonth(
        uint48[] calldata totalSharesInMonth
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Effects: set the shares array
        sharesInMonth = totalSharesInMonth;

        // Effects: emit event
        emit SharesInMonthSet(totalSharesInMonth);
    }

    /**
     * @notice  Sets new total amount of bands used for staking
     * @param   newTotalBandsAmount  total amount of bands used for staking
     */
    function setTotalBandLevelsAmount(
        uint16 newTotalBandsAmount
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAmountNotZero(newTotalBandsAmount)
    {
        // Effects: set the total bands amount
        s_totalBandLevels = newTotalBandsAmount;

        // Effects: emit event
        emit TotalBandLevelsAmountSet(newTotalBandsAmount);
    }

    /**
     * @notice  Sets new total amount of pools used for staking
     * @param   newTotalPoolAmount  total amount of pools used for staking
     */
    function setTotalPoolAmount(
        uint16 newTotalPoolAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAmountNotZero(newTotalPoolAmount) {
        // Effects: set the total pools amount
        s_totalPools = newTotalPoolAmount;

        // Effects: emit event
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
        uint16 totalPools = s_totalPools;
        uint256 usersAmount = s_users.length();

        uint256 distributionId = _createFundDistribution(token, amount);

        // Effects: create all pool distributions for this fund distribution
        _createAllPoolDistributions(token, amount, distributionId, totalPools);

        // Loop through all users and set the amount of shares
        for (uint256 userIndex; userIndex < usersAmount; userIndex++) {
            (address user, ) = s_users.at(userIndex);

            // Effects: Loop through all bands and add shares to pools
            uint256[] memory userSharesPerPool = _addAllBandSharesToPools(
                user,
                distributionId,
                totalPools
            );

            // Effects: Loop through all pools and set the amount of shares for the user
            _addSharesToUser(
                user,
                distributionId,
                totalPools,
                userSharesPerPool
            );
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
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAmountNotZero(amount) {
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
        // Interraction: transfer staked tokens
        uint16 bandLevel = s_bands[bandId].bandLevel;
        uint256 stakedAmount = s_bandLevelData[bandLevel].price;
        s_wowToken.safeTransfer(msg.sender, stakedAmount);

        // Effects: delete band data
        _unstakeBand(bandId, msg.sender);

        // Interaction: transfer earned rewards to staker
        _claimRewardsFromPools(bandId);

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

        // Interaction: transfer earned rewards to staker
        _claimRewardsFromPools(bandId);

        // Effects: emit event
        emit Unstaked(user, bandId, true);
    }

    /**
     * @notice  Delete all user band data if beneficiary removed from vesting
     * @param   user  staker address
     */
    function deleteVestingUserData(
        address user
    ) external onlyRole(VESTING_ROLE) {
        uint256[] memory bandIds = s_stakerBands[user];
        uint256 bandsAmount = bandIds.length;

        // Loop through all bands that user owns and delete data
        for (uint256 bandIndex; bandIndex < bandsAmount; bandIndex++) {
            delete s_bands[bandIds[bandIndex]];
        }
        s_users.remove(user);
        delete s_stakerBands[user];
        emit VestingUserRemoved(msg.sender);
    }

    /**
     * @notice  Upgradea any owned band to a new level
     * @param   bandId  Band Id being upgraded
     * @param   newBandLevel  New band level being upgraded to
     */
    function upgradeBand(
        uint256 bandId,
        uint16 newBandLevel
    )
        external
        mBandOwner(msg.sender, bandId)
        mBandLevelExists(newBandLevel)
        mNotFixStakingType(bandId)
    {
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
    )
        external
        mBandOwner(msg.sender, bandId)
        mBandLevelExists(newBandLevel)
        mNotFixStakingType(bandId)
    {
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

    /**
     * @notice  Claim rewards for all pools and tokens
     * @notice  This function can be called by anyone
     */
    function claimAllRewards() external {
        // Loop through all pools and claim rewards for USDT and USDC
        for (uint16 poolId = 1; poolId <= s_totalPools; poolId++) {
            claimPoolRewards(s_usdtToken, poolId);
            claimPoolRewards(s_usdcToken, poolId);
        }

        // Effects: emit event
        emit AllRewardsClaimed(msg.sender);
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
        return s_totalBandLevels;
    }

    /**
     * @notice  Returns the next consecutive band Id number to be assigned
     * @return  uint256  Next band Id
     */
    function getNextBandId() external view returns (uint256) {
        return s_nextBandId;
    }

    /**
     * @notice  Returns the next consecutive distribution Id number to be assigned
     * @return  uint256  Next distribution Id
     */
    function getNextDistributionId() external view returns (uint256) {
        return s_nextDistributionId;
    }

    /**
     * @notice  Returns all shares to be accumulated each month
     * @return  uint256[]  Array of all shares appending each month
     */
    function getSharesInMonth() external view returns (uint48[] memory) {
        return sharesInMonth;
    }

    /**
     * @notice  Returns pool data such as distribution percentage and token amounts
     * @param   poolId  Pool Id
     * @return  distributionPercentage  Percentage in 10**6 precision
     * @return  usdtTokenAmount  Total USDT tokens in pool
     * @return  usdcTokenAmount  Total USDC tokens in pool
     */
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

    /**
     * @notice  Returns band data such as band price, accessible pools and timespan
     * @param   bandLevel  Band level
     * @return  price  Band price in WOW tokens
     * @return  accessiblePools  List of accessible pools after purchase
     */
    function getBand(
        uint16 bandLevel
    ) external view returns (uint256 price, uint16[] memory accessiblePools) {
        Band memory band = s_bandLevelData[bandLevel];
        price = band.price;
        accessiblePools = band.accessiblePools;
    }

    function getSharesInMonth(
        uint256 index
    ) external view returns (uint48 shares) {
        shares = sharesInMonth[index];
    }

    /**
     * @notice  Returns staker data on each band they purchased
     * @param   bandId  Band Id
     * @return  stakingType  FIx/FLEXI staking type
     * @return  startingSharesAmount  Starting assigned share amount
     * @return  owner  Staker address
     * @return  bandLevel  Band level
     * @return  stakingStartTimestamp  Timestamp of staking start
     * @return  usdtRewardsClaimed  Amount of USDT tokens claimed
     * @return  usdcRewardsClaimed  Amount of USDC tokens claimed
     */
    function getStakerBandData(
        uint256 bandId
    )
        external
        view
        returns (
            StakingTypes stakingType,
            uint256 startingSharesAmount,
            address owner,
            uint16 bandLevel,
            uint256 stakingStartTimestamp,
            uint256 usdtRewardsClaimed,
            uint256 usdcRewardsClaimed
        )
    {
        StakerBandData memory stakerBandData = s_bands[bandId];
        stakingType = stakerBandData.stakingType;
        startingSharesAmount = stakerBandData.startingSharesAmount;
        owner = stakerBandData.owner;
        bandLevel = stakerBandData.bandLevel;
        stakingStartTimestamp = stakerBandData.stakingStartTimestamp;
        usdtRewardsClaimed = stakerBandData.usdtRewardsClaimed;
        usdcRewardsClaimed = stakerBandData.usdcRewardsClaimed;
    }

    /**
     * @notice  Returns all band Ids the staker bought
     * @param   staker  Staker address
     * @return  bandIds  Array of all staker owned bands
     */
    function getStakerBandIds(
        address staker
    ) external view returns (uint256[] memory bandIds) {
        bandIds = s_stakerBands[staker];
    }

    /**
     * @notice  Returns all fund distributions by specified token
     * @param   token  IERC20 USDT/USDC token
     * @return  fundDistributionData  Array of funDistribution data
     */
    function getFundDistribution(
        IERC20 token
    ) external view returns (FundDistribution[] memory fundDistributionData) {
        fundDistributionData = s_fundDistributions[token];
    }

    /**
     * @notice  Returns pool distribution information:
     *          token, token amount and share amount
     * @param   distributionIdAndPoolId  Hashed distribution and pool Id
     * @return  token  ERC20 USDT/USDC
     * @return  tokensAmount  Amount of tokens distributed to pool
     * @return  sharesAmount  Amount of shares present in pool
     */
    function getPoolDistribution(
        bytes32 distributionIdAndPoolId
    )
        external
        view
        returns (IERC20 token, uint256 tokensAmount, uint256 sharesAmount)
    {
        PoolDistribution memory poolDistributionData = s_poolsDistribution[
            distributionIdAndPoolId
        ];
        token = poolDistributionData.token;
        tokensAmount = poolDistributionData.tokensAmount;
        sharesAmount = poolDistributionData.sharesAmount;
    }

    /**
     * @notice  Returns data on staker shares and claimed status
     * @param   distributionIdWithPoolIdAndStaker  Hashed distribution, pool Id and staker
     * @return  shares  Total claimable shares
     * @return  claimed  Claimed share status
     */
    function getStakerShares(
        bytes32 distributionIdWithPoolIdAndStaker
    ) external view returns (uint256 shares, bool claimed) {
        StakerShares memory stakerSharesData = s_stakerShares[
            distributionIdWithPoolIdAndStaker
        ];
        shares = stakerSharesData.shares;
        claimed = stakerSharesData.claimed;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice  Claim rewards for all bands
     * @param   token  USDT/USDC token
     * @param   poolId  Id of the pool (1-9)
     */
    function claimPoolRewards(IERC20 token, uint16 poolId) public {
        uint256 distributionsAmount = s_fundDistributions[token].length;
        uint256 totalRewards;

        // Loop through all fund distributions for a single pool
        // Iterate from the last distribution to the first one
        // We know that only distributions with unclaimed rewards are at the end
        for (uint256 index = distributionsAmount - 1; index >= 0; index--) {
            uint256 distributionId = s_fundDistributions[token][index].id;
            bytes32 stakerConfigHash = _getStakerHash(
                distributionId,
                poolId,
                msg.sender
            );
            StakerShares memory stakerShares = s_stakerShares[stakerConfigHash];

            // Break the loop if the user has already claimed the rewards
            if (stakerShares.claimed) {
                break;
            }

            bytes32 poolConfigHash = _getPoolHash(distributionId, poolId);
            PoolDistribution memory distribution = s_poolsDistribution[
                poolConfigHash
            ];

            // Calculate rewards for the user and add them to the total
            totalRewards += _calculateRewards(
                distribution.tokensAmount,
                distribution.sharesAmount,
                stakerShares.shares
            );

            // Effects: set the user shares to claimed
            s_stakerShares[stakerConfigHash].claimed = true;
        }

        // Interaction: transfer the tokens to the sender
        token.safeTransfer(msg.sender, totalRewards);

        // Effects: emit event
        emit RewardsClaimed(msg.sender, token, totalRewards);
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

    /**
     * @notice  Claim rewards for specified band
     * @dev  This function can be called by anyone
     * @param   bandId  Band Id
     */
    function _claimRewardsFromPools(uint256 bandId) internal {
        uint16 bandLevel = s_bands[bandId].bandLevel;
        uint256 maxPoolId = s_bandLevelData[bandLevel].accessiblePools.length;
        // Loop through all pools and claim rewards for USDT and USDC
        for (uint16 poolId = 1; poolId <= maxPoolId; poolId++) {
            claimPoolRewards(s_usdtToken, poolId);
        }
    }

    function _createFundDistribution(
        IERC20 token,
        uint256 amount
    ) internal returns (uint256 distributionId) {
        // Effects: increment distributionId
        distributionId = s_nextDistributionId++;

        // Create fund distribution data
        FundDistribution memory fundDistribution = FundDistribution({
            id: distributionId,
            token: token,
            amount: amount,
            timestamp: block.timestamp
        });

        // Effects: set fund distribution data
        s_fundDistributions[token].push(fundDistribution);
    }

    function _createAllPoolDistributions(
        IERC20 token,
        uint256 amount,
        uint256 distributionId,
        uint16 totalPools
    ) internal {
        // Loop through all pools and set the amount of tokens
        for (uint16 poolId = 1; poolId <= totalPools; poolId++) {
            bytes32 configHash = _getPoolHash(distributionId, poolId);
            uint256 poolTokens = _calculatePoolAllocation(amount, poolId);

            // Effects: set pool distribution data
            PoolDistribution storage poolDistribution = s_poolsDistribution[
                configHash
            ];
            poolDistribution.token = token;
            poolDistribution.tokensAmount = poolTokens;
        }
    }

    function _addSharesToAccessiblePools(
        uint256 bandShares,
        uint256 distributionId,
        uint16 bandLevel,
        uint256[] memory userSharesPerPool
    ) internal returns (uint256[] memory) {
        uint16[] memory pools = s_bandLevelData[bandLevel].accessiblePools;
        uint256 poolsAmount = pools.length;

        // No need to add shares if there is nothing to add
        if (bandShares == 0) {
            return userSharesPerPool;
        }

        // Loop through all pools and set the amount of shares
        for (uint16 poolIndex; poolIndex < poolsAmount; poolIndex++) {
            uint16 poolId = pools[poolIndex];
            bytes32 poolConfigHash = _getPoolHash(distributionId, poolId);

            // Add shares to the user in the pool
            userSharesPerPool[poolId - 1] = bandShares;

            // Effects: increase pool shares
            s_poolsDistribution[poolConfigHash].sharesAmount += bandShares;
        }

        return userSharesPerPool;
    }

    function _addSharesToUser(
        address user,
        uint256 distributionId,
        uint16 totalPools,
        uint256[] memory userSharesPerPool
    ) internal {
        // Loop through all pools and set the amount of shares
        for (uint16 poolId = 1; poolId <= totalPools; poolId++) {
            bytes32 stakerConfigHash = _getStakerHash(
                distributionId,
                poolId,
                user
            );

            // Effects: increase user shares
            s_stakerShares[stakerConfigHash].shares += userSharesPerPool[
                poolId - 1
            ];
        }
    }

    function _addAllBandSharesToPools(
        address user,
        uint256 distributionId,
        uint16 totalPools
    ) internal returns (uint256[] memory userSharesPerPool) {
        uint256[] memory bandIds = s_stakerBands[user];
        uint256 bandsAmount = bandIds.length;
        userSharesPerPool = new uint256[](totalPools);

        // Loop through all bands that user owns and set the amount of shares
        for (uint256 bandIndex; bandIndex < bandsAmount; bandIndex++) {
            uint256 bandId = bandIds[bandIndex];
            StakerBandData memory band = s_bands[bandId];
            uint256 bandShares = _calculateBandShares(band, block.timestamp);

            userSharesPerPool = _addSharesToAccessiblePools(
                bandShares,
                distributionId,
                band.bandLevel,
                userSharesPerPool
            );
        }
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

    function _calculateCompletedMonths(
        uint256 startDate,
        uint256 endDate
    ) internal pure returns (uint256 perionInMonths) {
        perionInMonths = (endDate - startDate) / MONTH;
    }

    function _calculatePoolAllocation(
        uint256 amount,
        uint16 poolId
    ) internal view returns (uint256 poolTokens) {
        // amount * (distribution % * 10**6) / (100% * 10**6)
        poolTokens = ((amount * s_poolData[poolId].distributionPercentage) /
            PERCENTAGE_PRECISION);
    }

    function _calculateBandShares(
        StakerBandData memory band,
        uint256 endDate
    ) internal view returns (uint256 bandShares) {
        // If staking type is FLEXI calculate shares based months passed
        if (band.stakingType == StakingTypes.FLEXI) {
            // Calculate months that passed since staking start
            uint256 monthsPassed = _calculateCompletedMonths(
                band.stakingStartTimestamp,
                endDate
            );

            // If at least 1 month passed, calculate shares based on months
            if (monthsPassed > 0) {
                bandShares = sharesInMonth[monthsPassed - 1];
            }
        }
        // Else type is FIX
        else {
            // For FIX type, shares are set at the start and do not change over time
            bandShares = band.startingSharesAmount;
        }
    }

    function _calculateRewards(
        uint256 poolTokens,
        uint256 poolShares,
        uint256 userShares
    ) internal pure returns (uint256 rewards) {
        if (poolShares == 0) {
            revert Errors.Staking__ZeroPoolShares();
        }

        rewards = (poolTokens * userShares) / poolShares;
    }

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
