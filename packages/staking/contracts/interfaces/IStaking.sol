// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IStakingEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );
    event HarvestRewards(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );
    event PoolCreated(uint256 poolId);
    event SetBandData(uint16 bandId, uint256 price, uint256[] accessiblePools);
    event SetTotalBandAmount(uint16 newTotalBandsAmount);
    event SetTotalPoolAmount(uint16 newTotalPoolAmount);
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
        uint256[] accessiblePools; //1-9
    }

    struct Pool {
        string name;
        uint24 distributionPercentage; // in 10**6 integrals, for divident calculation
        uint24[] bandAllocationPercentage; // in 10**6, itterate as 0 = 9lvl, 1 = 8lvl...
        uint256 totalUsdtPoolTokenAmount;
        uint256 totalUsdcPoolTokenAmount;
        mapping(bytes32 hashedStakerAndBandId => StakerPoolData) stakedPoolData;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

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

    function setBandData(
        uint16 bandId,
        uint256 price,
        uint256[] memory accessiblePools
    ) external;

    function setTotalBandAmount(uint16 newTotalBandsAmount) external;

    function setTotalPoolAmount(uint16 newTotalPoolAmount) external;
}
