// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {StakingAssertions} from "./StakingAssertions.t.sol";

struct Balances {
    uint256 alicePreStakingBalance;
    uint256 alicePostStakingBalance;
    uint256 alicePostClaimingBalance;
    uint256 bobPreStakingBalance;
    uint256 bobPostStakingBalance;
    uint256 bobPostClaimingBalance;
    uint256 stakingBalanceBefore;
    uint256 stakingPreClaimingBalance;
    uint256 stakingPostClaimingBalance;
    uint256 stakingPostStakingBalance;
    uint256 adminBalanceBefore;
}

contract Staking_E2E_Test is StakingAssertions {
    function test_With2Users_CreateDistribution_DistributeRewards_StakeVested_Wait_UpgradeBand_Wait_ClaimRewards()
        external
        setBandLevelData
    {
        /**
         * 1. Alice stakes to level 2 band
         * 2. Bob stakes to level 4 band
         * 3. Distribution created
         * 4. Bob upgrades band to level 5
         * 5. Both users wait
         * 6. Distribute rewards
         * 7. Both users wait
         * 8. Both users claim rewards
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
        }

        balances.alicePostStakingBalance = wowToken.balanceOf(alice);
        balances.bobPostStakingBalance = wowToken.balanceOf(bob);
        balances.stakingPostStakingBalance = wowToken.balanceOf(
            address(staking)
        );

        {
            vm.prank(admin);
            staking.setBandUpgradesEnabled(true);

            skip(MONTH);

            vm.startPrank(bob);
            wowToken.approve(address(staking), BAND_5_PRICE - BAND_4_PRICE);
            staking.upgradeBand(secondBandId, BAND_LEVEL_5);
            vm.stopPrank();

            skip(MONTH);
        }

        balances.adminBalanceBefore = usdtToken.balanceOf(admin);
        balances.stakingBalanceBefore = usdtToken.balanceOf(address(staking));

        {
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

            vm.prank(alice);
            staking.claimRewards(usdtToken);
            vm.prank(bob);
            staking.claimRewards(usdtToken);

            assertRewardsClaimed(alice);
            assertRewardsClaimed(bob);
        }

        (uint256 aliceClaimedRewards, uint256 aliceUnclaimedRewards) = staking
            .getStakerReward(alice, usdtToken);
        (uint256 bobClaimedRewards, uint256 bobUnclaimedRewards) = staking
            .getStakerReward(bob, usdtToken);

        balances.alicePostClaimingBalance =
            wowToken.balanceOf(alice) +
            BAND_2_PRICE;
        balances.bobPostClaimingBalance =
            wowToken.balanceOf(bob) +
            BAND_5_PRICE;
        balances.stakingPreClaimingBalance = BAND_5_PRICE + BAND_2_PRICE;
        balances.stakingPostClaimingBalance = wowToken.balanceOf(
            address(staking)
        );

        assertBalances(
            balances.stakingPreClaimingBalance,
            balances.stakingPostClaimingBalance,
            balances.bobPreStakingBalance,
            balances.bobPostClaimingBalance,
            balances.alicePreStakingBalance,
            balances.alicePostClaimingBalance
        );
        assertStaked(alice, firstBandId, BAND_LEVEL_2, 1);
        assertStaked(bob, secondBandId, BAND_LEVEL_5, 1);
        assertRewardData(alice, aliceClaimedRewards, aliceUnclaimedRewards);
        assertRewardData(bob, bobClaimedRewards, bobUnclaimedRewards);
        assertStakerBandIds(alice, ALICE_BAND_IDS);
        assertStakerBandIds(bob, BOB_BAND_IDS);
        assertStateVariables(staking.getNextBandId(), true);
    }
}
