// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IStakingEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event PoolSet(uint16 indexed poolId, uint48 distributionPercentage);

    event BandLevelSet(
        uint16 indexed bandLevel,
        uint256 price,
        uint16[] accessiblePools
    );

    event SharesInMonthSet(uint48[] totalSharesInMonth);

    event UsdtTokenSet(IERC20 token);

    event UsdcTokenSet(IERC20 token);

    event WowTokenSet(IERC20 token);

    event TotalBandLevelsAmountSet(uint16 newTotalBandsAmount);

    event TotalPoolAmountSet(uint16 newTotalPoolAmount);

    event TokensWithdrawn(IERC20 token, address receiver, uint256 amount);

    event DistributionCreated(
        IERC20 token,
        uint256 amount,
        uint256 totalPools,
        uint256 totalBandLevels,
        uint256 totalStakers
    );

    event RewardsDistributed(IERC20 token);

    event Staked(
        address user,
        uint16 bandLevel,
        uint256 bandId,
        IStaking.StakingTypes stakingType,
        bool isVested
    );

    event Unstaked(address user, uint256 bandId, bool isVested);

    event BandUnstaked(address user, uint16 bandLevel, uint256 bandId);

    event VestingUserRemoved(address vestingSaker);

    event BandUpgaded(
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
        uint256 stakingStartDate;
        uint256 fixedShares;
        address owner;
        uint16 bandLevel;
        StakingTypes stakingType;
    }

    struct StakerReward {
        uint256 unclaimedAmount;
        uint256 claimedAmount;
    }

    struct BandLevel {
        uint256 price;
        uint16[] accessiblePools; // 1-9
    }

    struct Pool {
        uint48 distributionPercentage; // in 10**6 integrals, for divident calculation
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(
        IERC20 usdtToken,
        IERC20 usdcToken,
        IERC20 wowToken,
        uint16 totalPools,
        uint16 totalBandLevels
    ) external;

    function setPool(uint16 poolId, uint48 distributionPercentage) external;

    function setBandLevel(
        uint16 bandLevel,
        uint256 price,
        uint16[] calldata accessiblePools
    ) external;

    function setSharesInMonth(uint48[] calldata totalSharesInMonth) external;

    function setUsdtToken(IERC20 token) external;

    function setUsdcToken(IERC20 token) external;

    function setWowToken(IERC20 token) external;

    function setTotalBandLevelsAmount(uint16 newTotalBandsAmount) external;

    function setTotalPoolAmount(uint16 newTotalPoolAmount) external;

    function withdrawTokens(IERC20 token, uint256 amount) external;

    function createDistribution(IERC20 token, uint256 amount) external;

    function distributeRewards(
        IERC20 token,
        address[] memory stakers,
        uint256[] memory rewards
    ) external;

    function stake(StakingTypes stakingType, uint16 bandLevel) external;

    function unstake(uint256 bandId) external;

    function stakeVested(
        StakingTypes stakingType,
        uint16 bandLevel,
        address user
    ) external;

    function unstakeVested(uint256 bandId, address user) external;

    function deleteVestingUserData(address user) external;

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

    function getPool(
        uint16 poolId
    ) external view returns (uint48 distributionPercentage);

    function getBandLevel(
        uint16 bandLevel
    ) external view returns (uint256 price, uint16[] memory accessiblePools);

    function getStakerBand(
        uint256 bandId
    )
        external
        view
        returns (
            uint256 stakingStartDate,
            uint256 fixedShares,
            address owner,
            uint16 bandLevel,
            StakingTypes stakingType
        );

    function getStakerReward(
        address staker,
        IERC20 token
    ) external view returns (uint256 unclaimedAmount, uint256 claimedAmount);

    function getStakerBandIds(
        address staker
    ) external view returns (uint256[] memory bandIds);

    function getUser(uint256 index) external view returns (address user);
}
