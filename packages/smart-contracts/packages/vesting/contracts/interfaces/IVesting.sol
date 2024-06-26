// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {IStaking} from "@wealth-of-wisdom/staking/contracts/interfaces/IStaking.sol";

interface IVestingEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event AllTokensClaimed(address indexed user, uint256 tokenAmount);

    event VestingPoolAdded(
        uint16 indexed poolIndex,
        uint256 totalPoolTokenAmount
    );

    event GeneralPoolDataUpdated(
        uint16 indexed poolIndex,
        string name,
        IVesting.UnlockTypes unlockType,
        uint256 totalPoolTokenAmount
    );

    event PoolListingDataUpdated(
        uint16 indexed poolIndex,
        uint16 listingPercentageDividend,
        uint16 listingPercentageDivisor
    );

    event PoolCliffDataUpdated(
        uint16 indexed poolIndex,
        uint32 cliffEndDate,
        uint16 cliffInDays,
        uint16 cliffPercentageDividend,
        uint16 cliffPercentageDivisor
    );

    event PoolVestingDataUpdated(
        uint16 indexed poolIndex,
        uint32 vestingEndDate,
        uint16 vestingDurationInMonths,
        uint16 vestingDurationInDays
    );

    event BeneficiaryAdded(
        uint16 indexed poolIndex,
        address indexed beneficiary,
        uint256 addedTokenAmount
    );

    event BeneficiaryRemoved(
        uint16 indexed poolIndex,
        address indexed beneficiary,
        uint256 availableAmount
    );

    event ListingDateChanged(uint32 oldDate, uint32 newDate);

    event ContractTokensWithdrawn(
        IERC20 indexed customToken,
        address indexed recipient,
        uint256 tokenAmount
    );

    event StakingContractSet(IStaking indexed newContract);

    event TokensClaimed(
        uint16 indexed poolIndex,
        address indexed user,
        uint256 tokenAmount
    );

    event VestedTokensStaked(
        uint16 indexed poolIndex,
        address indexed beneficiary,
        uint256 amount,
        uint256 bandId
    );

    event VestedTokensUnstaked(
        uint16 indexed poolIndex,
        address indexed beneficiary,
        uint256 amount,
        uint256 bandId
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
        uint256 dedicatedPoolTokenAmount;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(
        IERC20 token,
        IStaking stakingContract,
        uint32 listingDate
    ) external;

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

    function updateGeneralPoolData(
        uint16 pid,
        string calldata name,
        UnlockTypes unlockType,
        uint256 totalPoolTokenAmount
    ) external;

    function updatePoolListingData(
        uint16 pid,
        uint16 listingPercentageDividend,
        uint16 listingPercentageDivisor
    ) external;

    function updatePoolCliffData(
        uint16 pid,
        uint16 cliffInDays,
        uint16 cliffPercentageDividend,
        uint16 cliffPercentageDivisor
    ) external;

    function updatePoolVestingData(
        uint16 pid,
        uint16 vestingDurationInMonths
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

    function removeBeneficiary(uint16 pid, address beneficiary) external;

    function changeListingDate(uint32 newListingDate) external;

    function setStakingContract(IStaking newStaking) external;

    function claimTokens(uint16 pid) external;

    function claimAllTokens() external;

    function stakeVestedTokens(
        IStaking.StakingTypes stakingType,
        uint16 bandLevel,
        uint8 month,
        uint16 pid
    ) external;

    function unstakeVestedTokens(uint256 bandId) external;

    function getBeneficiary(
        uint16 pid,
        address user
    ) external view returns (Beneficiary memory beneficiary);

    function getListingDate() external view returns (uint32 listingDate);

    function getPoolCount() external view returns (uint16 poolCount);

    function getToken() external view returns (IERC20 token);

    function getStakingContract() external view returns (IStaking staking);

    function getGeneralPoolData(
        uint16 pid
    )
        external
        view
        returns (
            string memory name,
            UnlockTypes unlockType,
            uint256 totalTokensAmount,
            uint256 dedicatedTokensAmount
        );

    function getPoolListingData(
        uint16 pid
    )
        external
        view
        returns (
            uint16 listingPercentageDividend,
            uint16 listingPercentageDivisor
        );

    function getPoolCliffData(
        uint16 pid
    )
        external
        view
        returns (
            uint32 cliffEndDate,
            uint16 cliffInDays,
            uint16 cliffPercentageDividend,
            uint16 cliffPercentageDivisor
        );

    function getPoolVestingData(
        uint16 pid
    )
        external
        view
        returns (
            uint32 vestingEndDate,
            uint16 vestingDurationInMonths,
            uint16 vestingDurationInDays
        );

    function getUnlockedTokenAmount(
        uint16 pid,
        address beneficiary
    ) external view returns (uint256 unlockedAmount);

    function getVestingPeriodsPassed(
        uint16 pid
    ) external view returns (uint16 periodsPassed, uint16 duration);
}
