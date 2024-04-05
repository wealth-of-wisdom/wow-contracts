// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {StakingAssertions} from "./StakingAssertions.t.sol";

struct Balances {
    uint256 alicePreStakingBalance;
    uint256 alicePostUnstakingBalance;
    uint256 bobPreStakingBalance;
    uint256 bobPostUnstakingBalance;
    uint256 carolPreStakingBalance;
    uint256 carolPostClaimingBalance;
    uint256 stakingBalanceBefore;
    uint256 stakingPreClaimingBalance;
    uint256 stakingPostClaimingBalance;
    uint256 adminBalanceBefore;
}

contract Staking_E2E_Test is StakingAssertions {
    function test_With3Users_CreateDistribution_DistributeRewards_Stake_UpgradeAndDowngradeBand_ClaimRewards()
        external
        setBandLevelData
    {
        /**
         * 1. Alice stakes to level 2 band
         * 2. Bob stakes to level 3 band
         * 2. Carol stakes to level 1 band
         * 3. All users wait
         * 4. Distribution created
         * 5. Distribute rewards
         * 6. Bob claims rewards
         * 7. Bob upgrades band
         * 8. Carol downgrades band
         * 9. Carol claims rewards
         * 10. Distribution created
         * 11. Distribute rewards
         * 12. Alice claims rewards
         * 13. Bob claims rewards
         * 14. All users wait
         * 15. Carol unstakes
         * 16. Distribution created
         * 17. Distribute rewards
         * 18. Alice claims rewards
         * 19. Bob downgrades band
         */
        // ARRANGE + ACT
        Balances memory balances;

        balances.alicePreStakingBalance = wowToken.balanceOf(alice);
        balances.bobPreStakingBalance = wowToken.balanceOf(bob);
        balances.carolPreStakingBalance = wowToken.balanceOf(carol);
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
            wowToken.approve(address(staking), BAND_3_PRICE);
            staking.stake(STAKING_TYPE_FLEXI, BAND_LEVEL_3, MONTH_0);
            vm.stopPrank();

            assertStaked(alice, firstBandId, BAND_LEVEL_2, 1);
            assertStaked(bob, secondBandId, BAND_LEVEL_3, 1);
        }

        uint256 thirdBandId = staking.getNextBandId();

        {
            vm.startPrank(carol);
            wowToken.approve(address(staking), BAND_1_PRICE);
            staking.stake(STAKING_TYPE_FLEXI, BAND_LEVEL_1, MONTH_0);
            vm.stopPrank();

            assertStaked(alice, firstBandId, BAND_LEVEL_2, 1);
            assertStaked(bob, secondBandId, BAND_LEVEL_3, 1);
            assertStaked(carol, thirdBandId, BAND_LEVEL_1, 1);

            vm.warp(MONTH);
        }

        {
            vm.prank(admin);
            staking.setBandUpgradesEnabled(true);
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
                THREE_MINIMAL_STAKERS,
                MINIMAL_REWARDS_3
            );

            assertRewardsDistributed(THREE_MINIMAL_STAKERS, MINIMAL_REWARDS_3);
            vm.stopPrank();

            vm.warp(MONTH);
        }
        {
            vm.startPrank(bob);
            staking.claimRewards(usdtToken);
            assertRewardsClaimed(bob);

            wowToken.approve(address(staking), BAND_2_PRICE);
            staking.downgradeBand(secondBandId, BAND_LEVEL_2);
            vm.stopPrank();
        }
        {
            vm.startPrank(carol);

            wowToken.approve(address(staking), BAND_2_PRICE);
            staking.upgradeBand(thirdBandId, BAND_LEVEL_2);

            staking.claimRewards(usdtToken);
            assertRewardsClaimed(carol);

            vm.stopPrank();
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
                THREE_MINIMAL_STAKERS,
                MINIMAL_REWARDS_3
            );
            //Update rewards for users that didn't claim
            MINIMAL_REWARDS_3[0] = MINIMAL_REWARDS_3[0] * 2;

            assertRewardsDistributed(THREE_MINIMAL_STAKERS, MINIMAL_REWARDS_3);
            vm.stopPrank();
        }
        {
            vm.prank(alice);
            staking.claimRewards(usdtToken);
            assertRewardsClaimed(alice);

            vm.prank(bob);
            staking.claimRewards(usdtToken);
            assertRewardsClaimed(bob);

            vm.warp(MONTH);

            vm.prank(carol);
            staking.unstake(thirdBandId);
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
                THREE_MINIMAL_STAKERS,
                MINIMAL_REWARDS_3
            );

            assertRewardsDistributed(THREE_MINIMAL_STAKERS, MINIMAL_REWARDS_3);
            vm.stopPrank();
        }
        {
            vm.startPrank(alice);
            staking.claimRewards(usdtToken);
            assertRewardsClaimed(alice);

            vm.startPrank(bob);

            wowToken.approve(address(staking), BAND_1_PRICE);
            staking.downgradeBand(secondBandId, BAND_LEVEL_1);

            vm.stopPrank();
        }

        (uint256 aliceClaimedRewards, uint256 aliceUnclaimedRewards) = staking
            .getStakerReward(alice, usdtToken);
        (uint256 bobClaimedRewards, uint256 bobUnclaimedRewards) = staking
            .getStakerReward(bob, usdtToken);
        (uint256 carolClaimedRewards, uint256 carolUnclaimedRewards) = staking
            .getStakerReward(carol, usdtToken);
        balances.alicePostUnstakingBalance =
            wowToken.balanceOf(alice) +
            BAND_2_PRICE;
        balances.bobPostUnstakingBalance =
            wowToken.balanceOf(bob) +
            BAND_1_PRICE;
        balances.carolPostClaimingBalance = wowToken.balanceOf(carol);
        balances.stakingPreClaimingBalance = BAND_2_PRICE + BAND_1_PRICE;
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
                balances.alicePostUnstakingBalance
            );

            assertOtherUserBalance(
                balances.carolPreStakingBalance,
                balances.carolPostClaimingBalance
            );

            assertStaked(alice, firstBandId, BAND_LEVEL_2, 1);
            assertStaked(bob, secondBandId, BAND_LEVEL_1, 1);
            assertUnstaked(thirdBandId);
            assertRewardData(alice, aliceClaimedRewards, aliceUnclaimedRewards);
            assertRewardData(bob, bobClaimedRewards, bobUnclaimedRewards);
            assertRewardData(carol, carolClaimedRewards, carolUnclaimedRewards);
            assertStakerBandIds(alice, ALICE_BAND_IDS);
            assertStakerBandIds(bob, BOB_BAND_IDS);
            assertStakerBandIds(carol, EMPTY_STAKER_BAND_IDS);
            assertStateVariables(staking.getNextBandId(), true);
        }
    }
}
