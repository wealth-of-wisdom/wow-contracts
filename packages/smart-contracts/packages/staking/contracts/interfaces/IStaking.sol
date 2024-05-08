// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IStakingEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event InitializedContractData(
        IERC20 usdtToken,
        IERC20 usdcToken,
        IERC20 wowToken,
        uint16 totalPools,
        uint16 totalBandLevels
    );

    event PoolSet(uint16 indexed poolId, uint32 distributionPercentage);

    event BandLevelSet(uint16 indexed bandLevel, uint256 price);

    event SharesInMonthSet(uint48[] totalSharesInMonth);

    event UsdtTokenSet(IERC20 token);

    event UsdcTokenSet(IERC20 token);

    event WowTokenSet(IERC20 token);

    event TotalBandLevelsAmountSet(uint16 newTotalBandsAmount);

    event TotalPoolAmountSet(uint16 newTotalPoolAmount);

    event BandUpgradeStatusSet(bool enabled);

    event DistributionStatusSet(bool inProgress);

    event TokensWithdrawn(IERC20 token, address receiver, uint256 amount);

    event DistributionCreated(
        IERC20 token,
        uint256 amount,
        uint16 totalPools,
        uint16 totalBandLevels,
        uint256 totalStakers,
        uint256 distributionTimestamp
    );

    event RewardsDistributed(IERC20 token);

    event SharesSyncTriggered();

    event Staked(
        address user,
        uint16 bandLevel,
        uint256 bandId,
        uint8 fixedMonths,
        IStaking.StakingTypes stakingType,
        bool areTokensVested
    );

    event Unstaked(address user, uint256 bandId, bool areTokensVested);

    event VestingUserDeleted(address user);

    event BandUpgraded(
        address user,
        uint256 bandId,
        uint16 oldBandLevel,
        uint16 newBandLevel
    );

    event BandDowngraded(
        address user,
        uint256 bandId,
        uint16 oldBandLevel,
        uint16 newBandLevel
    );

    event RewardsClaimed(address user, IERC20 token, uint256 totalRewards);
}

interface IStaking is IStakingEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       ENUMS
    //////////////////////////////////////////////////////////////////////////*/

    enum StakingTypes {
        FIX,
        FLEXI
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct StakerBand {
        address owner; // staker who owns the band
        uint32 stakingStartDate; // timestamp for initial band creation
        uint16 bandLevel; // band levels (1-9)
        uint8 fixedMonths; // 0 for flexi, 1-24 for fix
        StakingTypes stakingType; // FLEXI or FIX
        bool areTokensVested; // true if tokens from which the band was created are vested
    }

    struct StakerReward {
        uint256 unclaimedAmount; // amount of tokens that can be claimed
        uint256 claimedAmount; // amount of tokens that have been claimed
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(
        IERC20 usdtToken,
        IERC20 usdcToken,
        IERC20 wowToken,
        address vesting,
        address gelato,
        uint16 totalPools,
        uint16 totalBandLevels
    ) external;

    function setPoolDistributionPercentage(
        uint16 poolId,
        uint32 distributionPercentage
    ) external;

    function setBandLevel(uint16 bandLevel, uint256 price) external;

    function setSharesInMonth(uint48[] calldata totalSharesInMonth) external;

    function setUsdtToken(IERC20 token) external;

    function setUsdcToken(IERC20 token) external;

    function setWowToken(IERC20 token) external;

    function setTotalBandLevelsAmount(uint16 newTotalBandsAmount) external;

    function setTotalPoolAmount(uint16 newTotalPoolAmount) external;

    function setBandUpgradesEnabled(bool enabled) external;

    function setDistributionInProgress(bool inProgress) external;

    function withdrawTokens(IERC20 token, uint256 amount) external;

    function createDistribution(IERC20 token, uint256 amount) external;

    function distributeRewards(
        IERC20 token,
        address[] memory stakers,
        uint256[] memory rewards
    ) external;

    function triggerSharesSync() external;

    function stake(
        StakingTypes stakingType,
        uint16 bandLevel,
        uint8 month
    ) external;

    function unstake(uint256 bandId) external;

    function stakeVested(
        address user,
        StakingTypes stakingType,
        uint16 bandLevel,
        uint8 month
    ) external returns (uint256 bandId);

    function unstakeVested(address user, uint256 bandId) external;

    function deleteVestingUser(address user) external;

    function upgradeBand(uint256 bandId, uint16 newBandLevel) external;

    function downgradeBand(uint256 bandId, uint16 newBandLevel) external;

    function claimRewards(IERC20 token) external;

    function getTokenUSDT() external view returns (IERC20);

    function getTokenUSDC() external view returns (IERC20);

    function getTokenWOW() external view returns (IERC20);

    function getTotalPools() external view returns (uint16);

    function getTotalBandLevels() external view returns (uint16);

    function getNextBandId() external view returns (uint256);

    function getSharesInMonthArray() external view returns (uint48[] memory);

    function getSharesInMonth(
        uint256 index
    ) external view returns (uint48 shares);

    function getPoolDistributionPercentage(
        uint16 poolId
    ) external view returns (uint32 distributionPercentage);

    function getBandLevel(
        uint16 bandLevel
    ) external view returns (uint256 price);

    function getStakerBand(
        uint256 bandId
    )
        external
        view
        returns (
            address owner,
            uint32 stakingStartDate,
            uint16 bandLevel,
            uint8 fixedMonths,
            StakingTypes stakingType,
            bool areTokensVested
        );

    function getStakerReward(
        address staker,
        IERC20 token
    ) external view returns (uint256 unclaimedAmount, uint256 claimedAmount);

    function getStakerBandIds(
        address staker
    ) external view returns (uint256[] memory bandIds);

    function getUser(uint256 index) external view returns (address user);

    function getTotalUsers() external view returns (uint256 usersAmount);

    function areBandUpgradesEnabled() external view returns (bool enabled);

    function isDistributionInProgress() external view returns (bool inProgress);

    function getPeriodDuration() external pure returns (uint32);
}
