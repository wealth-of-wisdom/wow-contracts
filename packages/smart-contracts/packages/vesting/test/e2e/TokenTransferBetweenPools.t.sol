// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import {VestingAssertions} from "./VestingAssertions.t.sol";
import {IVesting} from "../../contracts/interfaces/IVesting.sol";

contract Vesting_E2E_Test is VestingAssertions {
    function test_TokenTransferBetweenPools() external {
        /**
         * 1. 2 Pools are added to vesting
         * 2. Alice added as beneficiary to primary pool
         * 3. Bob added as beneficiary to secondary pool
         * 4. Create 3 new pools (without beneficiaries) (treasury, team, advisors)
         * 5. Add beneficiary to a treasury pool
         * 6. Decrease tokens for team and advisors pools
         * 8. Creates pool treasury V2 with amount that were previously in 2 other pools.
         * 9. Updating any details for treasury pool reverts
         * 10. Updating any details for treasury pool V2 succeeds
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

        balances.vestingBalanceBefore = wowToken.balanceOf(address(vesting));
        balances.adminBalanceBefore = wowToken.balanceOf(admin);

        {
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
        }

        balances.vestingBalanceBefore = wowToken.balanceOf(address(vesting));
        balances.adminBalanceBefore = wowToken.balanceOf(admin);

        {
            string memory poolName = "Treasury";
            uint16 poolId = 2;

            wowToken.approve(address(vesting), TOTAL_POOL_TOKEN_AMOUNT_2);
            vesting.addVestingPool(
                poolName,
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
                pid: poolId,
                name: poolName,
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
        }

        balances.vestingBalanceBefore = wowToken.balanceOf(address(vesting));
        balances.adminBalanceBefore = wowToken.balanceOf(admin);

        {
            string memory poolName = "Team";
            uint16 poolId = 3;

            wowToken.approve(address(vesting), TOTAL_POOL_TOKEN_AMOUNT);
            vesting.addVestingPool(
                poolName,
                LISTING_PERCENTAGE_DIVIDEND_15,
                LISTING_PERCENTAGE_DIVISOR_40,
                CLIFF_IN_DAYS_2,
                CLIFF_PERCENTAGE_DIVIDEND_3,
                CLIFF_PERCENTAGE_DIVISOR_20,
                DURATION_5_MONTHS,
                MONTHLY_UNLOCK_TYPE,
                TOTAL_POOL_TOKEN_AMOUNT
            );

            poolData = PoolData({
                pid: poolId,
                name: poolName,
                listingPercentageDividend: LISTING_PERCENTAGE_DIVIDEND_15,
                listingPercentageDivisor: LISTING_PERCENTAGE_DIVISOR_40,
                cliffInDays: CLIFF_IN_DAYS_2,
                cliffPercentageDividend: CLIFF_PERCENTAGE_DIVIDEND_3,
                cliffPercentageDivisor: CLIFF_PERCENTAGE_DIVISOR_20,
                vestingDurationInMonths: DURATION_5_MONTHS,
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
            string memory poolName = "Advisors";
            uint16 poolId = 4;

            wowToken.approve(address(vesting), TOTAL_POOL_TOKEN_AMOUNT);
            vesting.addVestingPool(
                poolName,
                LISTING_PERCENTAGE_DIVIDEND_15,
                LISTING_PERCENTAGE_DIVISOR_40,
                CLIFF_IN_DAYS_2,
                CLIFF_PERCENTAGE_DIVIDEND_3,
                CLIFF_PERCENTAGE_DIVISOR_20,
                DURATION_5_MONTHS,
                MONTHLY_UNLOCK_TYPE,
                TOTAL_POOL_TOKEN_AMOUNT
            );

            poolData = PoolData({
                pid: poolId,
                name: poolName,
                listingPercentageDividend: LISTING_PERCENTAGE_DIVIDEND_15,
                listingPercentageDivisor: LISTING_PERCENTAGE_DIVISOR_40,
                cliffInDays: CLIFF_IN_DAYS_2,
                cliffPercentageDividend: CLIFF_PERCENTAGE_DIVIDEND_3,
                cliffPercentageDivisor: CLIFF_PERCENTAGE_DIVISOR_20,
                vestingDurationInMonths: DURATION_5_MONTHS,
                unlockType: MONTHLY_UNLOCK_TYPE,
                totalPoolTokenAmount: TOTAL_POOL_TOKEN_AMOUNT,
                vestingBalanceBefore: balances.vestingBalanceBefore,
                adminBalanceBefore: balances.adminBalanceBefore
            });
            assertPoolData(poolData);
        }

        {
            vesting.addBeneficiary(2, alice, BAND_2_PRICE);
            VestingAssertions.assertBeneficiaryData(
                2,
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

        balances.vestingBalanceBefore = wowToken.balanceOf(address(vesting));
        balances.adminBalanceBefore = wowToken.balanceOf(admin);

        {
            string memory poolName = "Team";
            uint16 poolId = 3;

            vesting.updateGeneralPoolData(
                poolId,
                poolName,
                DAILY_UNLOCK_TYPE,
                TOTAL_POOL_TOKEN_AMOUNT_2
            );

            uint256 tokensToDecrease = TOTAL_POOL_TOKEN_AMOUNT -
                TOTAL_POOL_TOKEN_AMOUNT_2;

            balances.vestingBalanceAfter = wowToken.balanceOf(address(vesting));
            balances.adminBalanceAfter = wowToken.balanceOf(admin);

            assertEq(
                balances.vestingBalanceBefore - tokensToDecrease,
                balances.vestingBalanceAfter
            );
            assertEq(
                balances.adminBalanceBefore + tokensToDecrease,
                balances.adminBalanceAfter
            );
        }

        balances.vestingBalanceBefore = wowToken.balanceOf(address(vesting));
        balances.adminBalanceBefore = wowToken.balanceOf(admin);

        {
            string memory poolName = "Advisors";
            uint16 poolId = 4;

            vesting.updateGeneralPoolData(
                poolId,
                poolName,
                DAILY_UNLOCK_TYPE,
                TOTAL_POOL_TOKEN_AMOUNT_2
            );

            uint256 tokensToDecrease = TOTAL_POOL_TOKEN_AMOUNT -
                TOTAL_POOL_TOKEN_AMOUNT_2;

            balances.vestingBalanceAfter = wowToken.balanceOf(address(vesting));
            balances.adminBalanceAfter = wowToken.balanceOf(admin);

            assertEq(
                balances.vestingBalanceBefore - tokensToDecrease,
                balances.vestingBalanceAfter
            );
            assertEq(
                balances.adminBalanceBefore + tokensToDecrease,
                balances.adminBalanceAfter
            );
        }

        balances.vestingBalanceBefore = wowToken.balanceOf(address(vesting));
        balances.adminBalanceBefore = wowToken.balanceOf(admin);

        {
            string memory poolName = "Treasury V2";
            uint16 poolId = 5;

            uint256 tokensForTreasuryV2 = (TOTAL_POOL_TOKEN_AMOUNT -
                TOTAL_POOL_TOKEN_AMOUNT_2) * 2;

            wowToken.approve(address(vesting), tokensForTreasuryV2);
            vesting.addVestingPool(
                poolName,
                LISTING_PERCENTAGE_DIVIDEND_15,
                LISTING_PERCENTAGE_DIVISOR_40,
                CLIFF_IN_DAYS_2,
                CLIFF_PERCENTAGE_DIVIDEND_3,
                CLIFF_PERCENTAGE_DIVISOR_20,
                DURATION_5_MONTHS,
                MONTHLY_UNLOCK_TYPE,
                tokensForTreasuryV2
            );

            poolData = PoolData({
                pid: poolId,
                name: poolName,
                listingPercentageDividend: LISTING_PERCENTAGE_DIVIDEND_15,
                listingPercentageDivisor: LISTING_PERCENTAGE_DIVISOR_40,
                cliffInDays: CLIFF_IN_DAYS_2,
                cliffPercentageDividend: CLIFF_PERCENTAGE_DIVIDEND_3,
                cliffPercentageDivisor: CLIFF_PERCENTAGE_DIVISOR_20,
                vestingDurationInMonths: DURATION_5_MONTHS,
                unlockType: MONTHLY_UNLOCK_TYPE,
                totalPoolTokenAmount: tokensForTreasuryV2,
                vestingBalanceBefore: balances.vestingBalanceBefore,
                adminBalanceBefore: balances.adminBalanceBefore
            });
            assertPoolData(poolData);
        }

        vm.stopPrank();
    }
}
