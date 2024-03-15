// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {StakingAssertions} from "./StakingAssertions.t.sol";

contract Staking_E2E_Test is StakingAssertions {
    function test_With2Users_CreateDistribution_DistributeRewards_StakeVested_Wait_ClaimRewards()
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
         */
        // ARRANGE + ACT

        uint256 alicePreStakingBalance = wowToken.balanceOf(alice);
        uint256 bobPreStakingBalance = wowToken.balanceOf(bob);

        uint256 firstBandId = staking.getNextBandId();
        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_2_PRICE);
        staking.stake(STAKING_TYPE_FLEXI, BAND_LEVEL_2, MONTH_0);
        vm.stopPrank();

        uint256 secondBandId = staking.getNextBandId();
        vm.startPrank(bob);
        wowToken.approve(address(staking), BAND_4_PRICE);
        staking.stake(STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0);
        vm.stopPrank();

        uint256 alicePostStakingBalance = wowToken.balanceOf(alice);
        uint256 bobPostStakingBalance = wowToken.balanceOf(bob);
        uint256 stakingPostStakingBalance = wowToken.balanceOf(
            address(staking)
        );

        vm.warp(MONTH);

        uint256 adminBalanceBefore = usdtToken.balanceOf(admin);
        uint256 stakingBalanceBefore = usdtToken.balanceOf(address(staking));

        vm.startPrank(admin);
        usdtToken.approve(address(staking), DISTRIBUTION_AMOUNT);
        staking.createDistribution(usdtToken, DISTRIBUTION_AMOUNT);

        assertDistributionCreated(adminBalanceBefore, stakingBalanceBefore);

        staking.distributeRewards(usdtToken, MINIMAL_STAKERS, MINIMAL_REWARDS);

        assertRewardsDistributed(MINIMAL_STAKERS, MINIMAL_REWARDS);
        vm.stopPrank();

        vm.warp(MONTH);

        vm.prank(alice);
        staking.claimRewards(usdtToken);
        vm.prank(bob);
        staking.claimRewards(usdtToken);

        assertRewardsClaimed(alice);
        assertRewardsClaimed(bob);

        (uint256 aliceClaimedRewards, uint256 aliceUnclaimedRewards) = staking
            .getStakerReward(alice, usdtToken);
        (uint256 bobClaimedRewards, uint256 bobUnclaimedRewards) = staking
            .getStakerReward(bob, usdtToken);

        uint256 alicePostClaimingBalance = wowToken.balanceOf(alice) +
            BAND_2_PRICE;
        uint256 bobPostClaimingBalance = wowToken.balanceOf(bob) + BAND_4_PRICE;
        uint256 stakingPreClaimingBalance = BAND_4_PRICE + BAND_2_PRICE;
        uint256 stakingPostClaimingBalance = wowToken.balanceOf(
            address(staking)
        );

        assertBalances(
            stakingPreClaimingBalance,
            stakingPostClaimingBalance,
            bobPreStakingBalance,
            bobPostClaimingBalance,
            alicePreStakingBalance,
            alicePostClaimingBalance
        );

        assertStaked(alice, firstBandId, BAND_LEVEL_2, 1);
        assertStaked(bob, secondBandId, BAND_LEVEL_4, 1);
        assertRewardData(alice, aliceClaimedRewards, aliceUnclaimedRewards);
        assertRewardData(bob, bobClaimedRewards, bobUnclaimedRewards);
        assertStakerBandIds(alice, ALICE_BAND_IDS);
        assertStakerBandIds(bob, BOB_BAND_IDS);
        assertStateVariables(staking.getNextBandId(), false);
    }
}
