// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import {VestingAssertions} from "./VestingAssertions.t.sol";
import {IVesting} from "../../contracts/interfaces/IVesting.sol";

contract Vesting_E2E_Test is VestingAssertions {
    function test_1User_2Pools_Create_Stake_Unstake_Remove() external {
        /**
         * 1. 2 Pools are added to vesting
         * 2. Alice added as beneficiary to primary pool
         * 3. Alice stakes vested tokens to primary pool
         * 4. Alice stakes vested tokens to secondary pool
         * 5. Alice waits
         * 6. Alice unstakes vested tokens from primary pool
         * 7. Alice unstakes vested tokens from secondary pool
         * 8. Alice is removed as beneficiary from primary pool
         */

        // ARRANGE + ACT
        Balances memory balances;
        PoolData memory poolData;

        vm.startPrank(admin);
        balances.vestingBalanceBefore = wowToken.balanceOf(address(vesting));
        balances.adminBalanceBefore = wowToken.balanceOf(admin);
        staking.setSharesInMonth(SHARES_IN_MONTH);

        {
            wowToken.approve(address(vesting), TOTAL_POOL_TOKEN_AMOUNT);
            vesting.addVestingPool(
                POOL_NAME,
                LISTING_PERCENTAGE_DIVIDEND,
                LISTING_PERCENTAGE_DIVISOR,
                CLIFF_IN_DAYS,
                CLIFF_PERCENTAGE_DIVIDEND,
                CLIFF_PERCENTAGE_DIVISOR,
                DURATION_3_MONTHS,
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
                vestingDurationInMonths: DURATION_3_MONTHS,
                unlockType: MONTHLY_UNLOCK_TYPE,
                totalPoolTokenAmount: TOTAL_POOL_TOKEN_AMOUNT,
                vestingBalanceBefore: balances.vestingBalanceBefore,
                adminBalanceBefore: balances.adminBalanceBefore
            });
            assertPoolData(poolData);
        }
        {
            balances.vestingBalanceBefore = wowToken.balanceOf(
                address(vesting)
            );
            balances.adminBalanceBefore = wowToken.balanceOf(admin);

            wowToken.approve(address(vesting), TOTAL_POOL_TOKEN_AMOUNT_2);
            vesting.addVestingPool(
                POOL_NAME_2,
                LISTING_PERCENTAGE_DIVIDEND_15,
                LISTING_PERCENTAGE_DIVISOR_40,
                CLIFF_IN_DAYS_2,
                CLIFF_PERCENTAGE_DIVIDEND_3,
                CLIFF_PERCENTAGE_DIVISOR_20,
                DURATION_5_MONTHS,
                MONTHLY_UNLOCK_TYPE,
                TOTAL_POOL_TOKEN_AMOUNT_2
            );
            poolData = PoolData({
                pid: SECONDARY_POOL,
                name: POOL_NAME_2,
                listingPercentageDividend: LISTING_PERCENTAGE_DIVIDEND_15,
                listingPercentageDivisor: LISTING_PERCENTAGE_DIVISOR_40,
                cliffInDays: CLIFF_IN_DAYS_2,
                cliffPercentageDividend: CLIFF_PERCENTAGE_DIVIDEND_3,
                cliffPercentageDivisor: CLIFF_PERCENTAGE_DIVISOR_20,
                vestingDurationInMonths: DURATION_5_MONTHS,
                unlockType: MONTHLY_UNLOCK_TYPE,
                totalPoolTokenAmount: TOTAL_POOL_TOKEN_AMOUNT_2,
                vestingBalanceBefore: balances.vestingBalanceBefore,
                adminBalanceBefore: balances.adminBalanceBefore
            });
            assertPoolData(poolData);

            vesting.addBeneficiary(PRIMARY_POOL, alice, BAND_1_PRICE);
            VestingAssertions.assertBeneficiaryData(
                PRIMARY_POOL,
                alice,
                0,
                0,
                BAND_1_PRICE,
                BAND_1_PRICE,
                LISTING_PERCENTAGE_DIVIDEND,
                LISTING_PERCENTAGE_DIVISOR,
                CLIFF_PERCENTAGE_DIVIDEND,
                CLIFF_PERCENTAGE_DIVISOR
            );
            vesting.addBeneficiary(SECONDARY_POOL, alice, BAND_2_PRICE);
            VestingAssertions.assertBeneficiaryData(
                SECONDARY_POOL,
                alice,
                0,
                0,
                BAND_2_PRICE,
                BAND_2_PRICE,
                LISTING_PERCENTAGE_DIVIDEND_15,
                LISTING_PERCENTAGE_DIVISOR_40,
                CLIFF_PERCENTAGE_DIVIDEND_3,
                CLIFF_PERCENTAGE_DIVISOR_20
            );
            vm.stopPrank();
        }
        {
            vm.startPrank(alice);
            vesting.stakeVestedTokens(
                STAKING_TYPE_FIX,
                BAND_LEVEL_1,
                MONTH_1,
                PRIMARY_POOL
            );
            assertStakerVestedData(PRIMARY_POOL, alice, BAND_1_PRICE);
            vesting.stakeVestedTokens(
                STAKING_TYPE_FIX,
                BAND_LEVEL_2,
                MONTH_1,
                SECONDARY_POOL
            );
            assertStakerVestedData(SECONDARY_POOL, alice, BAND_2_PRICE);

            vm.warp(MONTH * MONTH_2);
        }
        {
            vesting.unstakeVestedTokens(BAND_ID_0);
            assertStakerVestedData(PRIMARY_POOL, alice, 0);
            vesting.unstakeVestedTokens(BAND_ID_1);
            assertStakerVestedData(SECONDARY_POOL, alice, 0);

            vm.stopPrank();

            vm.prank(admin);
            vesting.removeBeneficiary(PRIMARY_POOL, alice);

            VestingAssertions.assertBeneficiaryData(
                PRIMARY_POOL,
                alice,
                0,
                0,
                0,
                0,
                LISTING_PERCENTAGE_DIVIDEND_15,
                LISTING_PERCENTAGE_DIVISOR_40,
                CLIFF_PERCENTAGE_DIVIDEND_3,
                CLIFF_PERCENTAGE_DIVISOR_20
            );
            VestingAssertions.assertBeneficiaryData(
                SECONDARY_POOL,
                alice,
                0,
                0,
                BAND_2_PRICE,
                BAND_2_PRICE,
                LISTING_PERCENTAGE_DIVIDEND_15,
                LISTING_PERCENTAGE_DIVISOR_40,
                CLIFF_PERCENTAGE_DIVIDEND_3,
                CLIFF_PERCENTAGE_DIVISOR_20
            );
        }
    }
}
