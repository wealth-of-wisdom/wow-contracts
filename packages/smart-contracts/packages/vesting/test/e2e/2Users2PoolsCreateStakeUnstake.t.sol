// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import {VestingAssertions} from "./VestingAssertions.t.sol";
import {IVesting} from "../../contracts/interfaces/IVesting.sol";

contract Vesting_E2E_Test is VestingAssertions {
    function test_2Users_2Pools_Create_Stake_Unstake() external {
        /**
         * 1. 2 Pools are added to vesting
         * 2. Alice added as beneficiary to primary pool
         * 3. Bob added as beneficiary to secondary pool
         * 4. Alice stakes vested tokens
         * 5. Bob stakes vested tokens
         * 6. Time passes
         * 7. Alice unstakes vested tokens
         * 8. Bob unstakes vested tokens
         */

        // ARRANGE + ACT
        Balances memory balances;
        PoolData memory poolData;

        vm.startPrank(admin);
        balances.vestingBalanceBefore = wowToken.balanceOf(address(vesting));
        balances.adminBalanceBefore = wowToken.balanceOf(admin);

        {
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

            poolData = PoolData({
                pid: PRIMARY_POOL,
                name: POOL_NAME,
                listingPercentageDividend: LISTING_PERCENTAGE_DIVIDEND,
                listingPercentageDivisor: LISTING_PERCENTAGE_DIVISOR,
                cliffInDays: CLIFF_IN_DAYS,
                cliffPercentageDividend: CLIFF_PERCENTAGE_DIVIDEND,
                cliffPercentageDivisor: CLIFF_PERCENTAGE_DIVISOR,
                vestingDurationInMonths: VESTING_DURATION_IN_MONTHS,
                unlockType: MONTHLY_UNLOCK_TYPE,
                totalPoolTokenAmount: TOTAL_POOL_TOKEN_AMOUNT,
                vestingBalanceBefore: balances.vestingBalanceBefore,
                adminBalanceBefore: balances.adminBalanceBefore
            });
            assertPoolData(poolData);
        }

        balances.vestingBalanceBefore = wowToken.balanceOf(address(vesting));
        balances.adminBalanceBefore = wowToken.balanceOf(admin);

        {
            wowToken.approve(address(vesting), TOTAL_POOL_TOKEN_AMOUNT_2);
            vesting.addVestingPool(
                POOL_NAME_2,
                LISTING_PERCENTAGE_DIVIDEND_2,
                LISTING_PERCENTAGE_DIVISOR_2,
                CLIFF_IN_DAYS_2,
                CLIFF_PERCENTAGE_DIVIDEND_2,
                CLIFF_PERCENTAGE_DIVISOR_2,
                VESTING_DURATION_IN_MONTHS_2,
                MONTHLY_UNLOCK_TYPE,
                TOTAL_POOL_TOKEN_AMOUNT_2
            );

            poolData = PoolData({
                pid: SECONDARY_POOL,
                name: POOL_NAME_2,
                listingPercentageDividend: LISTING_PERCENTAGE_DIVIDEND_2,
                listingPercentageDivisor: LISTING_PERCENTAGE_DIVISOR_2,
                cliffInDays: CLIFF_IN_DAYS_2,
                cliffPercentageDividend: CLIFF_PERCENTAGE_DIVIDEND_2,
                cliffPercentageDivisor: CLIFF_PERCENTAGE_DIVISOR_2,
                vestingDurationInMonths: VESTING_DURATION_IN_MONTHS_2,
                unlockType: MONTHLY_UNLOCK_TYPE,
                totalPoolTokenAmount: TOTAL_POOL_TOKEN_AMOUNT_2,
                vestingBalanceBefore: balances.vestingBalanceBefore,
                adminBalanceBefore: balances.adminBalanceBefore
            });
            assertPoolData(poolData);

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
            vesting.addBeneficiary(SECONDARY_POOL, bob, BAND_3_PRICE);
            VestingAssertions.assertBeneficiaryData(
                SECONDARY_POOL,
                bob,
                0,
                0,
                BAND_3_PRICE,
                BAND_3_PRICE,
                LISTING_PERCENTAGE_DIVIDEND_2,
                LISTING_PERCENTAGE_DIVISOR_2,
                CLIFF_PERCENTAGE_DIVIDEND_2,
                CLIFF_PERCENTAGE_DIVISOR_2
            );
            vm.stopPrank();
        }
        {
            vm.startPrank(alice);
            vesting.stakeVestedTokens(
                STAKING_TYPE_FLEXI,
                BAND_LEVEL_2,
                MONTH_0,
                PRIMARY_POOL
            );
            assertStakerVestedData(PRIMARY_POOL, alice, BAND_2_PRICE);
            vm.stopPrank();
        }
        {
            vm.startPrank(bob);
            vesting.stakeVestedTokens(
                STAKING_TYPE_FLEXI,
                BAND_LEVEL_3,
                MONTH_0,
                SECONDARY_POOL
            );
            assertStakerVestedData(SECONDARY_POOL, bob, BAND_3_PRICE);
            vm.stopPrank();
        }
        {
            vm.warp(MONTH_1);

            vm.prank(alice);
            vesting.unstakeVestedTokens(BAND_ID_0);
            assertStakerVestedData(PRIMARY_POOL, alice, 0);

            vm.prank(bob);
            vesting.unstakeVestedTokens(BAND_ID_1);
            assertStakerVestedData(SECONDARY_POOL, bob, 0);

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
            VestingAssertions.assertBeneficiaryData(
                SECONDARY_POOL,
                bob,
                0,
                0,
                BAND_3_PRICE,
                BAND_3_PRICE,
                LISTING_PERCENTAGE_DIVIDEND_2,
                LISTING_PERCENTAGE_DIVISOR_2,
                CLIFF_PERCENTAGE_DIVIDEND_2,
                CLIFF_PERCENTAGE_DIVISOR_2
            );
        }
    }
}
