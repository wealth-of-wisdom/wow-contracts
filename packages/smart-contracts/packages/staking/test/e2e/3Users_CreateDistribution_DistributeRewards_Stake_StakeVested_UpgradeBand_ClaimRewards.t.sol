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

struct BandIds {
    uint256 firstBandId;
    uint256 secondBandId;
    uint256 thirdBandId;
    uint256 fourthBandId;
    uint256 fifthBandId;
}

contract Staking_E2E_Test is StakingAssertions {
    function test_With3Users_CreateDistribution_DistributeRewards_Stake_StakeVested_UpgradeBand_ClaimRewards()
        external
        setBandLevelData
    {
        /**
         * 1. Alice vested stakes to level 2 band
         * 2. Bob stakes to level 1 band
         * 2. Carol vested stakes to level 1 band
         * 3. All users wait
         * 4. Distribution created
         * 5. Distribute rewards
         * 6. Bob claims rewards
         * 7. Bob upgrades band  - removed due to FIX type
         * 8. Carol stakes to level 3 band
         * 9. Carol claims rewards
         * 10. Distribution created
         * 11. Distribute rewards
         * 12. Alice vested stakes to level 2 band
         * 13. Bob claims rewards
         * 14. All users wait
         * 15. Carol unstakes vested band
         * 16. Distribution created
         * 17. Distribute rewards
         * 18. Alice claims rewards
         * 19. Bob downgrades band  - removed due to FIX type
         */
        // ARRANGE + ACT
        Balances memory balances;
        BandIds memory bandIds;

        balances.alicePreStakingBalance = wowToken.balanceOf(alice);
        balances.bobPreStakingBalance = wowToken.balanceOf(bob);
        balances.carolPreStakingBalance = wowToken.balanceOf(carol);
        bandIds.firstBandId = staking.getNextBandId();

        vm.startPrank(admin);
        staking.setSharesInMonth(SHARES_IN_MONTH);

        {
            vm.startPrank(admin);
            staking.grantRole(VESTING_ROLE, alice);
            staking.grantRole(VESTING_ROLE, bob);
            staking.grantRole(VESTING_ROLE, carol);
            vm.stopPrank();
        }
        {
            vm.startPrank(alice);
            wowToken.approve(address(staking), BAND_2_PRICE);
            staking.stakeVested(alice, STAKING_TYPE_FIX, BAND_LEVEL_2, MONTH_1);
            vm.stopPrank();
        }

        bandIds.secondBandId = staking.getNextBandId();

        {
            vm.startPrank(bob);
            wowToken.approve(address(staking), BAND_1_PRICE);
            staking.stake(STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_1);
            vm.stopPrank();

            assertStaked(alice, bandIds.firstBandId, BAND_LEVEL_2, 1);
            assertStaked(bob, bandIds.secondBandId, BAND_LEVEL_1, 1);
        }

        bandIds.thirdBandId = staking.getNextBandId();

        {
            vm.startPrank(carol);
            wowToken.approve(address(staking), BAND_1_PRICE);
            staking.stakeVested(carol, STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_1);
            vm.stopPrank();

            assertStaked(alice, bandIds.firstBandId, BAND_LEVEL_2, 1);
            assertStaked(bob, bandIds.secondBandId, BAND_LEVEL_1, 1);
            assertStaked(carol, bandIds.thirdBandId, BAND_LEVEL_1, 1);

            skip(MONTH);
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

            skip(MONTH);
        }
        {
            vm.startPrank(bob);
            staking.claimRewards(usdtToken);
            assertRewardsClaimed(bob);

            // wowToken.approve(address(staking), BAND_2_PRICE);
            // staking.upgradeBand(bandIds.secondBandId, BAND_LEVEL_2);
            vm.stopPrank();
        }

        bandIds.fourthBandId = staking.getNextBandId();

        {
            vm.startPrank(carol);
            wowToken.approve(address(staking), BAND_3_PRICE);
            staking.stake(STAKING_TYPE_FIX, BAND_LEVEL_3, MONTH_1);

            assertStaked(
                carol,
                bandIds.fourthBandId,
                BAND_LEVEL_3,
                block.timestamp
            );

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

        bandIds.fifthBandId = staking.getNextBandId();

        {
            ALICE_BAND_IDS = [bandIds.firstBandId, staking.getNextBandId()];
            vm.startPrank(alice);
            wowToken.approve(address(staking), BAND_2_PRICE);
            staking.stakeVested(alice, STAKING_TYPE_FIX, BAND_LEVEL_2, MONTH_1);

            assertStaked(
                alice,
                staking.getNextBandId() - 1,
                BAND_LEVEL_2,
                block.timestamp
            );
            vm.stopPrank();

            vm.prank(bob);
            staking.claimRewards(usdtToken);
            assertRewardsClaimed(bob);

            skip(MONTH);

            vm.prank(carol);
            staking.unstake(bandIds.fourthBandId);
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
            vm.startPrank(alice);
            staking.claimRewards(usdtToken);
            assertRewardsClaimed(alice);

            vm.startPrank(bob);

            // wowToken.approve(address(staking), BAND_1_PRICE);
            // staking.downgradeBand(bandIds.secondBandId, BAND_LEVEL_1);

            vm.stopPrank();
        }

        (uint256 aliceClaimedRewards, uint256 aliceUnclaimedRewards) = staking
            .getStakerReward(alice, usdtToken);
        (uint256 bobClaimedRewards, uint256 bobUnclaimedRewards) = staking
            .getStakerReward(bob, usdtToken);
        (uint256 carolClaimedRewards, uint256 carolUnclaimedRewards) = staking
            .getStakerReward(carol, usdtToken);
        balances.alicePostUnstakingBalance = wowToken.balanceOf(alice);
        balances.bobPostUnstakingBalance =
            wowToken.balanceOf(bob) +
            BAND_1_PRICE;
        balances.carolPostClaimingBalance = wowToken.balanceOf(carol);
        balances.stakingPreClaimingBalance = BAND_1_PRICE;
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

            assertRewardData(alice, aliceClaimedRewards, aliceUnclaimedRewards);
            assertRewardData(bob, bobClaimedRewards, bobUnclaimedRewards);
            assertRewardData(carol, carolClaimedRewards, carolUnclaimedRewards);
            assertStakerBandIds(alice, ALICE_BAND_IDS);
            assertStakerBandIds(bob, BOB_BAND_IDS);
            assertStakerBandIds(carol, CAROL_BAND_IDS);
            assertStateVariables(staking.getNextBandId(), true);
        }
    }
}
