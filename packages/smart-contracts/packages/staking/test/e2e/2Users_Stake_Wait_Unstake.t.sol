// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {StakingAssertions} from "./StakingAssertions.t.sol";

struct Balances {
    uint256 alicePreUnstakingBalance;
    uint256 alicePostUnstakingBalance;
    uint256 bobPreUnstakingBalance;
    uint256 bobPostUnstakingBalance;
    uint256 stakingPreUnstakingBalance;
    uint256 stakingPostUnstakingBalance;
}

contract Staking_E2E_Test is StakingAssertions {
    function test_With2Users_Stake_Wait_Unstake() external setBandLevelData {
        /**
         * 1. Alice stakes to level 3 band
         * 2. Bob stakes to level 6 band
         * 3. Both users wait
         * 4. Alice unstakes
         * 5. Bob unstakes
         */

        // ARRANGE + ACT
        Balances memory balances;

        balances.alicePreUnstakingBalance = wowToken.balanceOf(alice);
        balances.bobPreUnstakingBalance = wowToken.balanceOf(bob);
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

            skip(MONTH);

            vm.prank(alice);
            staking.unstake(firstBandId);

            vm.prank(bob);
            staking.unstake(secondBandId);
        }

        balances.alicePostUnstakingBalance = wowToken.balanceOf(alice);
        balances.bobPostUnstakingBalance = wowToken.balanceOf(bob);
        balances.stakingPostUnstakingBalance = wowToken.balanceOf(
            address(staking)
        );

        // ASSERT
        {
            assertBalances(
                balances.stakingPostUnstakingBalance,
                balances.stakingPreUnstakingBalance,
                balances.bobPreUnstakingBalance,
                balances.bobPostUnstakingBalance,
                balances.alicePreUnstakingBalance,
                balances.alicePostUnstakingBalance
            );

            assertUnstaked(firstBandId);
            assertUnstaked(secondBandId);
            assertStakerBandIds(alice, EMPTY_STAKER_BAND_IDS);
            assertStakerBandIds(bob, EMPTY_STAKER_BAND_IDS);
            assertStateVariables(staking.getNextBandId(), false);
        }
    }
}
