// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import {VestingAssertions} from "./VestingAssertions.t.sol";
import {IVesting} from "../../contracts/interfaces/IVesting.sol";

contract Vesting_E2E_Test is VestingAssertions {
    function test_1User_1Pool_Create_Stake_Stake_Unstake() external {
        /**
         * 1. Pool added to vesting
         * 2. Alice added as beneficiary
         * 3. Alice stakes vested tokens
         * 4. Time passes
         * 5. Alice stakes vested tokens again
         * 6. Alice unstakes vested tokens
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

            vesting.addBeneficiary(PRIMARY_POOL, alice, BAND_6_PRICE);
            VestingAssertions.assertBeneficiaryData(
                PRIMARY_POOL,
                alice,
                0,
                0,
                BAND_6_PRICE,
                BAND_6_PRICE,
                LISTING_PERCENTAGE_DIVIDEND,
                LISTING_PERCENTAGE_DIVISOR,
                CLIFF_PERCENTAGE_DIVIDEND,
                CLIFF_PERCENTAGE_DIVISOR
            );
            vm.stopPrank();
        }
        {
            vm.startPrank(alice);
            vesting.stakeVestedTokens(
                STAKING_TYPE_FIX,
                BAND_LEVEL_2,
                MONTH_1,
                PRIMARY_POOL
            );
            assertStakerVestedData(PRIMARY_POOL, alice, BAND_2_PRICE);
            vm.stopPrank();

            vm.warp(MONTH_1);
        }

        uint256 totalStakedTokens = BAND_2_PRICE + BAND_3_PRICE;

        {
            vm.startPrank(alice);
            vesting.stakeVestedTokens(
                STAKING_TYPE_FIX,
                BAND_LEVEL_3,
                MONTH_1,
                PRIMARY_POOL
            );
            assertStakerVestedData(PRIMARY_POOL, alice, totalStakedTokens);
            vm.stopPrank();

            VestingAssertions.assertBeneficiaryData(
                PRIMARY_POOL,
                alice,
                totalStakedTokens,
                0,
                BAND_6_PRICE,
                BAND_6_PRICE,
                LISTING_PERCENTAGE_DIVIDEND,
                LISTING_PERCENTAGE_DIVISOR,
                CLIFF_PERCENTAGE_DIVIDEND,
                CLIFF_PERCENTAGE_DIVISOR
            );

            vm.warp(MONTH * MONTH_2);
            vm.prank(alice);
            vesting.unstakeVestedTokens(BAND_ID_0);
            assertStakerVestedData(PRIMARY_POOL, alice, BAND_3_PRICE);
        }
    }
}
