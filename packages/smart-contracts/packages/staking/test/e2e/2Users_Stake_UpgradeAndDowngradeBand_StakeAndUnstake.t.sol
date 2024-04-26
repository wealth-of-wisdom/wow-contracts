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
    function test_With2Users_Stake_UpgradeAndDowngradeBand_StakeAndUnstake()
        external
        setBandLevelData
    {
        /**
         * 1. Alice stakes to level 3 band
         * 2. Bob stakes to level 4 band
         * 3. Alice upgrades band - removed due to FIX type
         * 4. Bob downgrades band - removed due to FIX type
         * 5. Alice unstakes
         */

        // ARRANGE + ACT
        Balances memory balances;

        {
            vm.prank(admin);
            staking.setBandUpgradesEnabled(true);
        }

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

            // vm.startPrank(alice);
            // wowToken.approve(address(staking), BAND_6_PRICE - BAND_2_PRICE);
            // staking.upgradeBand(firstBandId, BAND_LEVEL_6);
            // vm.stopPrank();

            // vm.prank(bob);
            // staking.downgradeBand(secondBandId, BAND_LEVEL_1);

            vm.warp(MONTH * MONTH_2);

            vm.prank(alice);
            staking.unstake(firstBandId);
        }

        balances.alicePostStakingBalance = wowToken.balanceOf(alice);
        balances.bobPostUnstakingBalance =
            wowToken.balanceOf(bob) +
            BAND_4_PRICE;
        balances.stakingPreUnstakingBalance = BAND_4_PRICE;
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

            assertUnstaked(firstBandId);
            assertStaked(bob, secondBandId, BAND_LEVEL_4, 1);
            assertStakerBandIds(alice, EMPTY_STAKER_BAND_IDS);
            assertStakerBandIds(bob, BOB_BAND_IDS);
            assertStateVariables(staking.getNextBandId(), true);
        }
    }
}
