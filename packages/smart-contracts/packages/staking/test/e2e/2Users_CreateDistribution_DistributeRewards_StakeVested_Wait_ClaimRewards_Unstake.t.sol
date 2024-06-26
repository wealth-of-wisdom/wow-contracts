// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {StakingAssertions} from "./StakingAssertions.t.sol";

struct Balances {
    uint256 alicePreStakingBalance;
    uint256 alicePostClaimingBalance;
    uint256 bobPreStakingBalance;
    uint256 bobPostUnstakingBalance;
    uint256 stakingBalanceBefore;
    uint256 stakingPreClaimingBalance;
    uint256 stakingPostClaimingBalance;
    uint256 adminBalanceBefore;
}

contract Staking_E2E_Test is StakingAssertions {
    function test_With2Users_CreateDistribution_DistributeRewards_StakeVested_Wait_ClaimRewards_Unstake()
        external
        setBandLevelData
    {
        /**
         * 1. Alice stakes to level 2 band
         * 2. Bob stakes to level 4 band
         * 3. Both users wait
         * 4. Distribution created
         * 5. Distribute rewards
         * 6. Both users wait
         * 7. Both users claims rewards
         * 8. Bob unstakes
         */
        // ARRANGE + ACT
        Balances memory balances;

        balances.alicePreStakingBalance = wowToken.balanceOf(alice);
        balances.bobPreStakingBalance = wowToken.balanceOf(bob);
        uint256 firstBandId = staking.getNextBandId();

        vm.startPrank(admin);
        staking.setSharesInMonth(SHARES_IN_MONTH);

        {
            vm.startPrank(alice);
            wowToken.approve(address(staking), BAND_2_PRICE);
            staking.stake(STAKING_TYPE_FIX, BAND_LEVEL_2, MONTH_1);
            vm.stopPrank();
        }

        uint256 secondBandId = staking.getNextBandId();

        {
            vm.startPrank(bob);
            wowToken.approve(address(staking), BAND_4_PRICE);
            staking.stake(STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1);
            vm.stopPrank();

            assertStaked(alice, firstBandId, BAND_LEVEL_2, 1);
            assertStaked(bob, secondBandId, BAND_LEVEL_4, 1);

            skip(MONTH);
        }

        {
            balances.adminBalanceBefore = usdtToken.balanceOf(admin);
            balances.stakingBalanceBefore = usdtToken.balanceOf(
                address(staking)
            );

            vm.startPrank(admin);
            usdtToken.approve(address(staking), DISTRIBUTION_AMOUNT);
            staking.createDistribution(usdtToken, DISTRIBUTION_AMOUNT);

            assertDistributionCreated(
                balances.adminBalanceBefore,
                balances.stakingBalanceBefore
            );

            staking.distributeRewards(
                usdtToken,
                TWO_MINIMAL_STAKERS,
                MINIMAL_REWARDS_2
            );

            assertRewardsDistributed(TWO_MINIMAL_STAKERS, MINIMAL_REWARDS_2);
            vm.stopPrank();

            skip(MONTH * MONTH_2);
        }

        {
            vm.prank(alice);
            staking.claimRewards(usdtToken);
            vm.prank(bob);
            staking.claimRewards(usdtToken);

            assertRewardsClaimed(alice);
            assertRewardsClaimed(bob);

            vm.prank(bob);
            staking.unstake(secondBandId);
        }

        (uint256 aliceClaimedRewards, uint256 aliceUnclaimedRewards) = staking
            .getStakerReward(alice, usdtToken);
        (uint256 bobClaimedRewards, uint256 bobUnclaimedRewards) = staking
            .getStakerReward(bob, usdtToken);
        balances.alicePostClaimingBalance =
            wowToken.balanceOf(alice) +
            BAND_2_PRICE;
        balances.bobPostUnstakingBalance = wowToken.balanceOf(bob);
        balances.stakingPreClaimingBalance = BAND_2_PRICE;
        balances.stakingPostClaimingBalance = wowToken.balanceOf(
            address(staking)
        );

        {
            assertBalances(
                balances.stakingPreClaimingBalance,
                balances.stakingPostClaimingBalance,
                balances.bobPreStakingBalance,
                balances.bobPostUnstakingBalance,
                balances.alicePreStakingBalance,
                balances.alicePostClaimingBalance
            );

            assertStaked(alice, firstBandId, BAND_LEVEL_2, 1);
            assertUnstaked(secondBandId);
            assertRewardData(alice, aliceClaimedRewards, aliceUnclaimedRewards);
            assertRewardData(bob, bobClaimedRewards, bobUnclaimedRewards);
            assertStakerBandIds(alice, ALICE_BAND_IDS);
            assertStakerBandIds(bob, EMPTY_STAKER_BAND_IDS);
            assertStateVariables(staking.getNextBandId(), false);
        }
    }
}
