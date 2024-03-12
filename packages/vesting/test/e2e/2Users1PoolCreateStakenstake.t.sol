// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import {VestingAssertions} from "./VestingAssertions.t.sol";

contract Vesting_E2E_Test is VestingAssertions {
    function test_2Users_1Pool_Create_Stake_Unstake() external {
        /**
         * 1. Add pool to vesting
         * 2. Alice added as beneficiary
         * 3. Bob added as beneficiary
         * 4. Alice stakes vested tokens
         * 5. Bob stakes vested tokens
         * 6. Time passes
         * 7. Alice unstakes vested tokens
         * 8. Bob unstakes vested tokens
         */

        // ARRANGE + ACT
        vm.startPrank(admin);
        uint256 vestingBalanceBefore = wowToken.balanceOf(address(vesting));
        uint256 adminBalanceBefore = wowToken.balanceOf(admin);

        wowToken.approve(address(vesting), TOTAL_POOL_TOKEN_AMOUNT);
        vesting.addVestingPool(
            POOL_NAME,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_IN_DAYS,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR,
            VESTING_DURATION_IN_MONTHS,
            MONTHLY_UNLOCK_TYPE,
            TOTAL_POOL_TOKEN_AMOUNT
        );
        assertPoolData(
            PRIMARY_POOL,
            POOL_NAME,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_IN_DAYS,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR,
            VESTING_DURATION_IN_MONTHS,
            MONTHLY_UNLOCK_TYPE,
            TOTAL_POOL_TOKEN_AMOUNT,
            vestingBalanceBefore,
            adminBalanceBefore
        );

        vesting.addBeneficiary(PRIMARY_POOL, alice, BAND_2_PRICE);
        VestingAssertions.assertBeneficiaryData(
            PRIMARY_POOL,
            alice,
            0,
            0,
            BAND_2_PRICE,
            BAND_2_PRICE,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR
        );

        uint256 totalLockedTokens = BAND_2_PRICE + BAND_3_PRICE;

        vesting.addBeneficiary(PRIMARY_POOL, bob, BAND_3_PRICE);
        VestingAssertions.assertBeneficiaryData(
            PRIMARY_POOL,
            bob,
            0,
            0,
            BAND_3_PRICE,
            totalLockedTokens,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR
        );
        vm.stopPrank();

        vm.startPrank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FLEXI,
            BAND_LEVEL_2,
            MONTH_0,
            PRIMARY_POOL
        );
        assertStakerVestedData(PRIMARY_POOL, alice, BAND_2_PRICE);
        vm.stopPrank();

        vm.startPrank(bob);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FLEXI,
            BAND_LEVEL_3,
            MONTH_0,
            PRIMARY_POOL
        );
        assertStakerVestedData(PRIMARY_POOL, bob, BAND_3_PRICE);
        vm.stopPrank();

        vm.warp(MONTH_1);

        vm.prank(alice);
        vesting.unstakeVestedTokens(BAND_ID_0);
        assertStakerVestedData(PRIMARY_POOL, alice, 0);

        vm.prank(bob);
        vesting.unstakeVestedTokens(BAND_ID_1);
        assertStakerVestedData(PRIMARY_POOL, bob, 0);

        VestingAssertions.assertBeneficiaryData(
            PRIMARY_POOL,
            alice,
            0,
            0,
            BAND_2_PRICE,
            totalLockedTokens,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR
        );
        VestingAssertions.assertBeneficiaryData(
            PRIMARY_POOL,
            bob,
            0,
            0,
            BAND_3_PRICE,
            totalLockedTokens,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR
        );
    }
}
