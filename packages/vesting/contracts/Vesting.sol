// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IStaking} from "@wealth-of-wisdom/staking/contracts/interfaces/IStaking.sol";
import {IVesting} from "./interfaces/IVesting.sol";
import {Errors} from "./libraries/Errors.sol";

contract Vesting is IVesting, Initializable, AccessControlUpgradeable {
    /*//////////////////////////////////////////////////////////////////////////
                                    LIBRARIES  
    //////////////////////////////////////////////////////////////////////////*/

    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 public constant STAKING_ROLE = keccak256("STAKING_ROLE");
    bytes32 public constant BENEFICIARIES_MANAGER_ROLE =
        keccak256("BENEFICIARIES_MANAGER_ROLE");

    uint32 public constant DAY = 1 days;
    uint32 public constant MONTH = 30 days;

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /* solhint-disable var-name-mixedcase */
    IERC20 internal s_token;
    IStaking internal s_staking;
    mapping(uint16 => Pool) internal s_vestingPools;
    uint32 internal s_listingDate;
    uint16 internal s_poolCount;
    /* solhint-enable */

    /*//////////////////////////////////////////////////////////////////////////
                                    MODIFIERS   
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks whether the address is not zero.
     */
    modifier mAddressNotZero(address addr) {
        if (addr == address(0)) {
            revert Errors.Vesting__ZeroAddress();
        }
        _;
    }

    /**
     * @notice Checks whether the address is user of the pool.
     */
    modifier mOnlyBeneficiary(uint16 pid) {
        if (!_isBeneficiaryAdded(pid, msg.sender)) {
            revert Errors.Vesting__NotBeneficiary();
        }
        _;
    }

    /**
     * @notice Checks whether the beneficiary is added to the pool.
     */
    modifier mBeneficiaryExists(uint16 pid, address beneficiary) {
        if (!_isBeneficiaryAdded(pid, beneficiary)) {
            revert Errors.Vesting__BeneficiaryDoesNotExist();
        }
        _;
    }

    /**
     * @notice Checks whether the editable vesting pool exists.
     */
    modifier mPoolExists(uint16 pid) {
        if (s_vestingPools[pid].cliffPercentageDivisor == 0) {
            revert Errors.Vesting__PoolDoesNotExist();
        }
        _;
    }

    /**
     * @notice Checks whether token amount > 0.
     */
    modifier mAmountNotZero(uint256 tokenAmount) {
        if (tokenAmount == 0) {
            revert Errors.Vesting__TokenAmountZero();
        }
        _;
    }

    /**
     * @notice Checks whether the listing date is not in the past.
     */
    modifier mValidListingDate(uint32 listingDate) {
        if (listingDate < block.timestamp) {
            revert Errors.Vesting__ListingDateNotInFuture();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract.
     * @param token ERC20 token address.
     * @param listingDate Listing date in epoch timestamp format.
     */
    function initialize(
        IERC20 token,
        IStaking stakingContract,
        uint32 listingDate
    )
        external
        initializer
        mAddressNotZero(address(token))
        mAddressNotZero(address(stakingContract))
        mValidListingDate(listingDate)
    {
        // Effects: Initialize AccessControl
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BENEFICIARIES_MANAGER_ROLE, msg.sender);
        _grantRole(STAKING_ROLE, address(stakingContract));

        // Effects: Initialize storage variables
        s_token = token;
        s_staking = stakingContract;
        s_listingDate = listingDate;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          ADMIN-FACING STATE CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Adds new vesting pool.
     * @param name Vesting pool name.
     * @param listingPercentageDividend Percentage fractional form dividend part.
     * @param listingPercentageDivisor Percentage fractional form divisor part.
     * @param cliffInDays Period of the first lock (cliff) in days.
     * @param cliffPercentageDividend Percentage fractional form dividend part.
     * @param cliffPercentageDivisor Percentage fractional form divisor part.
     * @param vestingDurationInMonths Duration of the vesting period.
     */
    function addVestingPool(
        string calldata name,
        uint16 listingPercentageDividend,
        uint16 listingPercentageDivisor,
        uint16 cliffInDays,
        uint16 cliffPercentageDividend,
        uint16 cliffPercentageDivisor,
        uint16 vestingDurationInMonths,
        UnlockTypes unlockType,
        uint256 totalPoolTokenAmount
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAmountNotZero(totalPoolTokenAmount)
    {
        // Checks: Validate pool data before adding new vesting pool
        _validatePoolData(
            name,
            listingPercentageDivisor,
            cliffPercentageDivisor,
            listingPercentageDividend,
            cliffPercentageDividend,
            vestingDurationInMonths
        );

        uint16 pid = s_poolCount;
        Pool storage pool = s_vestingPools[pid];

        // Effects: Initialize pool variables with provided data
        // We cannot use `pool = Pool(...)` because struct contains mapping
        pool.name = name;
        pool.listingPercentageDividend = listingPercentageDividend;
        pool.listingPercentageDivisor = listingPercentageDivisor;

        pool.cliffInDays = cliffInDays;
        pool.cliffEndDate = s_listingDate + (cliffInDays * DAY);
        pool.cliffPercentageDividend = cliffPercentageDividend;
        pool.cliffPercentageDivisor = cliffPercentageDivisor;

        pool.vestingDurationInDays = vestingDurationInMonths * 30;
        pool.vestingDurationInMonths = vestingDurationInMonths;
        pool.vestingEndDate =
            pool.cliffEndDate +
            (pool.vestingDurationInDays * DAY);

        pool.unlockType = unlockType;
        pool.totalPoolTokenAmount = totalPoolTokenAmount;

        // Effects: Increment pool count
        s_poolCount++;

        // Interactions: Transfer tokens to the contract
        s_token.safeTransferFrom(
            msg.sender,
            address(this),
            totalPoolTokenAmount
        );

        emit VestingPoolAdded(pid, totalPoolTokenAmount);
    }

    /**
     * @notice Adds user with token amount to vesting pool.
     * @param pid Index that refers to vesting pool object.
     * @param beneficiary Address of the user wallet.
     * @param tokenAmount Purchased token absolute amount (with included decimals).
     */
    /* solhint-disable ordering */
    function addBeneficiary(
        uint16 pid,
        address beneficiary,
        uint256 tokenAmount
    )
        public
        onlyRole(BENEFICIARIES_MANAGER_ROLE)
        mPoolExists(pid)
        mAddressNotZero(beneficiary)
        mAmountNotZero(tokenAmount)
    {
        Pool storage pool = s_vestingPools[pid];

        // Checks: User token amount should not exceed total pool amount
        if (
            pool.totalPoolTokenAmount <
            (pool.dedicatedPoolTokenAmount + tokenAmount)
        ) {
            revert Errors.Vesting__TokenAmountExeedsTotalPoolAmount();
        }

        // Effects: Increase locked pool token amount
        pool.dedicatedPoolTokenAmount += tokenAmount;

        // Effects: update user token amounts
        Beneficiary storage user = pool.beneficiaries[beneficiary];
        user.totalTokenAmount += tokenAmount;
        user.listingTokenAmount = _getTokensByPercentage(
            user.totalTokenAmount,
            pool.listingPercentageDividend,
            pool.listingPercentageDivisor
        );
        user.cliffTokenAmount = _getTokensByPercentage(
            user.totalTokenAmount,
            pool.cliffPercentageDividend,
            pool.cliffPercentageDivisor
        );
        user.vestedTokenAmount =
            user.totalTokenAmount -
            user.listingTokenAmount -
            user.cliffTokenAmount;

        emit BeneficiaryAdded(pid, beneficiary, tokenAmount);
    }

    /* solhint-enable */

    /**
     * @notice Adds addresses with purchased token amount to the user list.
     * @param pid Index that refers to vesting pool object.
     * @param beneficiaries List of whitelisted addresses.
     * @param tokenAmounts Purchased token absolute amount (with included decimals).
     * @dev Example of parameters: ["address1","address2"], ["address1Amount", "address2Amount"].
     */
    function addMultipleBeneficiaries(
        uint16 pid,
        address[] calldata beneficiaries,
        uint256[] calldata tokenAmounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mPoolExists(pid) {
        uint256 beneficiaryCount = beneficiaries.length;

        // Checks: Array lengths should be equal
        if (beneficiaryCount != tokenAmounts.length) {
            revert Errors.Vesting__ArraySizeMismatch();
        }

        // Effects: Add users to the pool
        for (uint16 i; i < beneficiaryCount; i++) {
            addBeneficiary(pid, beneficiaries[i], tokenAmounts[i]);
        }
    }

    /**
     * @notice Removes user from the pool.
     * @param pid Index that refers to vesting pool object.
     * @param beneficiary Address of the user wallet.
     */
    function removeBeneficiary(
        uint16 pid,
        address beneficiary
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mPoolExists(pid)
        mBeneficiaryExists(pid, beneficiary)
    {
        Pool storage pool = s_vestingPools[pid];
        Beneficiary storage user = pool.beneficiaries[beneficiary];

        // Get staked amount that will be unstaked from staking contract
        uint256 stakedAmount = user.stakedTokenAmount;

        // Get unlocked amount that will be transferred to the user
        // We don't need to check whether the user has staked tokens
        // because we are unstaking all staked tokens, which means it will be 0
        uint256 availableAmount = user.totalTokenAmount -
            user.claimedTokenAmount;

        if (availableAmount > 0) {
            // Effects: Update pool dedicated token amount
            pool.dedicatedPoolTokenAmount -= availableAmount;
        }

        // Effects: Delete user from the pool
        delete pool.beneficiaries[beneficiary];

        if (stakedAmount > 0) {
            // Interactions: Unstake staked tokens from staking contract
            s_staking.unstakeVestedTokens(beneficiary, stakedAmount);
        }

        emit BeneficiaryRemoved(pid, beneficiary, availableAmount);
    }

    /**
     * @notice Sets new listing date and recalculates cliff and vesting end dates for all pools.
     * @param newListingDate new listing date.
     */
    function changeListingDate(
        uint32 newListingDate
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mValidListingDate(newListingDate) {
        uint32 oldListingDate = s_listingDate;
        uint16 poolCount = s_poolCount;

        // Effects: Update listing date
        s_listingDate = newListingDate;

        // Effects: update cliff and vesting end dates for all pools
        for (uint16 i; i < poolCount; i++) {
            Pool storage pool = s_vestingPools[i];
            pool.cliffEndDate = s_listingDate + (pool.cliffInDays * DAY);
            pool.vestingEndDate =
                pool.cliffEndDate +
                (pool.vestingDurationInDays * DAY);
        }

        emit ListingDateChanged(oldListingDate, newListingDate);
    }

    /**
     * @notice Transfers tokens to the selected recipient.
     * @param customToken ERC20 token address.
     * @param recipient Address of the recipient.
     * @param tokenAmount Absolute token amount (with included decimals).
     */
    function withdrawContractTokens(
        IERC20 customToken,
        address recipient,
        uint256 tokenAmount
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAddressNotZero(address(customToken))
        mAddressNotZero(recipient)
        mAmountNotZero(tokenAmount)
    {
        // Checks: Can not withdraw vesting token
        if (customToken == s_token) {
            revert Errors.Vesting__CanNotWithdrawVestedTokens();
        }

        // Checks: Enough tokens in the contract
        if (tokenAmount > customToken.balanceOf(address(this))) {
            revert Errors.Vesting__InsufficientBalance();
        }

        // Interactions: Transfer tokens to the recipient
        customToken.safeTransfer(recipient, tokenAmount);

        emit ContractTokensWithdrawn(customToken, recipient, tokenAmount);
    }

    /**
     * @notice Allows admin to set new staking contract address.
     * @param newStaking Address of the new staking contract.
     */
    function setStakingContract(
        IStaking newStaking
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAddressNotZero(address(newStaking))
    {
        // Effects: Revoke and grant roles
        revokeRole(STAKING_ROLE, address(s_staking));
        grantRole(STAKING_ROLE, address(newStaking));

        // Effects: Set new staking contract address
        s_staking = newStaking;

        emit StakingContractSet(newStaking);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Function lets caller claim unlocked tokens from specified vesting pool.
     * @notice if the vesting period has ended - user is transferred all unclaimed tokens.
     * @param pid Index that refers to vesting pool object.
     */
    function claimTokens(
        uint16 pid
    ) external mPoolExists(pid) mOnlyBeneficiary(pid) {
        uint256 unlockedTokens = getUnlockedTokenAmount(pid, msg.sender);

        // Checks: At least some tokens are unlocked
        if (unlockedTokens == 0) {
            revert Errors.Vesting__NoTokensUnlocked();
        }

        // Checks: Enough tokens in the contract
        if (unlockedTokens > s_token.balanceOf(address(this))) {
            revert Errors.Vesting__NotEnoughTokens();
        }

        Pool storage pool = s_vestingPools[pid];
        Beneficiary storage user = pool.beneficiaries[msg.sender];

        // Available tokens are the maximum amount that user should be able claim
        // if all tokens are unlocked for the user,
        uint256 availableTokens = user.totalTokenAmount -
            user.claimedTokenAmount -
            user.stakedTokenAmount;

        // Checks: Unlocked tokens are not withdrawing from staked token pool
        if (unlockedTokens > availableTokens) {
            revert Errors.Vesting__StakedTokensCanNotBeClaimed();
        }

        // Effects
        user.claimedTokenAmount += unlockedTokens;

        // Interactions
        s_token.safeTransfer(msg.sender, unlockedTokens);

        emit TokensClaimed(pid, msg.sender, unlockedTokens);
    }

    /**
     * @notice Updates staked tokens via vesting contract.
     * @param pid Index that refers to vesting pool object.
     * @param beneficiary Address of the staker.
     * @param tokenAmount Amount used to stake or unstake from vesting pool.
     * @param startStaking Specification whether we are staking or unstaking from pool.
     */
    function updateVestedStakedTokens(
        uint16 pid,
        address beneficiary,
        uint256 tokenAmount,
        bool startStaking
    )
        external
        onlyRole(STAKING_ROLE)
        mPoolExists(pid)
        mBeneficiaryExists(pid, beneficiary)
        mAmountNotZero(tokenAmount)
    {
        Pool storage pool = s_vestingPools[pid];
        Beneficiary storage user = pool.beneficiaries[beneficiary];

        if (startStaking) {
            // Checks: Enough unstaked tokens in the contract
            if (
                tokenAmount >
                user.totalTokenAmount -
                    user.stakedTokenAmount -
                    user.claimedTokenAmount
            ) {
                revert Errors.Vesting__NotEnoughVestedTokensForStaking();
            }

            // Effects: Stake tokens
            user.stakedTokenAmount += tokenAmount;
        } else {
            // Checks: Enough staked tokens in the contract
            if (tokenAmount > user.stakedTokenAmount) {
                revert Errors.Vesting__NotEnoughStakedTokens();
            }

            // Effects: Unstake tokens
            user.stakedTokenAmount -= tokenAmount;
        }

        emit StakedTokensUpdated(pid, beneficiary, tokenAmount, startStaking);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          EXTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Get user details for pool.
     * @param pid Index that refers to vesting pool object.
     * @param user Address of the beneficiary wallet.
     * @return Beneficiary structure information.
     */
    function getBeneficiary(
        uint16 pid,
        address user
    ) external view returns (Beneficiary memory) {
        return s_vestingPools[pid].beneficiaries[user];
    }

    /**
     * @notice Return global listing date value (in epoch timestamp format).
     * @return listing date.
     */
    function getListingDate() external view returns (uint32) {
        return s_listingDate;
    }

    /**
     * @notice Return number of pools in contract.
     * @return pool count.
     */
    function getPoolCount() external view returns (uint16) {
        return s_poolCount;
    }

    /**
     * @notice Return claimable token address
     * @return IERC20 token.
     */
    function getToken() external view returns (IERC20) {
        return s_token;
    }

    /**
     * @notice Return staking contract address
     * @return staking contract address.
     */
    function getStakingContract() external view returns (IStaking) {
        return s_staking;
    }

    /**
     * @notice Return pool data.
     * @param pid Index that refers to vesting pool object.
     * @return Pool name
     * @return Unlock type
     * @return Total pool token amount
     * @return Locked pool token amount
     */
    function getGeneralPoolData(
        uint16 pid
    ) external view returns (string memory, UnlockTypes, uint256, uint256) {
        Pool storage pool = s_vestingPools[pid];
        return (
            pool.name,
            pool.unlockType,
            pool.totalPoolTokenAmount,
            pool.dedicatedPoolTokenAmount
        );
    }

    /**
     * @notice Return pool listing data.
     * @param pid Index that refers to vesting pool object.
     * @return listing percentage dividend
     * @return listing percentage divisor
     */
    function getPoolListingData(
        uint16 pid
    ) external view returns (uint16, uint16) {
        Pool storage pool = s_vestingPools[pid];
        return (pool.listingPercentageDividend, pool.listingPercentageDivisor);
    }

    /**
     * @notice Return pool cliff data.
     * @param pid Index that refers to vesting pool object.
     * @return cliff end date
     * @return cliff in days
     * @return cliff percentage dividend
     * @return cliff percentage divisor
     */
    function getPoolCliffData(
        uint16 pid
    ) external view returns (uint32, uint16, uint16, uint16) {
        Pool storage pool = s_vestingPools[pid];
        return (
            pool.cliffEndDate,
            pool.cliffInDays,
            pool.cliffPercentageDividend,
            pool.cliffPercentageDivisor
        );
    }

    /**
     * @notice Return pool vesting data.
     * @param pid Index that refers to vesting pool object.
     * @return vesting end date
     * @return vesting duration in months
     * @return vesting duration in days
     */
    function getPoolVestingData(
        uint16 pid
    ) external view returns (uint32, uint16, uint16) {
        Pool storage pool = s_vestingPools[pid];
        return (
            pool.vestingEndDate,
            pool.vestingDurationInMonths,
            pool.vestingDurationInDays
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculates unlocked and unclaimed tokens based on the days passed.
     * @param pid Index that refers to vesting pool object.
     * @param beneficiary Address of the user wallet.
     * @return unlockedAmount total unlocked and unclaimed tokens.
     */
    function getUnlockedTokenAmount(
        uint16 pid,
        address beneficiary
    ) public view returns (uint256 unlockedAmount) {
        Pool storage pool = s_vestingPools[pid];
        Beneficiary storage user = pool.beneficiaries[beneficiary];

        if (block.timestamp >= s_listingDate) {
            if (block.timestamp < pool.cliffEndDate) {
                // Cliff period has not ended yet. Unlocked listing tokens.
                unlockedAmount =
                    user.listingTokenAmount -
                    user.claimedTokenAmount;
            } else if (block.timestamp < pool.vestingEndDate) {
                // Cliff period has ended. Calculate vested tokens.
                (
                    uint16 periodsPassed,
                    uint16 duration
                ) = getVestingPeriodsPassed(pid);

                // Listing + Cliff + Vested - Claimed
                unlockedAmount =
                    user.listingTokenAmount +
                    user.cliffTokenAmount +
                    ((user.vestedTokenAmount * periodsPassed) / duration) -
                    user.claimedTokenAmount;
            } else {
                // Vesting period has ended. Unlocked all tokens.
                unlockedAmount =
                    user.totalTokenAmount -
                    user.claimedTokenAmount;
            }
        }
        // Else: Listing date has not come yet. unlockedAmount is 0 by default.
    }

    /**
     * @notice Calculates how many full days or months have passed since the cliff end.
     * @param pid Index that refers to vesting pool object.
     * @return periodsPassed If unlock type is daily: number of days passed, else: number of months passed.
     * @return duration If unlock type is daily: vesting duration in days, else: in months.
     */

    function getVestingPeriodsPassed(
        uint16 pid
    ) public view returns (uint16 periodsPassed, uint16 duration) {
        Pool storage pool = s_vestingPools[pid];

        // Default value for duration is vesting duration in months
        duration = pool.vestingDurationInMonths;

        if (block.timestamp >= pool.cliffEndDate) {
            periodsPassed = uint16(
                (block.timestamp - pool.cliffEndDate) /
                    (pool.unlockType == UnlockTypes.DAILY ? DAY : MONTH)
            );

            if (pool.unlockType == UnlockTypes.DAILY) {
                duration = pool.vestingDurationInDays;
            }
        }

        // periodsPassed by default is 0 if cliff has not ended yet
    }

    /*//////////////////////////////////////////////////////////////////////////
                        INTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Validates pool data before adding new vesting pool.
     * @param name Vesting pool name.
     * @param listingPercentageDivisor Percentage fractional form divisor part.
     * @param cliffPercentageDivisor Percentage fractional form divisor part.
     * @param listingPercentageDividend Percentage fractional form dividend part.
     * @param cliffPercentageDividend Percentage fractional form dividend part.
     */
    function _validatePoolData(
        string calldata name,
        uint16 listingPercentageDivisor,
        uint16 cliffPercentageDivisor,
        uint16 listingPercentageDividend,
        uint16 cliffPercentageDividend,
        uint16 vestingDurationInMonths
    ) internal view {
        if (bytes(name).length == 0) {
            revert Errors.Vesting__EmptyName();
        }

        uint16 poolCount = s_poolCount;
        for (uint16 i; i < poolCount; i++) {
            if (
                keccak256(abi.encodePacked(s_vestingPools[i].name)) ==
                keccak256(abi.encodePacked(name))
            ) {
                revert Errors.Vesting__PoolWithThisNameExists();
            }
        }

        if (listingPercentageDivisor == 0 || cliffPercentageDivisor == 0) {
            revert Errors.Vesting__PercentageDivisorZero();
        }

        if (
            (listingPercentageDividend * cliffPercentageDivisor) +
                (cliffPercentageDividend * listingPercentageDivisor) >
            (listingPercentageDivisor * cliffPercentageDivisor)
        ) {
            revert Errors.Vesting__ListingAndCliffPercentageOverflow();
        }

        if (vestingDurationInMonths == 0) {
            revert Errors.Vesting__VestingDurationZero();
        }
    }

    /**
     * @notice Checks whether the beneficiary exists in the pool.
     * @param pid Index that refers to vesting pool object.
     * @param beneficiary Address of the user wallet.
     * @return true if beneficiary exists in the pool, else false.
     */
    function _isBeneficiaryAdded(
        uint16 pid,
        address beneficiary
    ) internal view returns (bool) {
        return
            s_vestingPools[pid].beneficiaries[beneficiary].totalTokenAmount !=
            0;
    }

    /**
     * @notice Calculate token amount based on the provided prcentage.
     * @param totalAmount Token amount which will be used for percentage calculation.
     * @param dividend The number from which total amount will be multiplied.
     * @param divisor The number from which total amount will be divided.
     */
    function _getTokensByPercentage(
        uint256 totalAmount,
        uint16 dividend,
        uint16 divisor
    ) internal pure returns (uint256) {
        if (divisor == 0) {
            revert Errors.Vesting__PercentageDivisorZero();
        }

        return (totalAmount * dividend) / divisor;
    }
}
