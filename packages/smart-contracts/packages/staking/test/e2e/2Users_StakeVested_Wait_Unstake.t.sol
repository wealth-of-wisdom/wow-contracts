// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {StakingAssertions} from "./StakingAssertions.t.sol";

contract Staking_E2E_Test is StakingAssertions {
    function test_With2Users_StakeVested_Wait_Unstake()
        external
        setBandLevelData
    {
        /**
         * 1. Alice stakes to level 3 band
         * 2. Bob stakes to level 6 band
         * 3. Both users wait
         * 4. Alice unstakes
         * 5. Bob unstakes
         */

        // ARRANGE + ACT
        vm.startPrank(admin);
        staking.grantRole(VESTING_ROLE, alice);
        staking.grantRole(VESTING_ROLE, bob);
        vm.stopPrank();

        uint256 alicePreUnstakingBalance = wowToken.balanceOf(alice);
        uint256 bobPreUnstakingBalance = wowToken.balanceOf(bob);

        uint256 firstBandId = staking.getNextBandId();
        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_2_PRICE);
        staking.stakeVested(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_2, MONTH_0);
        vm.stopPrank();

        uint256 secondBandId = staking.getNextBandId();
        vm.startPrank(bob);
        wowToken.approve(address(staking), BAND_4_PRICE);
        staking.stakeVested(bob, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0);
        vm.stopPrank();

        vm.warp(MONTH);

        vm.prank(alice);
        staking.unstakeVested(alice, firstBandId);

        vm.prank(bob);
        staking.unstakeVested(bob, secondBandId);

        uint256 alicePostUnstakingBalance = wowToken.balanceOf(alice);
        uint256 bobPostUnstakingBalance = wowToken.balanceOf(bob);
        uint256 stakingPostUnstakingBalance = wowToken.balanceOf(
            address(staking)
        );

        // ASSERT
        assertBalances(
            stakingPostUnstakingBalance,
            0,
            bobPreUnstakingBalance,
            bobPostUnstakingBalance,
            alicePreUnstakingBalance,
            alicePostUnstakingBalance
        );

        assertUnstaked(firstBandId);
        assertUnstaked(secondBandId);
        assertStakerBandIds(alice, EMPTY_STAKER_BAND_IDS);
        assertStakerBandIds(bob, EMPTY_STAKER_BAND_IDS);
        assertStateVariables(staking.getNextBandId(), false);
    }
}
