// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IStakingEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event PoolSet(uint16 indexed poolId, string name);

    event BandDataSet(uint16 bandId, uint256 price, uint16[] accessiblePools);

    event TotalBandAmountSet(uint16 newTotalBandsAmount);

    event TotalPoolAmountSet(uint16 newTotalPoolAmount);
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

    struct StakerPoolData {
        StakingTypes stakingType;
        uint256 stakingStartTimestamp;
        uint256 stakingTimespan;
        uint256 amountStaked;
        uint256 usdtRewardsClaimed;
        uint256 usdcRewardsClaimed;
        //additional data TBD
    }
    struct Band {
        uint256 price;
        uint16[] accessiblePools; //1-9
    }

    struct Pool {
        string name;
        uint48 distributionPercentage; // in 10**6 integrals, for divident calculation
        uint48[] bandAllocationPercentage; // in 10**6, start from the last level: 0 = 9lvl, 1 = 8lvl...
        uint256 totalUsdtPoolTokenAmount;
        uint256 totalUsdcPoolTokenAmount;
        mapping(bytes32 hashedStakerAndBandId => StakerPoolData) stakedPoolData;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function setPool(
        uint16 poolId,
        string memory name,
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
        uint16[] memory accessiblePools
    ) external;

    function setTotalBandAmount(uint16 newTotalBandsAmount) external;

    function setTotalPoolAmount(uint16 newTotalPoolAmount) external;

    function getTokenUSDT() external view returns (IERC20);

    function getTokenUSDC() external view returns (IERC20);

    function getTokenWOW() external view returns (IERC20);

    function getTotalPools() external view returns (uint16);

    function getTotalBands() external view returns (uint16);
}
