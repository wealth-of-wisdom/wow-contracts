//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.20;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IStaking} from "./interfaces/IStaking.sol";
import {Errors} from "./libraries/Errors.sol";

// solhint-disable-next-line max-states-count
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

    uint32 private constant MONTH = 30 days;
    uint16 private constant SHARES_IN_MONTH_LENGTH = 24;

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant VESTING_ROLE = keccak256("VESTING_ROLE");
    bytes32 public constant GELATO_EXECUTOR_ROLE =
        keccak256("GELATO_EXECUTOR_ROLE");

    uint32 public constant PERCENTAGE_PRECISION = 1e8; // 100% = 10^8

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /* solhint-disable var-name-mixedcase */

    // Map user => bool (if user is staking)
    // 0 - false (not staking), 1 - true (is staking)
    EnumerableMap.AddressToUintMap internal s_users;

    // Map staker => all the band ids that staker owns
    mapping(address staker => uint256[] bandIds) internal s_stakerBands;

    // Map staker => token => claimed and unclaimed rewards
    mapping(bytes32 stakerAndToken => StakerReward) internal s_stakerRewards;

    // Map single band id => band data
    mapping(uint256 bandId => StakerBand) internal s_bands;

    // Map pool id (1-9) => pool distribution percentage in 10^6 integrals, for divident calculation
    mapping(uint16 poolId => uint32 distributionPercentage)
        internal s_poolDistributionPercentages;

    // Map band level (1-9) => band level price
    mapping(uint16 bandLevel => uint256 price) internal s_bandLevelPrice;

    // Array of 24 integers, each representing the amount of shares
    // User owns in the pool for each month. Used for FLEXI staking
    // 0 index represents shares after 1 month, 1 index represents shares after 2 months, etc.
    // 10**6 = 1 share
    uint48[] internal s_sharesInMonth;

    // Token to be payed as reward
    IERC20 internal s_usdtToken;

    // Token to be payed as reward
    IERC20 internal s_usdcToken;

    // Token to be staked
    IERC20 internal s_wowToken;

    // Next unique band id to be used
    uint256 internal s_nextBandId;

    // Total amount of pools used for staking (currently, 9)
    uint16 internal s_totalPools;

    // Total amount of bands used for staking (currently, 9)
    uint16 internal s_totalBandLevels;

    // Flag to know if upgrades are enabled or not
    bool internal s_bandUpgradesEnabled;

    // Flag to know if rewards distribution is in progress
    // True if distribution was created but rewards were not yet distributed
    // False if no distribution created or rewards were already distributed
    bool internal s_distributionInProgress;

    /* solhint-enable */

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

    modifier mOnlyFlexiType(uint256 bandId) {
        if (StakingTypes.FIX == s_bands[bandId].stakingType) {
            revert Errors.Staking__NotFlexiTypeBand();
        }
        _;
    }

    modifier mValidMonth(StakingTypes stakingType, uint8 month) {
        // Checks: month must be undefined (0) for flexible staking
        if (StakingTypes.FLEXI == stakingType && month != 0) {
            revert Errors.Staking__InvalidMonth(month);
        }

        // Checks: month must be defined (1-24) for fixed staking
        if (
            StakingTypes.FIX == stakingType &&
            (month == 0 || month > s_sharesInMonth.length)
        ) {
            revert Errors.Staking__InvalidMonth(month);
        }

        _;
    }

    modifier mBandFromVestedTokens(uint256 bandId, bool shouldBeVested) {
        bool areTokensVested = s_bands[bandId].areTokensVested;
        if (areTokensVested != shouldBeVested) {
            revert Errors.Staking__BandFromVestedTokens(areTokensVested);
        }
        _;
    }

    modifier mPoolExists(uint16 poolId) {
        if (poolId == 0 || poolId > s_totalPools) {
            revert Errors.Staking__InvalidPoolId(poolId);
        }
        _;
    }

    modifier mTokenExists(IERC20 token) {
        if (token != s_usdtToken && token != s_usdcToken) {
            revert Errors.Staking__NonExistantToken();
        }
        _;
    }

    modifier mUpgradesEnabled() {
        if (!s_bandUpgradesEnabled) {
            revert Errors.Staking__UpgradesDisabled();
        }
        _;
    }

    modifier mDistributionNotInProgress() {
        if (s_distributionInProgress) {
            revert Errors.Staking__DistributionInProgress();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice  Initializes the contract with the required data
     * @param   usdtToken  USDT token
     * @param   usdcToken  USDC token
     * @param   wowToken  WOW token
     * @param   vesting  address of the vesting contract (not contract as we don't call any functions from it)
     * @param   gelato  address of the gelato executor which will call the distributeRewards and triggerSharesSync
     * @param   totalPools  total amount of pools used for staking
     * @param   totalBandLevels  total amount of bands levels used for staking
     */
    function initialize(
        IERC20 usdtToken,
        IERC20 usdcToken,
        IERC20 wowToken,
        address vesting,
        address gelato,
        uint16 totalPools,
        uint16 totalBandLevels
    )
        external
        initializer
        mAmountNotZero(totalPools)
        mAmountNotZero(totalBandLevels)
    {
        /// @dev no validation for vesting and gelato is needed,
        /// @dev because if it is zero, the contract will limit some functionality

        // Checks: Address cannot be zero (not using modifers to avoid stack too deep error)
        if (
            address(usdtToken) == address(0) ||
            address(usdcToken) == address(0) ||
            address(wowToken) == address(0)
        ) {
            revert Errors.Staking__ZeroAddress();
        }

        __AccessControl_init();
        __UUPSUpgradeable_init();

        // Effects: set the roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GELATO_EXECUTOR_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(VESTING_ROLE, vesting);
        _grantRole(GELATO_EXECUTOR_ROLE, gelato);

        // Effects: set the storage
        s_usdtToken = usdtToken;
        s_usdcToken = usdcToken;
        s_wowToken = wowToken;
        s_totalPools = totalPools;
        s_totalBandLevels = totalBandLevels;

        emit InitializedContractData(
            s_usdtToken,
            s_usdcToken,
            s_wowToken,
            s_totalPools,
            s_totalBandLevels
        );
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
    function setPoolDistributionPercentage(
        uint16 poolId,
        uint32 distributionPercentage
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mPoolExists(poolId) {
        // Checks: distribution percentage should not exceed 100%
        if (distributionPercentage > PERCENTAGE_PRECISION) {
            revert Errors.Staking__InvalidDistributionPercentage(
                distributionPercentage
            );
        }

        // Effects: set the storage
        s_poolDistributionPercentages[poolId] = distributionPercentage;

        // Effects: emit event
        emit PoolSet(poolId, distributionPercentage);
    }

    /**
     * @notice  Sets data of the selected band.
     *          This is used to set the price and accessible pools for the first time.
     *          Function can be used to update the price,
     *          but accessible pools cannot be updated.
     * @param   bandLevel  band level number
     * @param   price  band purchase price
     *          accessible after band purchase
     * @param   accessiblePools  list of pools that become
     *          accessible after band purchase
     *          This array is only used in subgraph, so it
     *          is not stored on chain
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
        // Checks: if price is set, accessible pools must be empty array
        if (s_bandLevelPrice[bandLevel] > 0 && accessiblePools.length > 0) {
            revert Errors.Staking__BandLevelAlreadySet(bandLevel);
        }

        // Checks: pools array must not exceed the total amount of pools
        if (accessiblePools.length > s_totalPools) {
            revert Errors.Staking__MaximumLevelExceeded();
        }

        // Effects: set band storage
        s_bandLevelPrice[bandLevel] = price;

        // Effects: emit event
        emit BandLevelSet(bandLevel, price, accessiblePools);
    }

    /**
     * @notice  Sets the total amount of shares that user is going to have
     *          at the end of each month of staking. Shares in month
     *          will be used for FIX and FLEXI types. All calculations will be
     *          conducted on the subgraph for FIX and FLEXI types
     * @param   totalSharesInMonth  array of shares for each month
     */
    function setSharesInMonth(
        uint48[] calldata totalSharesInMonth
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (totalSharesInMonth.length != SHARES_IN_MONTH_LENGTH) {
            revert Errors.Staking__ShareLengthMismatch();
        }
        // Effects: set the shares array
        s_sharesInMonth = totalSharesInMonth;

        // Effects: emit event
        emit SharesInMonthSet(totalSharesInMonth);
    }

    /**
     * @notice  Sets the USDC token which is used for rewards distribution
     * @param   token  USDC token
     */
    function setUsdtToken(
        IERC20 token
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAddressNotZero(address(token)) {
        // Effects: set the token
        s_usdtToken = token;

        // Effects: emit event
        emit UsdtTokenSet(token);
    }

    /**
     * @notice  Sets the USDC token which is used for rewards distribution
     * @param   token  USDC token
     */
    function setUsdcToken(
        IERC20 token
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAddressNotZero(address(token)) {
        // Effects: set the token
        s_usdcToken = token;

        // Effects: emit event
        emit UsdcTokenSet(token);
    }

    /**
     * @notice  Sets the WOW token which is used for staking by users
     * @param   token  WOW token
     */
    function setWowToken(
        IERC20 token
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAddressNotZero(address(token)) {
        // Effects: set the token
        s_wowToken = token;

        // Effects: emit event
        emit WowTokenSet(token);
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
     * @notice  Sets new trigger status for upgrades/downgrades
     * @param   enabled  true or false value for upgrades enabling
     */
    function setBandUpgradesEnabled(
        bool enabled
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Effects: set upgrades trigger
        s_bandUpgradesEnabled = enabled;

        // Effects: emit event
        emit BandUpgradeStatusSet(enabled);
    }

    /**
     * @notice  Sets the status of the rewards distribution
     * @param   inProgress  true if distribution is in progress
     *                      false if distribution not started or completed
     */
    function setDistributionInProgress(
        bool inProgress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Effects: set distribution in progress
        s_distributionInProgress = inProgress;

        // Effects: emit event
        emit DistributionStatusSet(inProgress);
    }

    /**
     * @notice  Withdraw the given amount of tokens from the contract
     * @notice  We trust the admin to withdraw the correct amount of tokens
     * @notice  Admin should be careful when calling this function not to
     * @notice  withdraw tokens that are still in use by the contract
     * @param   token Token to withdraw
     * @param   amount Amount to withdraw
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

    /**
     * @notice  Creates a new distribution of the given amount of tokens
     * @notice  Gelato backend will will monitor this function and call web3 function
     * @notice  to calculate the amount of rewards for each staker and distribute them
     * @notice  by calling distributeRewards function at the end
     * @notice  It might look like this function is missing the actual distribution logic
     * @notice  but this function is only indication for Gelato backend to calculate the rewards
     * @notice  All logic is done on the server side
     * @param   token  USDT/USDC token
     * @param   amount  amount of tokens to distribute
     */
    function createDistribution(
        IERC20 token,
        uint256 amount
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mTokenExists(token)
        mAmountNotZero(amount)
        mDistributionNotInProgress
    {
        // Only indication for Gelato backend to calculate the rewards
        // We only need to transfer funds and emit an event here

        // Effects: set distribution in progress
        s_distributionInProgress = true;

        // Interaction: transfer the tokens to the sender
        token.safeTransferFrom(msg.sender, address(this), amount);

        // Effects: emit event
        emit DistributionCreated(
            token,
            amount,
            s_totalPools,
            s_totalBandLevels,
            s_users.length(),
            block.timestamp
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS FOR GELATO EXECUTOR
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice  Distribute rewards to all stakers
     * @notice  This function is called by the Gelato backend
     * @notice  after the rewards are calculated from the server side
     * @notice  We trust the server side to calculate the rewards correctly
     * @param   token  USDT/USDC token
     * @param   stakers  array of stakers
     * @param   rewards  array of rewards for each staker in the same order
     */
    function distributeRewards(
        IERC20 token,
        address[] memory stakers,
        uint256[] memory rewards
    ) external onlyRole(GELATO_EXECUTOR_ROLE) mTokenExists(token) {
        uint256 stakersLength = stakers.length;
        uint256 rewardsLength = rewards.length;

        // Checks: stakers and rewards arrays must be the same length
        if (stakersLength != rewardsLength) {
            revert Errors.Staking__MismatchedArrayLengths(
                stakersLength,
                rewardsLength
            );
        }

        // Checks: distribution must be in progress
        if (!s_distributionInProgress) {
            revert Errors.Staking__DistributionNotInProgress();
        }

        // Effects: set distribution not in progress
        s_distributionInProgress = false;

        // Loop through all stakers and distribute rewards
        for (uint256 i; i < stakersLength; i++) {
            // Effects: add rewards to the user
            s_stakerRewards[_getStakerAndTokenHash(stakers[i], token)]
                .unclaimedAmount += rewards[i];
        }

        // Effects: emit event
        emit RewardsDistributed(token);
    }

    /**
     * @notice  Trigger the shares sync event
     * @notice  This function is called by the Gelato backend
     * @notice  to trigger the shares sync event in subgraph
     * @notice  We trust the server side to call this function at the right time
     */
    function triggerSharesSync() external onlyRole(GELATO_EXECUTOR_ROLE) {
        // Effects: emit event
        emit SharesSyncTriggered();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS FOR USERS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice  Stake and lock tokens to earn rewards
     * @param   stakingType  enumerable type for flexi or fixed staking
     * @param   bandLevel  band level number
     * @param   month  fixed staking period in months (if not fixed, set to 0)
     */
    function stake(
        StakingTypes stakingType,
        uint16 bandLevel,
        uint8 month
    )
        external
        mBandLevelExists(bandLevel)
        mValidMonth(stakingType, month)
        mDistributionNotInProgress
    {
        uint256 price = s_bandLevelPrice[bandLevel];

        // Effects: Create a new band and add it to the user
        uint256 bandId = _stakeBand(
            price,
            msg.sender,
            stakingType,
            bandLevel,
            month,
            false
        );

        // Interaction: transfer transaction funds to contract
        s_wowToken.safeTransferFrom(msg.sender, address(this), price);

        // Effects: emit event
        emit Staked(msg.sender, bandLevel, bandId, month, stakingType, false);
    }

    /**
     * @notice  Unstake tokens at any time and claim earned rewards
     * @param   bandId  Id of the band (0-max uint)
     */
    function unstake(
        uint256 bandId
    )
        external
        mBandOwner(msg.sender, bandId)
        mBandFromVestedTokens(bandId, false)
        mDistributionNotInProgress
    {
        StakerBand storage band = s_bands[bandId];

        // Checks: if band is FIX, the fixed months period should be passed
        _validateFixedPeriodPassed(band);

        // Get purchase price before deleting band data
        uint256 purchasePrice = band.purchasePrice;

        // Effects: delete band data
        _unstakeBand(msg.sender, bandId);

        // Interaction: transfer earned rewards to staker for both tokens
        _claimAllRewards(msg.sender);

        // Interraction: transfer staked tokens
        s_wowToken.safeTransfer(msg.sender, purchasePrice);

        // Effects: emit event
        emit Unstaked(msg.sender, bandId, false);
    }

    /**
     * @notice  Stakes vesting contract tokens to ear rewards
     * @param   user  address of user staking vested tokens
     * @param   stakingType  enumerable type for flexi or fixed staking
     * @param   bandLevel  band level number
     * @param   month  fixed staking period in months (if not fixed, set to 0)
     */
    function stakeVested(
        address user,
        StakingTypes stakingType,
        uint16 bandLevel,
        uint8 month
    )
        external
        onlyRole(VESTING_ROLE)
        mAddressNotZero(user)
        mBandLevelExists(bandLevel)
        mValidMonth(stakingType, month)
        mDistributionNotInProgress
        returns (uint256 bandId)
    {
        // Checks: only flexi type is allowed for vesting
        if (StakingTypes.FIX != stakingType) {
            revert Errors.Staking__OnlyFixTypeAllowed();
        }

        uint256 price = s_bandLevelPrice[bandLevel];

        // Effects: Create a new band and add it to the user
        bandId = _stakeBand(price, user, stakingType, bandLevel, month, true);

        // Effects: emit event
        emit Staked(user, bandLevel, bandId, month, stakingType, true);
    }

    /**
     * @notice  Unstake tokens at any time and claim earned rewards
     * @notice  This function can only be called by the vesting contract
     * @param   user  address of user staking vested tokens
     * @param   bandId  Id of the band (0-max uint)
     */
    function unstakeVested(
        address user,
        uint256 bandId
    )
        external
        onlyRole(VESTING_ROLE)
        mBandOwner(user, bandId)
        mBandFromVestedTokens(bandId, true)
        mDistributionNotInProgress
    {
        StakerBand storage band = s_bands[bandId];

        // Checks: if band is FIX, the fixed months period should be passed
        _validateFixedPeriodPassed(band);

        // Effects: delete band data
        _unstakeBand(user, bandId);

        // Interaction: transfer earned rewards to staker for both tokens
        _claimAllRewards(user);

        // Effects: emit event
        emit Unstaked(user, bandId, true);
    }

    /**
     * @notice  Delete all user band data if beneficiary removed from vesting
     * @notice  All unlclaimed USDT/USDC rewards will be transferred to the rewards collector
     * @param   user  staker address
     */
    function deleteVestingUser(
        address user
    ) external onlyRole(VESTING_ROLE) mAddressNotZero(user) {
        uint256[] memory bandIds = s_stakerBands[user];
        uint256 bandsAmount = bandIds.length;

        if (bandIds.length != 0) {
            // Loop through all bands that user owns and delete data
            for (uint256 bandIndex = 0; bandIndex < bandsAmount; bandIndex++) {
                // Effects: delete all band data
                delete s_bands[bandIds[bandIndex]];
            }

            // Effects: delete user from the staker bands map
            delete s_stakerBands[user];

            // Effects: delete users all claimed and unclaimed rewards for USDT
            delete s_stakerRewards[_getStakerAndTokenHash(user, s_usdtToken)];

            // Effects: delete users all claimed and unclaimed rewards for USDC
            delete s_stakerRewards[_getStakerAndTokenHash(user, s_usdcToken)];

            // Effects: delete user from the map
            s_users.remove(user);

            // Effects: emit event
            emit VestingUserDeleted(user);
        }
    }

    /**
     * @notice  Upgradea any owned band to a new level
     * @param   bandId  BandLevel Id being upgraded
     * @param   newBandLevel  New band level being upgraded to
     */
    function upgradeBand(
        uint256 bandId,
        uint16 newBandLevel
    )
        external
        mUpgradesEnabled
        mBandOwner(msg.sender, bandId)
        mBandLevelExists(newBandLevel)
        mOnlyFlexiType(bandId)
        mBandFromVestedTokens(bandId, false)
        mDistributionNotInProgress
    {
        StakerBand storage band = s_bands[bandId];
        uint16 oldBandLevel = band.bandLevel;

        // Checks: new band level must be higher than the old one
        if (newBandLevel <= oldBandLevel) {
            revert Errors.Staking__InvalidBandLevel(newBandLevel);
        }

        uint256 newPurchasePrice = _updateBandAndTransferTokens(
            band,
            msg.sender,
            newBandLevel
        );

        // Effects: emit event
        emit BandUpgraded(
            msg.sender,
            bandId,
            oldBandLevel,
            newBandLevel,
            newPurchasePrice
        );
    }

    /**
     * @notice  Downgrade any owned band to a new level
     * @param   bandId  BandLevel Id being downgraded
     * @param   newBandLevel  New band level being downgraded to
     */
    function downgradeBand(
        uint256 bandId,
        uint16 newBandLevel
    )
        external
        mUpgradesEnabled
        mBandOwner(msg.sender, bandId)
        mBandLevelExists(newBandLevel)
        mOnlyFlexiType(bandId)
        mBandFromVestedTokens(bandId, false)
        mDistributionNotInProgress
    {
        StakerBand storage band = s_bands[bandId];
        uint16 oldBandLevel = band.bandLevel;

        // Checks: new band level must be higher than the old one
        if (newBandLevel >= oldBandLevel) {
            revert Errors.Staking__InvalidBandLevel(newBandLevel);
        }

        uint256 newPurchasePrice = _updateBandAndTransferTokens(
            band,
            msg.sender,
            newBandLevel
        );

        // Effects: emit event
        emit BandDowngraded(
            msg.sender,
            bandId,
            oldBandLevel,
            newBandLevel,
            newPurchasePrice
        );
    }

    /**
     * @notice  Claim rewards for all pools and tokens
     * @notice  This function can be called by anyone
     * @param   token  USDT/USDC token
     */
    function claimRewards(
        IERC20 token
    ) external mTokenExists(token) mDistributionNotInProgress {
        _claimRewards(msg.sender, token, true);
    }

    function claimAllRewards() external mDistributionNotInProgress {
        _claimAllRewards(msg.sender);
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
    function getTotalBandLevels() external view returns (uint16) {
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
     * @notice  Returns all shares to be accumulated each month
     * @return  uint256[]  Array of all shares appending each month
     */
    function getSharesInMonthArray() external view returns (uint48[] memory) {
        return s_sharesInMonth;
    }

    /**
     * @notice  Returns the amount of shares to be accumulated in the specified month
     * @param   index  Index of the month (months start from 0)
     * @return  shares  Amount of shares to be accumulated in total
     */
    function getSharesInMonth(
        uint256 index
    ) external view returns (uint48 shares) {
        shares = s_sharesInMonth[index];
    }

    /**
     * @notice  Returns pool data such as distribution percentage and token amounts
     * @param   poolId  Pool Id
     * @return  distributionPercentage  Percentage in 10**6 precision
     */
    function getPoolDistributionPercentage(
        uint16 poolId
    ) external view returns (uint32 distributionPercentage) {
        distributionPercentage = s_poolDistributionPercentages[poolId];
    }

    /**
     * @notice  Returns band data such as band price, accessible pools and timespan
     * @param   bandLevel  BandLevel level
     * @return  price  BandLevel price in WOW tokens
     */
    function getBandLevel(
        uint16 bandLevel
    ) external view returns (uint256 price) {
        price = s_bandLevelPrice[bandLevel];
    }

    /**
     * @notice  Returns staker data on each band they purchased
     * @param   bandId  BandLevel Id
     * @return  purchasePrice  Band purchase price (changes only when upgrading/downgrading)
     * @return  owner  Staker address
     * @return  stakingStartDate  Timestamp of staking start
     * @return  bandLevel  BandLevel level
     * @return  fixedMonths  Fixed staking period in months (if not fixed, set to 0)
     * @return  stakingType  FIx/FLEXI staking type
     * @return  areTokensVested  If band was bought from vested tokens
     */
    function getStakerBand(
        uint256 bandId
    )
        external
        view
        returns (
            uint256 purchasePrice,
            address owner,
            uint32 stakingStartDate,
            uint16 bandLevel,
            uint8 fixedMonths,
            StakingTypes stakingType,
            bool areTokensVested
        )
    {
        StakerBand memory band = s_bands[bandId];
        purchasePrice = band.purchasePrice;
        owner = band.owner;
        stakingStartDate = band.stakingStartDate;
        bandLevel = band.bandLevel;
        fixedMonths = band.fixedMonths;
        stakingType = band.stakingType;
        areTokensVested = band.areTokensVested;
    }

    /**
     * @notice  Returns staker reward data for the specified token
     * @param   staker  Staker address
     * @param   token  USDT/USDC token
     * @return  unclaimedAmount  Amount of unclaimed rewards
     * @return  claimedAmount  Amount of claimed rewards
     */
    function getStakerReward(
        address staker,
        IERC20 token
    ) external view returns (uint256 unclaimedAmount, uint256 claimedAmount) {
        StakerReward memory reward = s_stakerRewards[
            _getStakerAndTokenHash(staker, token)
        ];
        unclaimedAmount = reward.unclaimedAmount;
        claimedAmount = reward.claimedAmount;
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
     * @notice  Get user address in the users map from index in array
     * @param   index  Index in the users array
     * @return  user  User address
     */
    function getUser(uint256 index) external view returns (address user) {
        (user, ) = s_users.at(index);
    }

    /**
     * @notice  Returns the amount of users in the staking contract
     * @return  usersAmount  Amount of users
     */
    function getTotalUsers() external view returns (uint256 usersAmount) {
        usersAmount = s_users.length();
    }

    /**
     * @notice  Returns status of the upgrades and downgrades
     * @return  enabled  True if upgrades/downgrades are enabled
     *                   False if upgrades/downgrades are disabled
     */
    function areBandUpgradesEnabled() external view returns (bool enabled) {
        return s_bandUpgradesEnabled;
    }

    /**
     * @notice  Returns the status of the rewards distribution
     * @return  inProgress  True if distribution is in progress
     *                      False if distribution not started or completed
     */
    function isDistributionInProgress()
        external
        view
        returns (bool inProgress)
    {
        inProgress = s_distributionInProgress;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getPeriodDuration() public pure virtual returns (uint32) {
        return MONTH;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _claimAllRewards(address staker) internal {
        // If claiming in unstake function, we don't want to revert if there are no rewards
        _claimRewards(staker, s_usdtToken, false);
        _claimRewards(staker, s_usdcToken, false);
    }

    function _claimRewards(
        address staker,
        IERC20 token,
        bool revertIfZeroAmount
    ) internal {
        StakerReward storage stakerRewards = s_stakerRewards[
            _getStakerAndTokenHash(staker, token)
        ];

        uint256 rewardsToClaim = stakerRewards.unclaimedAmount;

        // Checks: user must have rewards to claim
        if (rewardsToClaim == 0 && revertIfZeroAmount) {
            revert Errors.Staking__NoRewardsToClaim();
        }

        if (rewardsToClaim > 0) {
            // Effects: update rewards data
            stakerRewards.unclaimedAmount = 0;
            stakerRewards.claimedAmount += rewardsToClaim;

            // Interaction: transfer the tokens to the sender
            token.safeTransfer(staker, rewardsToClaim);

            // Effects: emit event
            emit RewardsClaimed(staker, token, rewardsToClaim);
        }
    }

    function _stakeBand(
        uint256 purchasePrice,
        address user,
        StakingTypes stakingType,
        uint16 bandLevel,
        uint8 month,
        bool areTokensVested
    ) internal returns (uint256 bandId) {
        // Effects: increment bandId (variable is set before incrementing to start from 0)
        bandId = s_nextBandId++;

        // Effects: set staker band data
        StakerBand storage band = s_bands[bandId];
        band.purchasePrice = purchasePrice;
        band.owner = user;
        band.stakingStartDate = uint32(block.timestamp);
        band.bandLevel = bandLevel;
        band.stakingType = stakingType;

        if (month > 0) {
            // Effects: set fixed months for the band
            band.fixedMonths = month;
        }

        if (areTokensVested) {
            // Effects: set that band is bought from vested tokens
            band.areTokensVested = true;
        }

        // Effects: add bandId to the user
        s_stakerBands[user].push(bandId);

        // If currently added band is the first one for the user
        if (s_stakerBands[user].length == 1) {
            // Effects: add user to the map
            s_users.set(user, 1);
        }
    }

    function _unstakeBand(address user, uint256 bandId) internal {
        // Effects: delete band data
        delete s_bands[bandId];

        // Effects: loop trough bandIds and remove required Id
        uint256[] storage bandIds = s_stakerBands[user];
        uint256 bandsIdsAmount = bandIds.length;
        for (uint256 i = 0; i < bandsIdsAmount; i++) {
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
    }

    function _updateBandAndTransferTokens(
        StakerBand storage band,
        address staker,
        uint16 newBandLevel
    ) internal returns (uint256 newPrice) {
        // Use the band purchase price and not the old band level price
        // Because band level price might change and be different from the purchase price
        uint256 oldPrice = band.purchasePrice;
        newPrice = s_bandLevelPrice[newBandLevel];

        // Effects: update band level
        band.bandLevel = newBandLevel;

        // Early exit if the price is the same
        if (oldPrice == newPrice) {
            return newPrice;
        }

        // Effects: update purchase price
        band.purchasePrice = newPrice;

        // Transfer tokens corresponding to the price difference
        if (newPrice > oldPrice) {
            uint256 priceDifference = newPrice - oldPrice;
            // Interaction: transfer transaction funds to contract
            s_wowToken.safeTransferFrom(staker, address(this), priceDifference);
        } else if (newPrice < oldPrice) {
            uint256 priceDifference = oldPrice - newPrice;
            // Interaction: transfer transaction funds from contract
            s_wowToken.safeTransfer(staker, priceDifference);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FUNCTIONS FOR UPGRADER ROLE
    //////////////////////////////////////////////////////////////////////////*/

    /* solhint-disable no-empty-blocks */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {
        /// @dev This function is empty but uses a modifier to restrict access
    }

    /* solhint-enable */

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _validateFixedPeriodPassed(
        StakerBand storage band
    ) internal view virtual {
        if (band.stakingType == StakingTypes.FIX) {
            uint32 monthsPassed = (uint32(block.timestamp) -
                band.stakingStartDate) / getPeriodDuration();

            // Checks: fixed staking can only be unstaked after the fixed period
            if (monthsPassed < band.fixedMonths) {
                revert Errors.Staking__UnlockDateNotReached();
            }
        }
    }

    function _getStakerAndTokenHash(
        address staker,
        IERC20 token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(staker, token));
    }
}
