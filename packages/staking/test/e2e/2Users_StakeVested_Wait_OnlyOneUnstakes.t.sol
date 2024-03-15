// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {StakingAssertions} from "./StakingAssertions.t.sol";

contract Staking_E2E_Test is StakingAssertions {
    function test_With2Users_StakeVested_Wait_OnlyOneUnstakes()
        external
        setBandLevelData
    {
        /**
         * 1. Alice stakes to level 3 band
         * 2. Bob stakes to level 6 band
         * 3. Both users wait
         * 4. Bob unstakes
         */

        // ARRANGE + ACT
        vm.startPrank(admin);
        staking.grantRole(VESTING_ROLE, alice);
        staking.grantRole(VESTING_ROLE, bob);
        vm.stopPrank();
        uint256 alicePreStakingBalance = wowToken.balanceOf(alice);
        uint256 bobPreUnstakingBalance = wowToken.balanceOf(bob);

        uint256 firstBandId = staking.getNextBandId();
        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_3_PRICE);
        staking.stakeVested(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_3, MONTH_0);
        vm.stopPrank();

        uint256 secondBandId = staking.getNextBandId();
        vm.startPrank(bob);
        wowToken.approve(address(staking), BAND_6_PRICE);
        staking.stakeVested(bob, STAKING_TYPE_FLEXI, BAND_LEVEL_6, MONTH_0);
        vm.stopPrank();

        vm.warp(MONTH);

        vm.prank(bob);
        staking.unstakeVested(bob, secondBandId);

        uint256 alicePostStakingBalance = wowToken.balanceOf(alice);
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
            alicePreStakingBalance,
            alicePostStakingBalance
        );

        assertStaked(alice, firstBandId, BAND_LEVEL_3, 1);
        assertUnstaked(secondBandId);
        assertStakerBandIds(alice, ALICE_BAND_IDS);
        assertStakerBandIds(bob, EMPTY_STAKER_BAND_IDS);
        assertStateVariables(staking.getNextBandId(), false);
    }
}
