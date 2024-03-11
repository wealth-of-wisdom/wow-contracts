// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IVesting} from "../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../contracts/libraries/Errors.sol";
import {VestingMock} from "../mocks/VestingMock.sol";
import {StakingMock} from "../mocks/StakingMock.sol";
import {VestingMock} from "../mocks/VestingMock.sol";
import {Base_Test} from "../Base.t.sol";

contract Vesting_E2E_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function assertPoolData(
        uint16 pid,
        string memory name,
        uint16 listingPercentageDividend,
        uint16 listingPercentageDivisor,
        uint16 cliffInDays,
        uint16 cliffPercentageDividend,
        uint16 cliffPercentageDivisor,
        uint16 vestingDurationInMonths,
        IVesting.UnlockTypes unlockType,
        uint256 totalPoolTokenAmount,
        uint256 vestingBalanceBefore,
        uint256 adminBalanceBefore
    ) internal {
        uint256 vestingBalanceAfter = wowToken.balanceOf(address(vesting));
        uint256 adminBalanceAfter = wowToken.balanceOf(admin);
        (
            string memory nameSet,
            IVesting.UnlockTypes unlockTypeSet,
            uint256 totalAmountSet,

        ) = vesting.getGeneralPoolData(pid);
        (uint16 listingDividendSet, uint16 listingDivisorSet) = vesting
            .getPoolListingData(pid);
        (
            ,
            uint16 cliffInDaysSet,
            uint16 cliffDividendSet,
            uint16 cliffDivisorSet
        ) = vesting.getPoolCliffData(pid);
        (, uint16 vestingDurationInMonthsSet, ) = vesting.getPoolVestingData(
            pid
        );

        assertEq(name, nameSet, "Pool name incorrect");
        assertEq(
            listingPercentageDividend,
            listingDividendSet,
            "Listing percentage dividend incorrect"
        );
        assertEq(
            listingPercentageDivisor,
            listingDivisorSet,
            "Listing percentage divisor incorrect"
        );
        assertEq(cliffInDays, cliffInDaysSet, "Cliff in days incorrect");
        assertEq(
            cliffPercentageDivisor,
            cliffDivisorSet,
            "Cliff percentage divisor incorrect"
        );
        assertEq(
            cliffPercentageDividend,
            cliffDividendSet,
            "Cliff percentage dividend incorrect"
        );
        assertEq(
            vestingDurationInMonths,
            vestingDurationInMonthsSet,
            "Vesting duration in months incorrect"
        );
        assertEq(
            uint8(unlockType),
            uint8(unlockTypeSet),
            "Unlock type incorrect"
        );
        assertEq(
            totalPoolTokenAmount,
            totalAmountSet,
            "Total pool token amount incorrect"
        );

        assertEq(
            vestingBalanceBefore + totalAmountSet,
            vestingBalanceAfter,
            "Vesting contract balance incorrect"
        );
        assertEq(
            adminBalanceBefore - totalAmountSet,
            adminBalanceAfter,
            "Admin account balance incorrect"
        );
    }

    function assertBeneficiaryData(
        uint16 pid,
        address staker,
        uint256 beneficiaryTokenAmounts,
        uint256 lockedAmount,
        uint16 listingPercentageDividend,
        uint16 listingPercentageDivisor,
        uint16 cliffPercentageDividend,
        uint16 cliffPercentageDivisor
    ) internal {
        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            pid,
            staker
        );
        (, , , uint256 lockedAmountSet) = vesting.getGeneralPoolData(pid);

        assertEq(lockedAmountSet, lockedAmount, "Incorrect locked amount");
        assertEq(
            beneficiary.totalTokenAmount,
            beneficiaryTokenAmounts,
            "Incorrect user total token amount"
        );
        assertEq(
            beneficiary.listingTokenAmount,
            (beneficiaryTokenAmounts * listingPercentageDividend) /
                listingPercentageDivisor,
            "Incorrect user listing token amount"
        );
        assertEq(
            beneficiary.cliffTokenAmount,
            (beneficiaryTokenAmounts * cliffPercentageDividend) /
                cliffPercentageDivisor,
            "Incorrect user cliff token amount"
        );
        assertEq(
            beneficiary.vestedTokenAmount,
            beneficiaryTokenAmounts -
                beneficiary.listingTokenAmount -
                beneficiary.cliffTokenAmount,
            "Incorrect user vested token amount"
        );
    }

    function assertStakerVestedData(
        uint16 pid,
        address staker,
        uint256 beneficiaryTokenAmount
    ) internal {
        IVesting.Beneficiary memory user = vesting.getBeneficiary(pid, staker);
        assertEq(
            user.stakedTokenAmount,
            beneficiaryTokenAmount,
            "Staked tokens not set"
        );
    }

    function assertTokensClaimed(
        uint16 pid,
        address staker,
        uint256 sakerBalanceBefore,
        uint256 vestingBalanceBefore,
        uint256 unlockedTokenAmount
    ) internal {
        uint256 stakerBalanceAfter = wowToken.balanceOf(staker);
        uint256 vestingBalanceAfter = wowToken.balanceOf(address(vesting));
        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            pid,
            staker
        );
        assertEq(sakerBalanceBefore + unlockedTokenAmount, stakerBalanceAfter);
        assertEq(
            vestingBalanceBefore - unlockedTokenAmount,
            vestingBalanceAfter
        );
        assertEq(beneficiary.claimedTokenAmount, unlockedTokenAmount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                TESTS
    //////////////////////////////////////////////////////////////////////////*/
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
        assertBeneficiaryData(
            PRIMARY_POOL,
            alice,
            BAND_2_PRICE,
            BAND_2_PRICE,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR
        );

        uint256 totalLockedTokens = BAND_2_PRICE + BAND_3_PRICE;

        vesting.addBeneficiary(PRIMARY_POOL, bob, BAND_3_PRICE);
        assertBeneficiaryData(
            PRIMARY_POOL,
            bob,
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

        assertBeneficiaryData(
            PRIMARY_POOL,
            alice,
            BAND_2_PRICE,
            totalLockedTokens,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR
        );
        assertBeneficiaryData(
            PRIMARY_POOL,
            bob,
            BAND_3_PRICE,
            totalLockedTokens,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR
        );
    }

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

        vestingBalanceBefore = wowToken.balanceOf(address(vesting));
        adminBalanceBefore = wowToken.balanceOf(admin);

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
        assertPoolData(
            SECONDARY_POOL,
            POOL_NAME_2,
            LISTING_PERCENTAGE_DIVIDEND_2,
            LISTING_PERCENTAGE_DIVISOR_2,
            CLIFF_IN_DAYS_2,
            CLIFF_PERCENTAGE_DIVIDEND_2,
            CLIFF_PERCENTAGE_DIVISOR_2,
            VESTING_DURATION_IN_MONTHS_2,
            MONTHLY_UNLOCK_TYPE,
            TOTAL_POOL_TOKEN_AMOUNT_2,
            vestingBalanceBefore,
            adminBalanceBefore
        );

        vesting.addBeneficiary(PRIMARY_POOL, alice, BAND_2_PRICE);
        assertBeneficiaryData(
            PRIMARY_POOL,
            alice,
            BAND_2_PRICE,
            BAND_2_PRICE,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR
        );
        vesting.addBeneficiary(SECONDARY_POOL, bob, BAND_3_PRICE);
        assertBeneficiaryData(
            SECONDARY_POOL,
            bob,
            BAND_3_PRICE,
            BAND_3_PRICE,
            LISTING_PERCENTAGE_DIVIDEND_2,
            LISTING_PERCENTAGE_DIVISOR_2,
            CLIFF_PERCENTAGE_DIVIDEND_2,
            CLIFF_PERCENTAGE_DIVISOR_2
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
            SECONDARY_POOL
        );
        assertStakerVestedData(SECONDARY_POOL, bob, BAND_3_PRICE);
        vm.stopPrank();

        vm.warp(MONTH_1);

        vm.prank(alice);
        vesting.unstakeVestedTokens(BAND_ID_0);
        assertStakerVestedData(PRIMARY_POOL, alice, 0);

        vm.prank(bob);
        vesting.unstakeVestedTokens(BAND_ID_1);
        assertStakerVestedData(SECONDARY_POOL, bob, 0);

        assertBeneficiaryData(
            PRIMARY_POOL,
            alice,
            BAND_2_PRICE,
            BAND_2_PRICE,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR
        );
        assertBeneficiaryData(
            SECONDARY_POOL,
            bob,
            BAND_3_PRICE,
            BAND_3_PRICE,
            LISTING_PERCENTAGE_DIVIDEND_2,
            LISTING_PERCENTAGE_DIVISOR_2,
            CLIFF_PERCENTAGE_DIVIDEND_2,
            CLIFF_PERCENTAGE_DIVISOR_2
        );
    }

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

        vestingBalanceBefore = wowToken.balanceOf(address(vesting));
        adminBalanceBefore = wowToken.balanceOf(admin);

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
        assertPoolData(
            SECONDARY_POOL,
            POOL_NAME_2,
            LISTING_PERCENTAGE_DIVIDEND_2,
            LISTING_PERCENTAGE_DIVISOR_2,
            CLIFF_IN_DAYS_2,
            CLIFF_PERCENTAGE_DIVIDEND_2,
            CLIFF_PERCENTAGE_DIVISOR_2,
            VESTING_DURATION_IN_MONTHS_2,
            MONTHLY_UNLOCK_TYPE,
            TOTAL_POOL_TOKEN_AMOUNT_2,
            vestingBalanceBefore,
            adminBalanceBefore
        );

        vesting.addBeneficiary(PRIMARY_POOL, alice, BAND_1_PRICE);
        assertBeneficiaryData(
            PRIMARY_POOL,
            alice,
            BAND_1_PRICE,
            BAND_1_PRICE,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR
        );
        vesting.addBeneficiary(SECONDARY_POOL, alice, BAND_2_PRICE);
        assertBeneficiaryData(
            SECONDARY_POOL,
            alice,
            BAND_2_PRICE,
            BAND_2_PRICE,
            LISTING_PERCENTAGE_DIVIDEND_2,
            LISTING_PERCENTAGE_DIVISOR_2,
            CLIFF_PERCENTAGE_DIVIDEND_2,
            CLIFF_PERCENTAGE_DIVISOR_2
        );
        vm.stopPrank();

        vm.startPrank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FLEXI,
            BAND_LEVEL_1,
            MONTH_0,
            PRIMARY_POOL
        );
        assertStakerVestedData(PRIMARY_POOL, alice, BAND_1_PRICE);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FLEXI,
            BAND_LEVEL_2,
            MONTH_0,
            SECONDARY_POOL
        );
        assertStakerVestedData(SECONDARY_POOL, alice, BAND_2_PRICE);

        vm.warp(MONTH_1);

        vesting.unstakeVestedTokens(BAND_ID_0);
        assertStakerVestedData(PRIMARY_POOL, alice, 0);
        vesting.unstakeVestedTokens(BAND_ID_1);
        assertStakerVestedData(SECONDARY_POOL, alice, 0);

        vm.stopPrank();

        vm.prank(admin);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);

        assertBeneficiaryData(
            PRIMARY_POOL,
            alice,
            0,
            0,
            LISTING_PERCENTAGE_DIVIDEND_2,
            LISTING_PERCENTAGE_DIVISOR_2,
            CLIFF_PERCENTAGE_DIVIDEND_2,
            CLIFF_PERCENTAGE_DIVISOR_2
        );
        assertBeneficiaryData(
            SECONDARY_POOL,
            alice,
            BAND_2_PRICE,
            BAND_2_PRICE,
            LISTING_PERCENTAGE_DIVIDEND_2,
            LISTING_PERCENTAGE_DIVISOR_2,
            CLIFF_PERCENTAGE_DIVIDEND_2,
            CLIFF_PERCENTAGE_DIVISOR_2
        );
    }

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
        assertBeneficiaryData(
            PRIMARY_POOL,
            alice,
            BAND_3_PRICE,
            BAND_3_PRICE,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR
        );

        uint256 totalLockedTokens = BAND_3_PRICE + BAND_4_PRICE;

        vesting.addBeneficiary(PRIMARY_POOL, bob, BAND_4_PRICE);
        assertBeneficiaryData(
            PRIMARY_POOL,
            bob,
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

    function test_1User_1Pool_Create_Stake_Stake() external {
        /**
         * 1. Pool added to vesting
         * 2. Alice added as beneficiary
         * 3. Alice stakes vested tokens
         * 4. Time passes
         * 5. Alice stakes vested tokens again
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

        vesting.addBeneficiary(PRIMARY_POOL, alice, BAND_6_PRICE);
        assertBeneficiaryData(
            PRIMARY_POOL,
            alice,
            BAND_6_PRICE,
            BAND_6_PRICE,
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

        vm.warp(MONTH_1);

        uint256 totalStakedTokens = BAND_2_PRICE + BAND_3_PRICE;

        vm.startPrank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FLEXI,
            BAND_LEVEL_3,
            MONTH_0,
            PRIMARY_POOL
        );
        assertStakerVestedData(PRIMARY_POOL, alice, totalStakedTokens);
        vm.stopPrank();

        assertBeneficiaryData(
            PRIMARY_POOL,
            alice,
            BAND_6_PRICE,
            BAND_6_PRICE,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR
        );
    }

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

        vesting.addBeneficiary(PRIMARY_POOL, alice, BAND_6_PRICE);
        assertBeneficiaryData(
            PRIMARY_POOL,
            alice,
            BAND_6_PRICE,
            BAND_6_PRICE,
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

        vm.warp(MONTH_1);

        uint256 totalStakedTokens = BAND_2_PRICE + BAND_3_PRICE;

        vm.startPrank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FLEXI,
            BAND_LEVEL_3,
            MONTH_0,
            PRIMARY_POOL
        );
        assertStakerVestedData(PRIMARY_POOL, alice, totalStakedTokens);
        vm.stopPrank();

        assertBeneficiaryData(
            PRIMARY_POOL,
            alice,
            BAND_6_PRICE,
            BAND_6_PRICE,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR
        );

        vm.prank(alice);
        vesting.unstakeVestedTokens(BAND_ID_0);
        assertStakerVestedData(PRIMARY_POOL, alice, BAND_3_PRICE);
    }
}
