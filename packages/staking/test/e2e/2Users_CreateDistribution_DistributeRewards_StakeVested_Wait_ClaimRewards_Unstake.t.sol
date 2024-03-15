// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {StakingAssertions} from "./StakingAssertions.t.sol";

contract Staking_E2E_Test is StakingAssertions {
    function test_With2Users_CreateDistribution_DistributeRewards_StakeVested_Wait_ClaimRewards_Unstake()
        external
        setBandLevelData
    {
        /**
         * 1. Alice stakes to level 2 band
         * 2. Bob stakes to level 4 band
         * 3. Distribution created
         * 4. Distribute rewards
         * 5. Both users wait
         * 6. Both users claims rewards
         * 7. Bob unstakes
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

        assertStaked(alice, firstBandId, BAND_LEVEL_2, 1);
        assertStaked(bob, secondBandId, BAND_LEVEL_4, 1);

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

        vm.prank(bob);
        staking.unstake(secondBandId);

        (uint256 aliceClaimedRewards, uint256 aliceUnclaimedRewards) = staking
            .getStakerReward(alice, usdtToken);
        (uint256 bobClaimedRewards, uint256 bobUnclaimedRewards) = staking
            .getStakerReward(bob, usdtToken);
        uint256 alicePostClaimingBalance = wowToken.balanceOf(alice) +
            BAND_2_PRICE -
            aliceClaimedRewards;
        uint256 bobPostUnstakingBalance = wowToken.balanceOf(bob);
        uint256 stakingPreClaimingBalance = BAND_2_PRICE -
            aliceClaimedRewards -
            bobClaimedRewards;
        uint256 stakingPostClaimingBalance = wowToken.balanceOf(
            address(staking)
        );

        assertBalances(
            stakingPreClaimingBalance,
            stakingPostClaimingBalance,
            bobPreStakingBalance,
            bobPostUnstakingBalance,
            alicePreStakingBalance,
            alicePostClaimingBalance
        );

        assertStaked(alice, firstBandId, BAND_LEVEL_2, 1);
        assertUnstaked(secondBandId);
        assertRewardData(alice, aliceClaimedRewards, aliceUnclaimedRewards);
        assertRewardData(bob, bobClaimedRewards, bobUnclaimedRewards);
    }
}
