// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IStakingEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event PoolSet(uint16 indexed poolId);

    event BandSet(uint16 bandLevel);

    event FundsDistributed(IERC20 token, uint256 amount);

    event Staked(
        address user,
        uint16 bandLevel,
        IStaking.StakingTypes stakingType,
        bool isVested
    );

    event Unstaked(address user, uint256 bandId, bool isVested);

    event BandStaked(address user, uint16 bandLevel, uint256 bandId);

    event BandUnstaked(address user, uint16 bandLevel, uint256 bandId);

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

    event TotalBandAmountSet(uint16 newTotalBandsAmount);

    event TotalPoolAmountSet(uint16 newTotalPoolAmount);

    event TokensWithdrawn(IERC20 token, address receiver, uint256 amount);

    event RewardsClaimed(address user, IERC20 token, uint256 totalRewards);

    event AllRewardsClaimed(address user);
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

    // Distribution of funds

    struct FundDistribution {
        uint256 id;
        IERC20 token;
        uint256 amount;
        uint256 timestamp;
    }

    struct PoolDistribution {
        IERC20 token;
        uint256 tokensAmount;
        uint256 sharesAmount;
    }

    struct StakerShares {
        uint256 shares;
        bool claimed;
    }

    // Staking

    struct StakerBandData {
        StakingTypes stakingType;
        uint256 startingSharesAmount;
        address owner;
        uint16 bandLevel;
        uint256 stakingStartTimestamp;
        uint256 usdtRewardsClaimed;
        uint256 usdcRewardsClaimed;
    }

    struct Band {
        uint256 price;
        uint16[] accessiblePools; // 1-9
        uint256 stakingTimespan;
    }

    struct Pool {
        uint48 distributionPercentage; // in 10**6 integrals, for divident calculation
        uint256 totalUsdtPoolTokenAmount;
        uint256 totalUsdcPoolTokenAmount;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function setPool(uint16 poolId, uint48 distributionPercentage) external;

    function setBand(
        uint16 bandLevel,
        uint256 price,
        uint16[] memory accessiblePools,
        uint256 stakingTimespan
    ) external;

    function setTotalBandAmount(uint16 newTotalBandsAmount) external;

    function setTotalPoolAmount(uint16 newTotalPoolAmount) external;

    function distributeFunds(IERC20 token, uint256 amount) external;

    function withdrawTokens(IERC20 token, uint256 amount) external;

    function stake(StakingTypes stakingType, uint16 bandLevel) external;

    function unstake(uint256 bandId) external;

    function stakeVested(
        StakingTypes stakingType,
        uint16 bandLevel,
        address user
    ) external;

    // /**
    //  * @notice Stops staking of vested tokens for a beneficiary in a pool
    //  * @notice Beneficiary needs to claim staking rewards with an external call
    //  * @notice This function can only be called by the vesting contract
    //  */
    function unstakeVested(uint256 bandId, address user) external;

    function deleteVestingUserData(address user) external;

    function upgradeBand(uint256 bandId, uint16 newBandLevel) external;

    function downgradeBand(uint256 bandId, uint16 newBandLevel) external;

    function claimAllRewards() external;

    function claimPoolRewards(IERC20 token, uint16 poolId) external;

    function getTokenUSDT() external view returns (IERC20);

    function getTokenUSDC() external view returns (IERC20);

    function getTokenWOW() external view returns (IERC20);

    function getTotalPools() external view returns (uint16);

    function getTotalBands() external view returns (uint16);

    function getPool(
        uint16 poolId
    )
        external
        view
        returns (
            uint48 distributionPercentage,
            uint256 usdtTokenAmount,
            uint256 usdcTokenAmount
        );

    function getBand(
        uint16 bandLevel
    )
        external
        view
        returns (
            uint256 price,
            uint16[] memory accessiblePools,
            uint256 stakingTimespan
        );
}
