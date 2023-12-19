// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library Vesting {
    enum UnlockTypes {
        DAILY,
        MONTHLY
    }

    struct Beneficiary {
        bool isWhitelisted;
        uint256 totalTokens;
        uint256 listingTokenAmount;
        uint256 cliffTokenAmount;
        uint256 vestedTokenAmount;
        uint256 claimedTotalTokenAmount;
    }

    struct Pool {
        string name;
        uint256 listingDate;
        uint256 listingPercentageDividend;
        uint256 listingPercentageDivisor;
        uint256 cliff;
        uint256 cliffEndDate;
        uint256 cliffPercentageDividend;
        uint256 cliffPercentageDivisor;
        uint256 vestingDurationInMonths;
        uint256 vestingDurationInDays;
        uint256 vestingEndDate;
        mapping(address => Beneficiary) beneficiaries;
        address[] beneficiaryList;
        UnlockTypes unlockType;
        uint256 poolTokenAmount;
        uint256 lockedPoolTokens;
    }

    /**
     * @notice Sets the vesting pool settings.
     * Function calculates cliff and vesting end dates based on listing date, cliff and vesting periods.
     * Percentage is provided in the fractional form with divident and divisors.
     * @dev Function calling this library should be restricted with role (e.g. onlyOwner).
     * @param p Vesting pool object to be edited with given values.
     * @param _name Vesting pool name.
     * @param _listingDate The start of token distribution. Format in seconds since epoch start (timestamp).
     * @param _listingPercentageDividend Percentage fractional form dividend part.
     * @param _listingPercentageDivisor Percentage fractional form divisor part.
     * @param _cliff Period of the first lock (cliff) in days.
     * @param _cliffPercentageDividend Percentage fractional form dividend part.
     * @param _cliffPercentageDivisor Percentage fractional form divisor part.
     * @param _vestingDurationInMonths Duration of the vesting period in days (integer).
     * @param _poolTokenAmount Total amount of pool tokens available for claiming.
     */
    function setPool(
        Pool storage p,
        string memory _name,
        uint256 _listingDate,
        uint256 _listingPercentageDividend,
        uint256 _listingPercentageDivisor,
        uint256 _cliff,
        uint256 _cliffPercentageDividend,
        uint256 _cliffPercentageDivisor,
        uint256 _vestingDurationInMonths,
        UnlockTypes _unlockType,
        uint256 _poolTokenAmount
    ) external {
        require(
            (_listingPercentageDivisor > 0 && _cliffPercentageDivisor > 0),
            "Percentage divisor can not be zero."
        );
        p.name = _name;
        p.listingDate = _listingDate;
        p.listingPercentageDividend = _listingPercentageDividend;
        p.listingPercentageDivisor = _listingPercentageDivisor;
        p.cliff = _cliff;
        p.cliffEndDate = p.listingDate + (_cliff * 1 days);
        p.cliffPercentageDividend = _cliffPercentageDividend;
        p.cliffPercentageDivisor = _cliffPercentageDivisor;
        p.vestingDurationInMonths = _vestingDurationInMonths;
        p.vestingDurationInDays = _vestingDurationInMonths * 30;
        p.vestingEndDate = p.cliffEndDate + (p.vestingDurationInDays * 1 days);
        p.unlockType = _unlockType;
        p.poolTokenAmount = _poolTokenAmount;
    }

    /**
     * @notice Adds address with purchased token amount to the beneficiary structure.
     * @dev Function calling this library should be restricted with role (e.g. onlyOwner).
     * @param p Vesting pool object that holds mapping to the Beneficiary.
     * @param _address Address of the beneficiary wallet.
     * @param _tokenAmount Purchased token absolute amount (with included decimals).
     */
    function addToBeneficiariesList(
        Pool storage p,
        address _address,
        uint256 _tokenAmount
    ) public {
        require(
            p.poolTokenAmount >= (p.lockedPoolTokens + _tokenAmount),
            "Allocated token amount will exceed total pool amount."
        );

        p.lockedPoolTokens += _tokenAmount;

        Beneficiary storage b = p.beneficiaries[_address];
        b.isWhitelisted = true;
        b.totalTokens = _tokenAmount;
        b.listingTokenAmount = calculateTokensOnPercentage(
            _tokenAmount,
            p.listingPercentageDividend,
            p.listingPercentageDivisor
        );
        b.cliffTokenAmount = calculateTokensOnPercentage(
            _tokenAmount,
            p.cliffPercentageDividend,
            p.cliffPercentageDivisor
        );
        b.vestedTokenAmount =
            b.totalTokens -
            b.listingTokenAmount -
            b.cliffTokenAmount;
        p.beneficiaryList.push(_address);
    }

    /**
     * @notice Adds addresses with purchased token amount to the beneficiary list.
     * @dev Function calling this library should be restricted with role (e.g. onlyOwner).
     * @dev Example of parameters: ["address1","address2"], ["address1Amount", "address2Amount"].
     * @param p Vesting pool object that holds mapping to the Beneficiary.
     * @param _addresses List of whitelisted addresses.
     * @param _tokenAmount Purchased token absolute amount (with included decimals).
     */
    function addToBeneficiariesListMultiple(
        Pool storage p,
        address[] calldata _addresses,
        uint256[] calldata _tokenAmount
    ) external {
        require(
            _addresses.length == _tokenAmount.length,
            "Addresses and token amount arrays must be the same size"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            addToBeneficiariesList(p, _addresses[i], _tokenAmount[i]);
        }
    }

    /**
     * @notice Calculate token amount based on the provided prcentage.
     * @param totalAmount Token amount which will be used for percentage calculation.
     * @param dividend The number from which total amount will be multiplied.
     * @param divisor The number from which total amount will be divided.
     */
    function calculateTokensOnPercentage(
        uint256 totalAmount,
        uint256 dividend,
        uint256 divisor
    ) public pure returns (uint256) {
        return (totalAmount * dividend) / divisor;
    }

    /**
     * @notice Check how many tokens are unclaimed by addresses in the pool.
     * @param p Pool object.
     */
    function totalUnclaimedPoolTokens(
        Pool storage p
    ) public view returns (uint256) {
        uint256 totalAmountOfTokens = 0;
        for (uint256 i = 0; i < p.beneficiaryList.length; i++) {
            Beneficiary memory b = p.beneficiaries[p.beneficiaryList[i]];
            uint256 unclaimedTokens = b.totalTokens - b.claimedTotalTokenAmount;
            totalAmountOfTokens += unclaimedTokens;
        }
        return totalAmountOfTokens;
    }

    /**
     * @notice Check how many tokens are free in a pool (not allocated to any user).
     * @param p Pool object.
     */
    function totalUnusedPoolTokens(
        Pool storage p
    ) public view returns (uint256) {
        return p.poolTokenAmount - p.lockedPoolTokens;
    }

    /**
     * @notice Deletes beneficiary from the mapping.
     * @dev Function calling this library should be restricted with role (e.g. onlyOwner).
     * @param p Vesting pool object that holds mapping to the Beneficiary.
     * @param _address Address of the beneficiary wallet to be removed.
     */
    function removeBeneficiary(Pool storage p, address _address) external {
        Beneficiary storage b = p.beneficiaries[_address];
        p.lockedPoolTokens -= (b.totalTokens - b.claimedTotalTokenAmount);
        delete p.beneficiaries[_address];
    }

    /**
     * @notice Changes listing date and recalculates cliff and vesting end dates.
     * @dev Function calling this library should be restricted with role (e.g. onlyOwner).
     * @param p Vesting pool object to be edited with given values.
     * @param _listingDate New listing date.
     */
    function changeListingDate(Pool storage p, uint256 _listingDate) external {
        require(p.cliffPercentageDivisor > 0, "Pool does not exist.");
        p.listingDate = _listingDate;
        p.cliffEndDate = _listingDate + (p.cliff * 1 days);
        p.vestingEndDate = p.cliffEndDate + (p.vestingDurationInDays * 1 days);
    }

    /**
     * @notice Calculates unlocked and unclaimed tokens based on the days passed.
     * @param p Vesting pool object that holds mapping to the Beneficiary.
     * @param _address Wallet of the beneficiary that is in the pool mapping.
     * @return Total unlocked and unclaimed tokens.
     */
    function unlockedTokenAmount(
        Pool storage p,
        address _address
    ) external view returns (uint256) {
        Beneficiary storage b = p.beneficiaries[_address];
        uint256 unlockedTokens = 0;

        if (block.timestamp < p.listingDate) {
            // Listing has not begun yet. Return 0.
            return unlockedTokens;
        } else if (block.timestamp < p.cliffEndDate) {
            // Cliff period has not ended yet. Unlocked listing tokens.
            unlockedTokens = b.listingTokenAmount;
        } else if (block.timestamp >= p.vestingEndDate) {
            // Vesting period has ended. Unlocked all tokens.
            unlockedTokens = b.totalTokens;
        } else {
            // Cliff period has ended. Calculate vested tokens.
            (uint256 duration, uint256 periodsPassed) = vestingPeriodsPassed(p);
            unlockedTokens =
                b.listingTokenAmount +
                b.cliffTokenAmount +
                (b.vestedTokenAmount / duration) *
                periodsPassed;
        }
        return unlockedTokens - b.claimedTotalTokenAmount;
    }

    /**
     * @notice Calculates how many full days or months have passed since the cliff end.
     * @return If unlock type is daily: vesting duration in days, else: in months.
     * @return If unlock type is daily: number of days passed, else: number of months passed.
     */
    function vestingPeriodsPassed(
        Pool storage p
    ) public view returns (uint256, uint256) {
        // Cliff not ended yet
        if (block.timestamp < p.cliffEndDate) {
            return (p.vestingDurationInMonths, 0);
        }
        // Unlock type daily
        else if (p.unlockType == UnlockTypes.DAILY) {
            return (
                p.vestingDurationInDays,
                (block.timestamp - p.cliffEndDate) / 1 days
            );
            // Unlock type monthly
        } else {
            return (
                p.vestingDurationInMonths,
                (block.timestamp - p.cliffEndDate) / 30 days
            );
        }
    }

    /**
     * @notice View of the beneficiary structure.
     * @param b The beneficiary object.
     * @return Beneficiary structure information.
     */
    function beneficiaryInformation(
        Beneficiary storage b
    )
        external
        view
        returns (bool, uint256, uint256, uint256, uint256, uint256)
    {
        return (
            b.isWhitelisted,
            b.totalTokens,
            b.listingTokenAmount,
            b.cliffTokenAmount,
            b.vestedTokenAmount,
            b.claimedTotalTokenAmount
        );
    }

    /**
     * @notice View of the vesting pool structure.
     * @param p The vesting pool object
     * @return Pool structure dates and timestamps.
     */
    function poolDates(
        Pool storage p
    )
        public
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        return (
            p.listingDate,
            p.cliff,
            p.cliffEndDate,
            p.vestingDurationInDays,
            p.vestingDurationInMonths,
            p.vestingEndDate
        );
    }

    /**
     * @notice View of the vesting pool structure.
     * @param p The vesting pool object
     * @return Part of the vesting pool information. (Without the dates).
     */
    function poolData(
        Pool storage p
    )
        public
        view
        returns (
            string memory,
            uint256,
            uint256,
            uint256,
            uint256,
            UnlockTypes,
            uint256
        )
    {
        return (
            p.name,
            p.listingPercentageDividend,
            p.listingPercentageDivisor,
            p.cliffPercentageDividend,
            p.cliffPercentageDivisor,
            p.unlockType,
            p.poolTokenAmount
        );
    }
}
