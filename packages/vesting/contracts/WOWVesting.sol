// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Vesting is Initializable, AccessControlUpgradeable {
    enum UnlockTypes {
        DAILY,
        MONTHLY
    }
    struct Beneficiary {
        uint totalTokens;
        uint listingTokenAmount;
        uint cliffTokenAmount;
        uint vestedTokenAmount;
        uint claimedTotalTokenAmount;
    }
    struct Pool {
        string name;
        uint listingPercentageDividend;
        uint listingPercentageDivisor;
        uint cliffInDays;
        uint cliffEndDate;
        uint cliffPercentageDividend;
        uint cliffPercentageDivisor;
        uint vestingDurationInMonths;
        uint vestingDurationInDays;
        uint vestingEndDate;
        mapping(address => Beneficiary) beneficiaries;
        UnlockTypes unlockType;
        uint totalPoolTokenAmount;
        uint lockedPoolTokens;
    }

    using SafeERC20 for IERC20;
    IERC20 private token;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    uint public constant DAY = 1 days;
    uint public constant MONTH = 30 days;

    uint private poolCount;
    uint private listingDate;
    mapping(uint => Pool) private vestingPools;

    event Claim(address indexed from, uint indexed poolIndex, uint tokenAmount);
    event BeneficiaryAdded(
        uint indexed poolIndex,
        address indexed beneficiary,
        uint addedTokenAmount
    );
    event BeneficiaryRemoved(
        uint indexed poolIndex,
        address indexed beneficiary,
        uint unlockedPoolAmount
    );
    event ListingDateChanged(uint oldDate, uint newDate);
    event VestingPoolAdded(uint indexed poolIndex, uint totalPoolTokenAmount);

    error ArraySizeMismatch();
    error CanNotWithdrawVestedTokens();
    error ListingDateCanOnlyBeSetInFuture();
    error ListingAndCliffPercentageOverflow();
    error NotInBeneficiaryList();
    error NoClaimableTokens();
    error NotEnoughTokenBalance();
    error PercentageDivisorZero();
    error PoolDoesNotExist();
    error PoolWithThisNameExists();
    error TokenAmountExeedsTotalPoolAmount();
    error TokenAmonutZero();
    error VestingDurationZero();
    error ZeroAddress();

    /**
     * @notice Checks whether the address is not zero.
     */
    modifier mAddressNotZero(address _address) {
        if (_address == address(0)) revert ZeroAddress();
        _;
    }

    /**
     * @notice Checks whether the address is beneficiary of the pool.
     */
    modifier mOnlyBeneficiary(uint _poolIndex) {
        if (vestingPools[_poolIndex].beneficiaries[msg.sender].totalTokens == 0)
            revert NotInBeneficiaryList();
        _;
    }

    /**
     * @notice Checks whether new pool's name does not already exist.
     */
    modifier mAddPoolDataCheck(
        string memory _name,
        uint _listingPercentageDivisor,
        uint _cliffPercentageDivisor,
        uint _listingPercentageDividend,
        uint _cliffPercentageDividend,
        uint _vestingDurationInMonths
    ) {
        for (uint i = 0; i < poolCount; i++) {
            if (
                keccak256(abi.encodePacked(vestingPools[i].name)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                revert PoolWithThisNameExists();
            }
        }
        if (_listingPercentageDivisor == 0 && _cliffPercentageDivisor == 0)
            revert PercentageDivisorZero();
        if (
            (_listingPercentageDividend * _cliffPercentageDivisor) +
                (_cliffPercentageDividend * _listingPercentageDivisor) <=
            (_listingPercentageDivisor * _cliffPercentageDivisor)
        ) revert ListingAndCliffPercentageOverflow();

        if (_vestingDurationInMonths == 0) revert VestingDurationZero();
        _;
    }

    /**
     * @notice Checks whether the editable vesting pool exists.
     */
    modifier mPoolExists(uint _poolIndex) {
        if (vestingPools[_poolIndex].cliffPercentageDivisor == 0)
            revert PoolDoesNotExist();
        _;
    }
    /**
     * @notice Checks whether token amount > 0.
     */
    modifier mTokenNotZero(uint _tokenAmount) {
        if (_tokenAmount <= 0) revert TokenAmonutZero();
        _;
    }

    /**
     * @notice Checks whether the listing date is not in the past.
     */
    modifier mValidListingDate(uint _listingDate) {
        if (_listingDate < block.timestamp)
            revert ListingDateCanOnlyBeSetInFuture();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        IERC20 _token,
        uint _listingDate
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
        uint _listingPercentageDividend,
        uint _listingPercentageDivisor,
        uint _cliffInDays,
        uint _cliffPercentageDividend,
        uint _cliffPercentageDivisor,
        uint _vestingDurationInMonths,
        UnlockTypes _unlockType,
        uint _totalPoolTokenAmount
    )
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAddPoolDataCheck(
            _name,
            _listingPercentageDivisor,
            _cliffPercentageDivisor,
            _listingPercentageDividend,
            _cliffPercentageDividend,
            _vestingDurationInMonths
        )
        mTokenNotZero(_totalPoolTokenAmount)
    {
        Pool storage p = vestingPools[poolCount];

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

        emit VestingPoolAdded(poolCount - 1, _totalPoolTokenAmount);
    }

    /**
     * @notice Adds address with purchased token amount to vesting pool.
     * @param _poolIndex Index that refers to vesting pool object.
     * @param _address Address of the beneficiary wallet.
     * @param _tokenAmount Purchased token absolute amount (with included decimals).
     */
    function addToBeneficiariesList(
        uint _poolIndex,
        address _address,
        uint _tokenAmount
    )
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAddressNotZero(_address)
        mPoolExists(_poolIndex)
        mTokenNotZero(_tokenAmount)
    {
        Pool storage p = vestingPools[_poolIndex];

        if (p.totalPoolTokenAmount < (p.lockedPoolTokens + _tokenAmount))
            revert TokenAmountExeedsTotalPoolAmount();

        p.lockedPoolTokens += _tokenAmount;
        Beneficiary storage b = p.beneficiaries[_address];
        b.totalTokens += _tokenAmount;
        b.listingTokenAmount = getTokensByPercentage(
            b.totalTokens,
            p.listingPercentageDividend,
            p.listingPercentageDivisor
        );

        b.cliffTokenAmount = getTokensByPercentage(
            b.totalTokens,
            p.cliffPercentageDividend,
            p.cliffPercentageDivisor
        );
        b.vestedTokenAmount =
            b.totalTokens -
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
        uint _poolIndex,
        address[] calldata _addresses,
        uint[] calldata _tokenAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_addresses.length != _tokenAmount.length)
            revert ArraySizeMismatch();

        for (uint i = 0; i < _addresses.length; i++) {
            addToBeneficiariesList(_poolIndex, _addresses[i], _tokenAmount[i]);
        }
    }

    /**
     * @notice Sets new listing date and recalculates cliff and vesting end dates for all pools.
     * @param newListingDate new listing date.
     */
    function changeListingDate(
        uint newListingDate
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mValidListingDate(newListingDate) {
        uint oldListingDate = listingDate;
        listingDate = newListingDate;

        for (uint i; i < poolCount; i++) {
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
        uint _poolIndex
    )
        external
        mPoolExists(_poolIndex)
        mAddressNotZero(msg.sender)
        mOnlyBeneficiary(_poolIndex)
    {
        uint unlockedTokens = getUnlockedTokenAmount(_poolIndex, msg.sender);
        if (unlockedTokens == 0) revert NoClaimableTokens();
        if (unlockedTokens > token.balanceOf(address(this)))
            revert NotEnoughTokenBalance();

        vestingPools[_poolIndex]
            .beneficiaries[msg.sender]
            .claimedTotalTokenAmount += unlockedTokens;

        token.safeTransfer(msg.sender, unlockedTokens);

        emit Claim(msg.sender, _poolIndex, unlockedTokens);
    }

    /**
     * @notice Removes beneficiary from the structure.
     * @param _poolIndex Index that refers to vesting pool object.
     * @param _address Address of the beneficiary wallet.
     */
    function removeBeneficiary(
        uint _poolIndex,
        address _address
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mPoolExists(_poolIndex) {
        Pool storage p = vestingPools[_poolIndex];
        Beneficiary storage b = p.beneficiaries[_address];
        uint unlockedPoolAmount = b.totalTokens - b.claimedTotalTokenAmount;
        p.lockedPoolTokens -= unlockedPoolAmount;
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
        if (_customToken == token) revert CanNotWithdrawVestedTokens();
        _customToken.safeTransfer(_address, _tokenAmount);
    }

    /**
     * @notice Calculates unlocked and unclaimed tokens based on the days passed.
     * @param _address Address of the beneficiary wallet.
     * @param _poolIndex Index that refers to vesting pool object.
     * @return uint total unlocked and unclaimed tokens.
     */
    function getUnlockedTokenAmount(
        uint _poolIndex,
        address _address
    ) public view returns (uint) {
        Pool storage p = vestingPools[_poolIndex];
        Beneficiary storage b = p.beneficiaries[_address];

        if (block.timestamp < listingDate) {
            // Listing has not begun yet. Return 0.
            return 0;
        }

        if (block.timestamp < p.cliffEndDate) {
            // Cliff period has not ended yet. Unlocked listing tokens.
            return b.listingTokenAmount - b.claimedTotalTokenAmount;
        }
        if (block.timestamp >= p.vestingEndDate) {
            // Vesting period has ended. Unlocked all tokens.
            return b.totalTokens - b.claimedTotalTokenAmount;
        }
        // Cliff period has ended. Calculate vested tokens.
        (uint duration, uint periodsPassed) = getVestingPeriodsPassed(
            _poolIndex
        );
        uint unlockedTokens = b.listingTokenAmount +
            b.cliffTokenAmount +
            ((b.vestedTokenAmount * periodsPassed) / duration);

        return unlockedTokens - b.claimedTotalTokenAmount;
    }

    /**
     * @notice Calculates how many full days or months have passed since the cliff end.
     * @param _poolIndex Index that refers to vesting pool object.
     * @return If unlock type is daily: vesting duration in days, else: in months.
     * @return If unlock type is daily: number of days passed, else: number of months passed.
     */
    function getVestingPeriodsPassed(
        uint _poolIndex
    ) public view returns (uint, uint) {
        Pool storage p = vestingPools[_poolIndex];
        // Cliff not ended yet
        if (block.timestamp < p.cliffEndDate) {
            return (p.vestingDurationInMonths, 0);
        }

        uint duration = p.unlockType == UnlockTypes.DAILY
            ? p.vestingDurationInDays
            : p.vestingDurationInMonths;
        // Unlock type daily or monthly
        uint periodsPassed = (block.timestamp - p.cliffEndDate) /
            (p.unlockType == UnlockTypes.DAILY ? DAY : MONTH);

        return (duration, periodsPassed);
    }

    /**
     * @notice Calculate token amount based on the provided prcentage.
     * @param totalAmount Token amount which will be used for percentage calculation.
     * @param dividend The number from which total amount will be multiplied.
     * @param divisor The number from which total amount will be divided.
     */
    function getTokensByPercentage(
        uint totalAmount,
        uint dividend,
        uint divisor
    ) internal pure returns (uint) {
        return (totalAmount * dividend) / divisor;
    }

    /**
     * @notice Checks how many tokens unlocked in a pool (not allocated to any user).
     * @param _poolIndex Index that refers to vesting pool object.
     */
    function getTotalUnlockedPoolTokens(
        uint _poolIndex
    ) external view returns (uint) {
        Pool storage p = vestingPools[_poolIndex];
        return p.totalPoolTokenAmount - p.lockedPoolTokens;
    }

    /**
     * @notice View of the beneficiary structure.
     * @param _poolIndex Index that refers to vesting pool object.
     * @param _address Address of the beneficiary wallet.
     * @return Beneficiary structure information.
     */
    function getBeneficiaryInformation(
        uint _poolIndex,
        address _address
    ) external view returns (uint, uint, uint, uint, uint) {
        Beneficiary storage b = vestingPools[_poolIndex].beneficiaries[
            _address
        ];
        return (
            b.totalTokens,
            b.listingTokenAmount,
            b.cliffTokenAmount,
            b.vestedTokenAmount,
            b.claimedTotalTokenAmount
        );
    }

    /**
     * @notice Return global listing date value (in epoch timestamp format).
     * @return uint listing date.
     */
    function getListingDate() external view returns (uint) {
        return listingDate;
    }

    /**
     * @notice Return number of pools in contract.
     * @return uint pool count.
     */
    function getPoolCount() external view returns (uint) {
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
        uint _poolIndex
    ) external view returns (uint, uint, uint, uint, uint) {
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
        uint _poolIndex
    )
        external
        view
        returns (string memory, uint, uint, uint, uint, UnlockTypes, uint)
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
}
