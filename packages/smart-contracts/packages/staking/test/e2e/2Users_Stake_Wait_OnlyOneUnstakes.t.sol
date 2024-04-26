// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {StakingAssertions} from "./StakingAssertions.t.sol";

struct Balances {
    uint256 alicePreStakingBalance;
    uint256 alicePostStakingBalance;
    uint256 bobPreUnstakingBalance;
    uint256 bobPostUnstakingBalance;
    uint256 stakingPreUnstakingBalance;
    uint256 stakingPostUnstakingBalance;
}

contract Staking_E2E_Test is StakingAssertions {
    function test_With2Users_Stake_Wait_OnlyOneUnstakes()
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
        Balances memory balances;

        balances.alicePreStakingBalance = wowToken.balanceOf(alice);
        balances.bobPreUnstakingBalance = wowToken.balanceOf(bob);
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

            skip(MONTH);

            vm.prank(bob);
            staking.unstake(secondBandId);
        }

        balances.alicePostStakingBalance =
            wowToken.balanceOf(alice) +
            BAND_2_PRICE;
        balances.bobPostUnstakingBalance = wowToken.balanceOf(bob);
        balances.stakingPreUnstakingBalance = BAND_2_PRICE;
        balances.stakingPostUnstakingBalance = wowToken.balanceOf(
            address(staking)
        );

        // ASSERT
        {
            assertBalances(
                balances.stakingPreUnstakingBalance,
                balances.stakingPostUnstakingBalance,
                balances.bobPreUnstakingBalance,
                balances.bobPostUnstakingBalance,
                balances.alicePreStakingBalance,
                balances.alicePostStakingBalance
            );

            assertStaked(alice, firstBandId, BAND_LEVEL_2, 1);
            assertUnstaked(secondBandId);
            assertStakerBandIds(alice, ALICE_BAND_IDS);
            assertStakerBandIds(bob, EMPTY_STAKER_BAND_IDS);
            assertStateVariables(staking.getNextBandId(), false);
        }
    }
}
