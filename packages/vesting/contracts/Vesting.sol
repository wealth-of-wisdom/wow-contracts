// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
    uint32 public constant DAY = 1 days;
    uint32 public constant MONTH = 30 days;

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal s_token;
    address internal s_stakingContract;
    mapping(uint16 => Pool) internal s_vestingPools;
    uint32 internal s_listingDate;
    uint16 internal s_poolCount;

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
        address stakingContract,
        uint32 listingDate
    )
        external
        initializer
        mAddressNotZero(address(token))
        mValidListingDate(listingDate)
    {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(STAKING_ROLE, stakingContract);

        s_token = token;
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

        s_poolCount++;

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
    function addBeneficiary(
        uint16 pid,
        address beneficiary,
        uint256 tokenAmount
    )
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        mPoolExists(pid)
        mAddressNotZero(beneficiary)
        mAmountNotZero(tokenAmount)
    {
        Pool storage pool = s_vestingPools[pid];

        if (
            pool.totalPoolTokenAmount <
            (pool.lockedPoolTokenAmount + tokenAmount)
        ) {
            revert Errors.Vesting__TokenAmountExeedsTotalPoolAmount();
        }

        pool.lockedPoolTokenAmount += tokenAmount;

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
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (beneficiaries.length != tokenAmounts.length) {
            revert Errors.Vesting__ArraySizeMismatch();
        }

        for (uint16 i; i < beneficiaries.length; i++) {
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

        /// @question should we remove user if he has staked tokens?
        uint256 unlockedPoolAmount = user.totalTokenAmount -
            user.claimedTokenAmount;
        pool.lockedPoolTokenAmount -= unlockedPoolAmount;

        delete pool.beneficiaries[beneficiary];

        emit BeneficiaryRemoved(pid, beneficiary, unlockedPoolAmount);
    }

    /**
     * @notice Sets new listing date and recalculates cliff and vesting end dates for all pools.
     * @param newListingDate new listing date.
     */
    function changeListingDate(
        uint32 newListingDate
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mValidListingDate(newListingDate) {
        uint32 oldListingDate = s_listingDate;
        s_listingDate = newListingDate;

        for (uint16 i; i < s_poolCount; i++) {
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
        if (customToken == s_token) {
            revert Errors.Vesting__CanNotWithdrawVestedTokens();
        }

        if (tokenAmount > customToken.balanceOf(address(this))) {
            revert Errors.Vesting__InsufficientBalance();
        }

        customToken.safeTransfer(recipient, tokenAmount);

        emit ContractTokensWithdrawn(customToken, recipient, tokenAmount);
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
    )
        external
        mPoolExists(pid)
        mAddressNotZero(msg.sender)
        mOnlyBeneficiary(pid)
    {
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
            if (
                tokenAmount >
                user.totalTokenAmount -
                    user.stakedTokenAmount -
                    user.claimedTokenAmount
            ) {
                revert Errors.Vesting__NotEnoughVestedTokensForStaking();
            }

            user.stakedTokenAmount += tokenAmount;
        } else {
            if (tokenAmount > user.stakedTokenAmount) {
                revert Errors.Vesting__NotEnoughStakedTokens();
            }

            user.stakedTokenAmount -= tokenAmount;
        }

        emit StakedTokensUpdated(pid, tokenAmount, startStaking);
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

    function getGeneralPoolData(
        uint16 pid
    ) external view returns (string memory, UnlockTypes, uint256, uint256) {
        Pool storage pool = s_vestingPools[pid];
        return (
            pool.name,
            pool.unlockType,
            pool.totalPoolTokenAmount,
            pool.lockedPoolTokenAmount
        );
    }

    function getPoolListingData(
        uint16 pid
    ) external view returns (uint16, uint16) {
        Pool storage pool = s_vestingPools[pid];
        return (pool.listingPercentageDividend, pool.listingPercentageDivisor);
    }

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
     * @return total unlocked and unclaimed tokens.
     */
    function getUnlockedTokenAmount(
        uint16 pid,
        address beneficiary
    ) public view returns (uint256) {
        Pool storage pool = s_vestingPools[pid];
        Beneficiary storage user = pool.beneficiaries[beneficiary];

        if (block.timestamp < s_listingDate) {
            // Listing has not begun yet. Return 0.
            return 0;
        }

        if (block.timestamp < pool.cliffEndDate) {
            // Cliff period has not ended yet. Unlocked listing tokens.
            return user.listingTokenAmount - user.claimedTokenAmount;
        }

        if (block.timestamp >= pool.vestingEndDate) {
            // Vesting period has ended. Unlocked all tokens.
            return user.totalTokenAmount - user.claimedTokenAmount;
        }

        // Cliff period has ended. Calculate vested tokens.
        (uint16 periodsPassed, uint16 duration) = getVestingPeriodsPassed(pid);
        uint256 unlockedTokens = user.listingTokenAmount +
            user.cliffTokenAmount +
            ((user.vestedTokenAmount * periodsPassed) / duration);

        return unlockedTokens - user.claimedTokenAmount;
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

        for (uint16 i; i < s_poolCount; i++) {
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
        return (totalAmount * dividend) / divisor;
    }
}
