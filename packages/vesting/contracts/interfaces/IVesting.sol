// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IVestingEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event Claim(
        uint16 indexed poolIndex,
        address indexed from,
        uint256 tokenAmount
    );
    event BeneficiaryAdded(
        uint16 indexed poolIndex,
        address indexed beneficiary,
        uint256 addedTokenAmount
    );
    event BeneficiaryRemoved(
        uint16 indexed poolIndex,
        address indexed beneficiary,
        uint256 unlockedPoolAmount
    );
    event ListingDateChanged(uint32 oldDate, uint32 newDate);
    event UpdatedStakedTokens(
        uint16 indexed poolIndex,
        uint256 amount,
        bool stake
    );
    event VestingPoolAdded(
        uint16 indexed poolIndex,
        uint256 totalPoolTokenAmount
    );
}

interface IVesting is IVestingEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       ENUMS
    //////////////////////////////////////////////////////////////////////////*/

    enum UnlockTypes {
        DAILY,
        MONTHLY
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct Beneficiary {
        uint256 totalTokenAmount;
        uint256 listingTokenAmount;
        uint256 cliffTokenAmount;
        uint256 vestedTokenAmount;
        uint256 stakedTokenAmount;
        uint256 claimedTokenAmount;
    }

    /// @todo make sure the order is correct
    struct Pool {
        string name;
        uint16 listingPercentageDividend;
        uint16 listingPercentageDivisor;
        uint16 cliffInDays;
        uint32 cliffEndDate;
        uint16 cliffPercentageDividend;
        uint16 cliffPercentageDivisor;
        uint16 vestingDurationInMonths;
        uint16 vestingDurationInDays;
        uint32 vestingEndDate;
        mapping(address => Beneficiary) beneficiaries;
        UnlockTypes unlockType;
        uint256 totalPoolTokenAmount;
        uint256 lockedPoolTokenAmount;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
}
