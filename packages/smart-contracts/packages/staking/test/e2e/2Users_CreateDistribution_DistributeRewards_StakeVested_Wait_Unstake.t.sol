// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {StakingAssertions} from "./StakingAssertions.t.sol";

struct Balances {
    uint256 alicePreStakingBalance;
    uint256 alicePostUnstakingBalance;
    uint256 alicePostClaimingBalance;
    uint256 bobPreStakingBalance;
    uint256 bobPostUnstakingBalance;
    uint256 bobPostClaimingBalance;
    uint256 stakingBalanceBefore;
    uint256 stakingPreClaimingBalance;
    uint256 stakingPostUnstakingBalance;
    uint256 adminBalanceBefore;
}

contract Staking_E2E_Test is StakingAssertions {
    function test_With2Users_CreateDistribution_DistributeRewards_StakeVested_Wait_Unstake()
        external
        setBandLevelData
    {
        /**
         * 1. Alice stakes to level 2 band
         * 2. Bob stakes to level 4 band
         * 3. Both users wait
         * 4. Distribution created
         * 5. Distribute rewards
         * 6. Both users unstake
         */
        // ARRANGE + ACT
        Balances memory balances;

        balances.alicePreStakingBalance = wowToken.balanceOf(alice);
        balances.bobPreStakingBalance = wowToken.balanceOf(bob);
        uint256 firstBandId = staking.getNextBandId();

        {
            vm.startPrank(alice);
            wowToken.approve(address(staking), BAND_2_PRICE);
            staking.stake(STAKING_TYPE_FLEXI, BAND_LEVEL_2, MONTH_0);
            vm.stopPrank();
        }

        uint256 secondBandId = staking.getNextBandId();

        {
            vm.startPrank(bob);
            wowToken.approve(address(staking), BAND_4_PRICE);
            staking.stake(STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0);
            vm.stopPrank();

            assertStaked(alice, firstBandId, BAND_LEVEL_2, 1);
            assertStaked(bob, secondBandId, BAND_LEVEL_4, 1);

            skip(MONTH);
        }

        uint256 adminBalanceBefore = usdtToken.balanceOf(admin);
        uint256 stakingBalanceBefore = usdtToken.balanceOf(address(staking));

        {
            vm.startPrank(admin);
            usdtToken.approve(address(staking), DISTRIBUTION_AMOUNT);
            staking.createDistribution(usdtToken, DISTRIBUTION_AMOUNT);

            assertDistributionCreated(adminBalanceBefore, stakingBalanceBefore);

            staking.distributeRewards(
                usdtToken,
                TWO_MINIMAL_STAKERS,
                MINIMAL_REWARDS_2
            );

            assertRewardsDistributed(TWO_MINIMAL_STAKERS, MINIMAL_REWARDS_2);
            vm.stopPrank();

            vm.prank(alice);
            staking.unstake(firstBandId);

            vm.prank(bob);
            staking.unstake(secondBandId);
        }

        (uint256 aliceClaimedRewards, uint256 aliceUnclaimedRewards) = staking
            .getStakerReward(alice, usdtToken);
        (uint256 bobClaimedRewards, uint256 bobUnclaimedRewards) = staking
            .getStakerReward(bob, usdtToken);
        balances.alicePostUnstakingBalance = wowToken.balanceOf(alice);
        balances.bobPostUnstakingBalance = wowToken.balanceOf(bob);
        balances.stakingPostUnstakingBalance = wowToken.balanceOf(
            address(staking)
        );

        {
            assertBalances(
                balances.stakingBalanceBefore,
                balances.stakingPostUnstakingBalance,
                balances.bobPreStakingBalance,
                balances.bobPostUnstakingBalance,
                balances.alicePreStakingBalance,
                balances.alicePostUnstakingBalance
            );
            assertUnstaked(firstBandId);
            assertUnstaked(secondBandId);
            assertRewardData(alice, aliceClaimedRewards, aliceUnclaimedRewards);
            assertRewardData(bob, bobClaimedRewards, bobUnclaimedRewards);
            assertStakerBandIds(alice, EMPTY_STAKER_BAND_IDS);
            assertStakerBandIds(bob, EMPTY_STAKER_BAND_IDS);
            assertStateVariables(staking.getNextBandId(), false);
        }
    }
}
