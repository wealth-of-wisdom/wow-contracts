// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import {VestingAssertions} from "./VestingAssertions.t.sol";

contract Vesting_E2E_Test is VestingAssertions {
    function test_2Users_1Pool_Create_Claim_Stake() external {
        /**
         * 1. Pool added to vesting
         * 2. Alice added as beneficiary
         * 3. Bob added as beneficiary
         * 4. Alice added as beneficiary
         * 5. Bob added as beneficiary
         * 6. Time passes
         * 7. Alice claims tokens
         * 8. Bob claims tokens
         * 9. Alice stakes vested tokens
         * 10. Bob stakes vested tokens
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

        vesting.addBeneficiary(PRIMARY_POOL, alice, BAND_3_PRICE);
        VestingAssertions.assertBeneficiaryData(
            PRIMARY_POOL,
            alice,
            0,
            0,
            BAND_3_PRICE,
            BAND_3_PRICE,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR
        );

        uint256 totalLockedTokens = BAND_3_PRICE + BAND_4_PRICE;

        vesting.addBeneficiary(PRIMARY_POOL, bob, BAND_4_PRICE);
        VestingAssertions.assertBeneficiaryData(
            PRIMARY_POOL,
            bob,
            0,
            0,
            BAND_4_PRICE,
            totalLockedTokens,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR
        );
        vm.stopPrank();

        vm.warp(LISTING_DATE + CLIFF_IN_DAYS);

        vm.startPrank(alice);
        uint256 vestingBalancBefore = wowToken.balanceOf(address(vesting));
        uint256 aliceBalanceBefore = wowToken.balanceOf(alice);
        uint256 aliceUnlockedTokenAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            alice
        );

        vesting.claimTokens(PRIMARY_POOL);
        assertTokensClaimed(
            PRIMARY_POOL,
            alice,
            aliceBalanceBefore,
            vestingBalancBefore,
            aliceUnlockedTokenAmount
        );

        vesting.stakeVestedTokens(
            STAKING_TYPE_FLEXI,
            BAND_LEVEL_1,
            MONTH_0,
            PRIMARY_POOL
        );
        assertStakerVestedData(PRIMARY_POOL, alice, BAND_1_PRICE);
        vm.stopPrank();

        vm.startPrank(bob);
        vestingBalancBefore = wowToken.balanceOf(address(vesting));
        uint256 bobBalanceBefore = wowToken.balanceOf(bob);
        uint256 bobUnlockedTokenAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            bob
        );

        vesting.claimTokens(PRIMARY_POOL);
        assertTokensClaimed(
            PRIMARY_POOL,
            bob,
            bobBalanceBefore,
            vestingBalancBefore,
            bobUnlockedTokenAmount
        );

        vesting.stakeVestedTokens(
            STAKING_TYPE_FLEXI,
            BAND_LEVEL_2,
            MONTH_0,
            PRIMARY_POOL
        );
        assertStakerVestedData(PRIMARY_POOL, bob, BAND_2_PRICE);
        vm.stopPrank();
    }
}
