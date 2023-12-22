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

    event VestingPoolAdded(
        uint16 indexed poolIndex,
        uint256 totalPoolTokenAmount
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

    event ContractTokensWithdrawn(
        IERC20 indexed customToken,
        address indexed recipient,
        uint256 tokenAmount
    );

    event TokensClaimed(
        uint16 indexed poolIndex,
        address indexed user,
        uint256 tokenAmount
    );

    event StakedTokensUpdated(
        uint16 indexed poolIndex,
        uint256 amount,
        bool stake
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
        UnlockTypes unlockType;
        mapping(address => Beneficiary) beneficiaries;
        uint256 totalPoolTokenAmount;
        uint256 lockedPoolTokenAmount;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(IERC20 token, uint32 listingDate) external;

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
    ) external;

    function addBeneficiary(
        uint16 pid,
        address beneficiary,
        uint256 tokenAmount
    ) external;

    function addMultipleBeneficiaries(
        uint16 pid,
        address[] calldata beneficiaries,
        uint256[] calldata tokenAmounts
    ) external;

    function changeListingDate(uint32 newListingDate) external;

    function removeBeneficiary(uint16 pid, address beneficiary) external;

    function withdrawContractTokens(
        IERC20 customToken,
        address recipient,
        uint256 tokenAmount
    ) external;

    function claimTokens(uint16 pid) external;

    function updateVestedStakedTokens(
        uint16 pid,
        address beneficiary,
        uint256 tokenAmount,
        bool isStaking
    ) external;

    function getTotalUnlockedPoolTokens(
        uint16 pid
    ) external view returns (uint256);

    function getBeneficiaryInformation(
        uint16 pid,
        address _address
    ) external view returns (uint256, uint256, uint256, uint256, uint256);

    function getListingDate() external view returns (uint32);

    function getPoolCount() external view returns (uint16);

    function getToken() external view returns (IERC20);

    function getPoolDates(
        uint16 pid
    ) external view returns (uint16, uint32, uint16, uint16, uint32);

    function getPoolData(
        uint16 pid
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
        );

    function getUnlockedTokenAmount(
        uint16 pid,
        address beneficiary
    ) external view returns (uint256);

    function getVestingPeriodsPassed(
        uint16 pid
    ) external view returns (uint16, uint16);
}
