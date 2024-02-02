// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IStakingEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event PoolSet(uint16 indexed poolId);

    event BandSet(uint16 bandId);

    event TotalBandAmountSet(uint16 newTotalBandsAmount);

    event TotalPoolAmountSet(uint16 newTotalPoolAmount);

    event TokensWithdrawn(IERC20 token, address receiver, uint256 amount);
}

interface IStaking is IStakingEvents {
    /*////////////////////////////////////////////////////////////////  //////////
                                       ENUMS
    //////////////////////////////////////////////////////////////////////////*/
    enum StakingTypes {
        FIX,
        FLEXI
    }
    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct FundDistribution {
        IERC20 token;
        uint256 amount;
        uint256 distributionPeriodStart;
        uint256 distributionPeriodEnd;
    }

    struct StakerBandData {
        StakingTypes stakingType;
        uint256 stakingStartTimestamp;
        uint256 usdtRewardsClaimed;
        uint256 usdcRewardsClaimed;
    }
    struct Band {
        uint256 price;
        uint16[] accessiblePools; //1-9
        uint256 stakingTimespan;
    }

    struct Pool {
        uint48 distributionPercentage; // in 10**6 integrals, for divident calculation
        uint48[] bandAllocationPercentage; // in 10**6, start from the last level: 0 = 9lvl, 1 = 8lvl...
        uint256 totalUsdtPoolTokenAmount;
        uint256 totalUsdcPoolTokenAmount;
        address[] allUsers;
        mapping(address staker => bool isUserInPool) userCheck;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function setPool(
        uint16 poolId,
        uint48 distributionPercentage,
        uint48[] memory bandAllocationPercentage
    ) external;

    // /**
    //  * @notice Stops staking of vested tokens for a beneficiary in a pool
    //  * @notice Beneficiary needs to claim staking rewards with an external call
    //  * @notice This function can only be called by the vesting contract
    //  * @param beneficiary Address of the beneficiary
    //  * @param stakedAmount Amount of tokens to unstake
    //  */
    // function unstakeVestedTokens(
    //     address beneficiary,
    //     uint256 stakedAmount
    // ) external;

    function setBand(
        uint16 bandId,
        uint256 price,
        uint16[] memory accessiblePools,
        uint256 stakingTimespan
    ) external;

    function setTotalBandAmount(uint16 newTotalBandsAmount) external;

    function setTotalPoolAmount(uint16 newTotalPoolAmount) external;

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
            uint48[] memory bandAllocationPercentage,
            uint256 usdtTokenAmount,
            uint256 usdcTokenAmount,
            address[] memory allUsers
        );

    function getBand(
        uint16 bandId
    )
        external
        view
        returns (
            uint256 price,
            uint16[] memory accessiblePools,
            uint256 stakingTimespan
        );
}
