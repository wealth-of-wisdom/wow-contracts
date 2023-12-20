// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IVesting} from "./interfaces/IVesting.sol";
import {Errors} from "./libraries/Errors.sol";

contract WOW_Vesting is IVesting, Initializable, AccessControlUpgradeable {
    /*//////////////////////////////////////////////////////////////////////////
                                    LIBRARIES  
    //////////////////////////////////////////////////////////////////////////*/

    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant DEFAULT_STAKING_ROLE =
        keccak256("DEFAULT_STAKING_ROLE");
    uint32 public constant DAY = 1 days;
    uint32 public constant MONTH = 30 days;

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal token;
    mapping(uint16 => Pool) internal vestingPools;
    uint32 internal listingDate;
    uint16 internal poolCount;

    /*//////////////////////////////////////////////////////////////////////////
                                    MODIFIERS   
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks whether the address is not zero.
     */
    modifier mAddressNotZero(address _address) {
        if (_address == address(0)) {
            revert Errors.Vesting__ZeroAddress();
        }
        _;
    }

    /**
     * @notice Checks whether the address is beneficiary of the pool.
     */
    modifier mOnlyBeneficiary(uint16 _poolIndex) {
        if (
            vestingPools[_poolIndex]
                .beneficiaries[msg.sender]
                .totalTokenAmount == 0
        ) {
            revert Errors.Vesting__NotInBeneficiaryList();
        }
        _;
    }

    /**
     * @notice Checks whether the editable vesting pool exists.
     */
    modifier mPoolExists(uint16 _poolIndex) {
        if (vestingPools[_poolIndex].cliffPercentageDivisor == 0) {
            revert Errors.Vesting__PoolDoesNotExist();
        }
        _;
    }
    /**
     * @notice Checks whether token amount > 0.
     */
    modifier mTokenNotZero(uint256 _tokenAmount) {
        if (_tokenAmount == 0) {
            revert Errors.Vesting__TokenAmonutZero();
        }
        _;
    }

    /**
     * @notice Checks whether the listing date is not in the past.
     */
    modifier mValidListingDate(uint32 _listingDate) {
        if (_listingDate < block.timestamp) {
            revert Errors.Vesting__ListingDateCanOnlyBeSetInFuture();
        }
        _;
    }

    function initialize(
        IERC20 _token,
        uint32 _listingDate
    ) public initializer mValidListingDate(_listingDate) {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);

        token = _token;
        poolCount = 0;
        listingDate = _listingDate;
    }

    /**
     * @notice Adds new vesting pool and pushes new id to ID array.
     * @param _name Vesting pool name.
     * @param _listingPercentageDividend Percentage fractional form dividend part.
     * @param _listingPercentageDivisor Percentage fractional form divisor part.
     * @param _cliffInDays Period of the first lock (cliff) in days.
     * @param _cliffPercentageDividend Percentage fractional form dividend part.
     * @param _cliffPercentageDivisor Percentage fractional form divisor part.
     * @param _vestingDurationInMonths Duration of the vesting period.
     */
    function addVestingPool(
        string memory _name,
        uint16 _listingPercentageDividend,
        uint16 _listingPercentageDivisor,
        uint16 _cliffInDays,
        uint16 _cliffPercentageDividend,
        uint16 _cliffPercentageDivisor,
        uint16 _vestingDurationInMonths,
        UnlockTypes _unlockType,
        uint256 _totalPoolTokenAmount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) mTokenNotZero(_totalPoolTokenAmount) {
        _validatePoolData(
            _name,
            _listingPercentageDivisor,
            _cliffPercentageDivisor,
            _listingPercentageDividend,
            _cliffPercentageDividend,
            _vestingDurationInMonths
        );

        uint16 newIndex = poolCount;
        Pool storage p = vestingPools[newIndex];

        p.name = _name;
        p.listingPercentageDividend = _listingPercentageDividend;
        p.listingPercentageDivisor = _listingPercentageDivisor;

        p.cliffInDays = _cliffInDays;
        p.cliffEndDate = listingDate + (_cliffInDays * DAY);

        p.cliffPercentageDividend = _cliffPercentageDividend;
        p.cliffPercentageDivisor = _cliffPercentageDivisor;

        p.vestingDurationInDays = _vestingDurationInMonths * 30;
        p.vestingDurationInMonths = _vestingDurationInMonths;
        p.vestingEndDate = p.cliffEndDate + (p.vestingDurationInDays * DAY);

        p.unlockType = _unlockType;
        p.totalPoolTokenAmount = _totalPoolTokenAmount;

        poolCount++;

        emit VestingPoolAdded(newIndex, _totalPoolTokenAmount);
    }

    /**
     * @notice Adds address with purchased token amount to vesting pool.
     * @param _poolIndex Index that refers to vesting pool object.
     * @param _address Address of the beneficiary wallet.
     * @param _tokenAmount Purchased token absolute amount (with included decimals).
     */
    function addToBeneficiariesList(
        uint16 _poolIndex,
        address _address,
        uint256 _tokenAmount
    )
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAddressNotZero(_address)
        mPoolExists(_poolIndex)
        mTokenNotZero(_tokenAmount)
    {
        Pool storage p = vestingPools[_poolIndex];

        if (p.totalPoolTokenAmount < (p.lockedPoolTokenAmount + _tokenAmount)) {
            revert Errors.Vesting__TokenAmountExeedsTotalPoolAmount();
        }

        p.lockedPoolTokenAmount += _tokenAmount;
        Beneficiary storage b = p.beneficiaries[_address];
        b.totalTokenAmount += _tokenAmount;
        b.listingTokenAmount = getTokensByPercentage(
            b.totalTokenAmount,
            p.listingPercentageDividend,
            p.listingPercentageDivisor
        );

        b.cliffTokenAmount = getTokensByPercentage(
            b.totalTokenAmount,
            p.cliffPercentageDividend,
            p.cliffPercentageDivisor
        );
        b.vestedTokenAmount =
            b.totalTokenAmount -
            b.listingTokenAmount -
            b.cliffTokenAmount;

        emit BeneficiaryAdded(_poolIndex, _address, _tokenAmount);
    }

    /**
     * @notice Adds addresses with purchased token amount to the beneficiary list.
     * @param _poolIndex Index that refers to vesting pool object.
     * @param _addresses List of whitelisted addresses.
     * @param _tokenAmount Purchased token absolute amount (with included decimals).
     * @dev Example of parameters: ["address1","address2"], ["address1Amount", "address2Amount"].
     */
    function addToBeneficiariesListMultiple(
        uint16 _poolIndex,
        address[] calldata _addresses,
        uint256[] calldata _tokenAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_addresses.length != _tokenAmount.length) {
            revert Errors.Vesting__ArraySizeMismatch();
        }

        for (uint16 i; i < _addresses.length; i++) {
            addToBeneficiariesList(_poolIndex, _addresses[i], _tokenAmount[i]);
        }
    }

    /**
     * @notice Sets new listing date and recalculates cliff and vesting end dates for all pools.
     * @param newListingDate new listing date.
     */
    function changeListingDate(
        uint32 newListingDate
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mValidListingDate(newListingDate) {
        uint32 oldListingDate = listingDate;
        listingDate = newListingDate;

        for (uint16 i; i < poolCount; i++) {
            Pool storage p = vestingPools[i];
            p.cliffEndDate = listingDate + (p.cliffInDays * DAY);
            p.vestingEndDate = p.cliffEndDate + (p.vestingDurationInDays * DAY);
        }
        emit ListingDateChanged(oldListingDate, newListingDate);
    }

    /**
     * @notice Function lets caller claim unlocked tokens from specified vesting pool.
     * @param _poolIndex Index that refers to vesting pool object.
     * if the vesting period has ended - beneficiary is transferred all unclaimed tokens.
     */
    function claimTokens(
        uint16 _poolIndex
    )
        external
        mPoolExists(_poolIndex)
        mAddressNotZero(msg.sender)
        mOnlyBeneficiary(_poolIndex)
    {
        uint256 unlockedTokens = getUnlockedTokenAmount(_poolIndex, msg.sender);

        if (unlockedTokens == 0) {
            revert Errors.Vesting__NoClaimableTokens();
        }

        if (unlockedTokens > token.balanceOf(address(this))) {
            revert Errors.Vesting__NotEnoughTokenBalance();
        }

        Pool storage p = vestingPools[_poolIndex];
        Beneficiary storage b = p.beneficiaries[msg.sender];
        // NOTICE:
        // additional staking logic requires check whether
        // claimable tokens are not withdrawing from staked token pool
        if (
            b.totalTokenAmount - (b.claimedTokenAmount + unlockedTokens) <
            b.stakedTokenAmount
        ) {
            revert Errors.Vesting__StakedTokensCanNotBeClaimed();
        }

        unlockedTokens = unlockedTokens - b.stakedTokenAmount;

        b.claimedTokenAmount += unlockedTokens;

        token.safeTransfer(msg.sender, unlockedTokens);

        emit Claim(_poolIndex, msg.sender, unlockedTokens);
    }

    /**
     * @notice Removes beneficiary from the structure.
     * @param _poolIndex Index that refers to vesting pool object.
     * @param _address Address of the beneficiary wallet.
     */
    function removeBeneficiary(
        uint16 _poolIndex,
        address _address
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mPoolExists(_poolIndex) {
        Pool storage p = vestingPools[_poolIndex];
        Beneficiary storage b = p.beneficiaries[_address];
        uint256 unlockedPoolAmount = b.totalTokenAmount - b.claimedTokenAmount;
        p.lockedPoolTokenAmount -= unlockedPoolAmount;
        delete p.beneficiaries[_address];
        emit BeneficiaryRemoved(_poolIndex, _address, unlockedPoolAmount);
    }

    /**
     * @notice Transfers tokens to the selected recipient.
     * @param _customToken ERC20 token address.
     * @param _address Address of the recipient.
     * @param _tokenAmount Absolute token amount (with included decimals).
     */
    function withdrawContractTokens(
        IERC20 _customToken,
        address _address,
        uint256 _tokenAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mAddressNotZero(_address) {
        if (_customToken == token) {
            revert Errors.Vesting__CanNotWithdrawVestedTokens();
        }

        _customToken.safeTransfer(_address, _tokenAmount);
    }

    /**
     * @notice Updates staked tokens via vetsing contract.
     * @param _poolIndex Index that refers to vesting pool object.
     * @param _address Address of the staker.
     * @param _tokenAmount Amount used to stake or unstake from vesting pool.
     * @param _staking Specification whether we are staking or unstaking from pool.
     */
    function updateVestedStakedTokens(
        uint16 _poolIndex,
        address _address,
        uint256 _tokenAmount,
        bool _staking
    )
        external
        onlyRole(DEFAULT_STAKING_ROLE)
        mPoolExists(_poolIndex)
        mAddressNotZero(_address)
    {
        Pool storage p = vestingPools[_poolIndex];
        Beneficiary storage b = p.beneficiaries[_address];

        if (_staking) {
            if (b.totalTokenAmount - b.stakedTokenAmount < _tokenAmount) {
                revert Errors.Vesting__NotEnoughVestedTokensForStaking();
            }

            b.stakedTokenAmount += _tokenAmount;
        } else {
            if (b.stakedTokenAmount < _tokenAmount) {
                revert Errors.Vesting__NotEnoughTokenBalance();
            }

            b.stakedTokenAmount -= _tokenAmount;
        }

        emit UpdatedStakedTokens(_poolIndex, _tokenAmount, _staking);
    }

    /**
     * @notice Calculates unlocked and unclaimed tokens based on the days passed.
     * @param _poolIndex Index that refers to vesting pool object.
     * @param _address Address of the beneficiary wallet.
     * @return total unlocked and unclaimed tokens.
     */
    function getUnlockedTokenAmount(
        uint16 _poolIndex,
        address _address
    ) public view returns (uint256) {
        Pool storage p = vestingPools[_poolIndex];
        Beneficiary storage b = p.beneficiaries[_address];

        if (block.timestamp < listingDate) {
            // Listing has not begun yet. Return 0.
            return 0;
        }

        if (block.timestamp < p.cliffEndDate) {
            // Cliff period has not ended yet. Unlocked listing tokens.
            return b.listingTokenAmount - b.claimedTokenAmount;
        }
        if (block.timestamp >= p.vestingEndDate) {
            // Vesting period has ended. Unlocked all tokens.
            return b.totalTokenAmount - b.claimedTokenAmount;
        }
        // Cliff period has ended. Calculate vested tokens.
        (uint16 duration, uint16 periodsPassed) = getVestingPeriodsPassed(
            _poolIndex
        );
        uint256 unlockedTokens = b.listingTokenAmount +
            b.cliffTokenAmount +
            ((b.vestedTokenAmount * periodsPassed) / duration);

        return unlockedTokens - b.claimedTokenAmount;
    }

    /**
     * @notice Calculates how many full days or months have passed since the cliff end.
     * @param _poolIndex Index that refers to vesting pool object.
     * @return If unlock type is daily: vesting duration in days, else: in months.
     * @return If unlock type is daily: number of days passed, else: number of months passed.
     */
    function getVestingPeriodsPassed(
        uint16 _poolIndex
    ) public view returns (uint16, uint16) {
        Pool storage p = vestingPools[_poolIndex];
        // Cliff not ended yet
        if (block.timestamp < p.cliffEndDate) {
            return (p.vestingDurationInMonths, 0);
        }

        uint16 duration = p.unlockType == UnlockTypes.DAILY
            ? p.vestingDurationInDays
            : p.vestingDurationInMonths;

        // Unlock type daily or monthly
        uint16 periodsPassed = uint16(
            (block.timestamp - p.cliffEndDate) /
                (p.unlockType == UnlockTypes.DAILY ? DAY : MONTH)
        );

        return (duration, periodsPassed);
    }

    /**
     * @notice Calculate token amount based on the provided prcentage.
     * @param totalAmount Token amount which will be used for percentage calculation.
     * @param dividend The number from which total amount will be multiplied.
     * @param divisor The number from which total amount will be divided.
     */
    function getTokensByPercentage(
        uint256 totalAmount,
        uint16 dividend,
        uint16 divisor
    ) internal pure returns (uint256) {
        return (totalAmount * dividend) / divisor;
    }

    /**
     * @notice Checks how many tokens unlocked in a pool (not allocated to any user).
     * @param _poolIndex Index that refers to vesting pool object.
     */
    function getTotalUnlockedPoolTokens(
        uint16 _poolIndex
    ) external view returns (uint256) {
        Pool storage p = vestingPools[_poolIndex];
        return p.totalPoolTokenAmount - p.lockedPoolTokenAmount;
    }

    /**
     * @notice View of the beneficiary structure.
     * @param _poolIndex Index that refers to vesting pool object.
     * @param _address Address of the beneficiary wallet.
     * @return Beneficiary structure information.
     */
    function getBeneficiaryInformation(
        uint16 _poolIndex,
        address _address
    ) external view returns (uint256, uint256, uint256, uint256, uint256) {
        Beneficiary storage b = vestingPools[_poolIndex].beneficiaries[
            _address
        ];
        return (
            b.totalTokenAmount,
            b.listingTokenAmount,
            b.cliffTokenAmount,
            b.vestedTokenAmount,
            b.claimedTokenAmount
        );
    }

    /**
     * @notice Return global listing date value (in epoch timestamp format).
     * @return listing date.
     */
    function getListingDate() external view returns (uint32) {
        return listingDate;
    }

    /**
     * @notice Return number of pools in contract.
     * @return pool count.
     */
    function getPoolCount() external view returns (uint16) {
        return poolCount;
    }

    /**
     * @notice Return claimable token address
     * @return IERC20 token.
     */
    function getToken() external view returns (IERC20) {
        return token;
    }

    /**
     * @notice View of the vesting pool structure.
     * @param _poolIndex Index that refers to vesting pool object.
     * @return Part of the vesting pool information.
     */
    function getPoolDates(
        uint16 _poolIndex
    ) external view returns (uint16, uint32, uint16, uint16, uint32) {
        Pool storage p = vestingPools[_poolIndex];
        return (
            p.cliffInDays,
            p.cliffEndDate,
            p.vestingDurationInDays,
            p.vestingDurationInMonths,
            p.vestingEndDate
        );
    }

    /**
     * @notice View of the vesting pool structure.
     * @param _poolIndex Index that refers to vesting pool object.
     * @return Part of the vesting pool information.
     */
    function getPoolData(
        uint16 _poolIndex
    )
        external
        view
        returns (
            string memory,
            uint16,
            uint16,
            uint16,
            uint16,
            UnlockTypes,
            uint256
        )
    {
        Pool storage p = vestingPools[_poolIndex];
        return (
            p.name,
            p.listingPercentageDividend,
            p.listingPercentageDivisor,
            p.cliffPercentageDividend,
            p.cliffPercentageDivisor,
            p.unlockType,
            p.totalPoolTokenAmount
        );
    }

    function _validatePoolData(
        string memory _name,
        uint16 _listingPercentageDivisor,
        uint16 _cliffPercentageDivisor,
        uint16 _listingPercentageDividend,
        uint16 _cliffPercentageDividend,
        uint16 _vestingDurationInMonths
    ) internal view {
        if (bytes(_name).length == 0) {
            revert Errors.Vesting__EmptyName();
        }

        for (uint16 i; i < poolCount; i++) {
            if (
                keccak256(abi.encodePacked(vestingPools[i].name)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                revert Errors.Vesting__PoolWithThisNameExists();
            }
        }

        if (_listingPercentageDivisor == 0 || _cliffPercentageDivisor == 0) {
            revert Errors.Vesting__PercentageDivisorZero();
        }

        if (
            (_listingPercentageDividend * _cliffPercentageDivisor) +
                (_cliffPercentageDividend * _listingPercentageDivisor) >
            (_listingPercentageDivisor * _cliffPercentageDivisor)
        ) {
            revert Errors.Vesting__ListingAndCliffPercentageOverflow();
        }

        if (_vestingDurationInMonths == 0) {
            revert Errors.Vesting__VestingDurationZero();
        }
    }
}
