// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Vesting_Unit_Test} from "./VestingUnit.t.sol";

contract Vesting_GetUnlockedTokenAmount_Unit_Test is Vesting_Unit_Test {
    // Current time is 1 minute before listing date
    function test_getUnlockedTokenAmount_ReturnsZeroWhenListingDateNotReaced()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(LISTING_DATE - 1 minutes);
        uint256 unlockedAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            alice
        );

        assertEq(unlockedAmount, 0, "Unlocked amount should be zero");
    }

    // Current time is listing date
    function test_getUnlockedTokenAmount_ReturnsListingAmountWhenListingDateReached()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(LISTING_DATE);
        uint256 unlockedAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            unlockedAmount,
            LISTING_TOKEN_AMOUNT,
            "Unlocked amount incorrect"
        );
    }

    // Current time is listing date
    function test_getUnlockedTokenAmount_ReturnsListingMinusClaimedAmountWhenListingDateReached()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        uint256 alreadyClaimedAmount = (LISTING_TOKEN_AMOUNT * 3) / 4;
        vesting.mock_setClaimedAmount(
            PRIMARY_POOL,
            alice,
            alreadyClaimedAmount
        );

        vm.warp(LISTING_DATE);
        uint256 unlockedAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            unlockedAmount,
            LISTING_TOKEN_AMOUNT - alreadyClaimedAmount,
            "Unlocked amount incorrect"
        );
    }

    // Current time is 1 minute after listing date
    function test_getUnlockedTokenAmount_ReturnsListingAmountWhenCliffDateNotReached()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(LISTING_DATE + 1 minutes);
        uint256 unlockedAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            unlockedAmount,
            LISTING_TOKEN_AMOUNT,
            "Unlocked amount incorrect"
        );
    }

    // Current time is 1 minute after listing date
    function test_getUnlockedTokenAmount_ReturnsListingMinusClaimedAmountWhenCliffDateNotReached()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        uint256 alreadyClaimedAmount = (LISTING_TOKEN_AMOUNT * 3) / 4;
        vesting.mock_setClaimedAmount(
            PRIMARY_POOL,
            alice,
            alreadyClaimedAmount
        );

        vm.warp(LISTING_DATE + 1 minutes);
        uint256 unlockedAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            alice
        );

        assertEq(
            unlockedAmount,
            LISTING_TOKEN_AMOUNT - alreadyClaimedAmount,
            "Unlocked amount incorrect"
        );
    }

    // Current time is vesting end date
    function test_getUnlockedTokenAmount_ReturnsTotalAmountWhenVestingEndReached()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(VESTING_END_DATE);
        uint256 unlockedAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            alice
        );

        assertEq(
            unlockedAmount,
            BENEFICIARY_TOKEN_AMOUNT,
            "Unlocked amount incorrect"
        );
    }

    // Current time is vesting end date
    function test_getUnlockedTokenAmount_ReturnsTotalMinusClaimedAmountWhenVestingEndReached()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        uint256 alreadyClaimedAmount = (BENEFICIARY_TOKEN_AMOUNT * 3) / 4;
        vesting.mock_setClaimedAmount(
            PRIMARY_POOL,
            alice,
            alreadyClaimedAmount
        );

        vm.warp(VESTING_END_DATE);
        uint256 unlockedAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            unlockedAmount,
            BENEFICIARY_TOKEN_AMOUNT - alreadyClaimedAmount,
            "Unlocked amount incorrect"
        );
    }

    // Current time is 1 minute after vesting end date
    function test_getUnlockedTokenAmount_ReturnsTotalAmountWhenVestingEndPassed()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(VESTING_END_DATE + 1 minutes);
        uint256 unlockedAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            alice
        );

        assertEq(
            unlockedAmount,
            BENEFICIARY_TOKEN_AMOUNT,
            "Unlocked amount incorrect"
        );
    }

    // Current time is 1 minute after vesting end date
    function test_getUnlockedTokenAmount_ReturnsTotalMinusClaimedAmountWhenVestingEndPassed()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        uint256 alreadyClaimedAmount = (BENEFICIARY_TOKEN_AMOUNT * 3) / 4;
        vesting.mock_setClaimedAmount(
            PRIMARY_POOL,
            alice,
            alreadyClaimedAmount
        );

        vm.warp(VESTING_END_DATE + 1 minutes);
        uint256 unlockedAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            unlockedAmount,
            BENEFICIARY_TOKEN_AMOUNT - alreadyClaimedAmount,
            "Unlocked amount incorrect"
        );
    }

    // Current time is cliff end date
    function test_getUnlockedTokenAmount_ReturnsListingAndCliffAmountWhenCliffDateReached()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE);
        uint256 unlockedAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            alice
        );

        assertEq(
            unlockedAmount,
            LISTING_AND_CLIFF_TOKEN_AMOUNT,
            "Unlocked amount incorrect"
        );
    }

    // Current time is cliff end date
    function test_getUnlockedTokenAmount_ReturnsListingAndCliffMinusClaimedAmountWhenCliffDateReached()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        uint256 alreadyClaimedAmount = (LISTING_AND_CLIFF_TOKEN_AMOUNT * 3) / 4;
        vesting.mock_setClaimedAmount(
            PRIMARY_POOL,
            alice,
            alreadyClaimedAmount
        );

        vm.warp(CLIFF_END_DATE);
        uint256 unlockedAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            alice
        );

        assertEq(
            unlockedAmount,
            LISTING_AND_CLIFF_TOKEN_AMOUNT - alreadyClaimedAmount,
            "Unlocked amount incorrect"
        );
    }

    // Current time is 1 minute after cliff end date
    function test_getUnlockedTokenAmount_ReturnsListingAndCliffAmountWhenCliffDatePassed()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE + 1 minutes);
        uint256 unlockedAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            alice
        );

        assertEq(
            unlockedAmount,
            LISTING_AND_CLIFF_TOKEN_AMOUNT,
            "Unlocked amount incorrect"
        );
    }

    // Current time is 1 minute after cliff end date
    function test_getUnlockedTokenAmount_ReturnsListingAndCliffMinusClaimedAmountWhenCliffDatePassed()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        uint256 alreadyClaimedAmount = (LISTING_AND_CLIFF_TOKEN_AMOUNT * 3) / 4;
        vesting.mock_setClaimedAmount(
            PRIMARY_POOL,
            alice,
            alreadyClaimedAmount
        );

        vm.warp(CLIFF_END_DATE + 1 minutes);
        uint256 unlockedAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            alice
        );

        assertEq(
            unlockedAmount,
            LISTING_AND_CLIFF_TOKEN_AMOUNT - alreadyClaimedAmount,
            "Unlocked amount incorrect"
        );
    }

    // Current time is 1 month after cliff end date
    function test_getUnlockedTokenAmount_ReturnsVestedAmountWhenOnePeriodPassed()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE + 30 days);
        uint256 unlockedAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            alice
        );

        assertEq(
            unlockedAmount,
            LISTING_AND_CLIFF_TOKEN_AMOUNT +
                (VESTING_TOKEN_AMOUNT / VESTING_DURATION_IN_MONTHS),
            "Unlocked amount incorrect"
        );
    }

    // Current time is 1 month after cliff end date
    function test_getUnlockedTokenAmount_ReturnsVestedMinusClaimedAmountWhenOnePeriodPassed()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        uint256 alreadyClaimedAmount = (LISTING_AND_CLIFF_TOKEN_AMOUNT * 3) / 4;
        vesting.mock_setClaimedAmount(
            PRIMARY_POOL,
            alice,
            alreadyClaimedAmount
        );

        vm.warp(CLIFF_END_DATE + 30 days);
        uint256 unlockedAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            alice
        );

        assertEq(
            unlockedAmount,
            LISTING_AND_CLIFF_TOKEN_AMOUNT +
                (VESTING_TOKEN_AMOUNT / VESTING_DURATION_IN_MONTHS) -
                alreadyClaimedAmount,
            "Unlocked amount incorrect"
        );
    }

    // Current time is 2 month after cliff end date
    function test_getUnlockedTokenAmount_ReturnsVestedAmountWhenTwoPeriodPassed()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE + 60 days);
        uint256 unlockedAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            alice
        );

        assertEq(
            unlockedAmount,
            LISTING_AND_CLIFF_TOKEN_AMOUNT +
                ((VESTING_TOKEN_AMOUNT * 2) / VESTING_DURATION_IN_MONTHS),
            "Unlocked amount incorrect"
        );
    }

    // Current time is 1 month after cliff end date
    function test_getUnlockedTokenAmount_ReturnsVestedMinusClaimedAmountWhenTwoPeriodPassed()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        uint256 alreadyClaimedAmount = (LISTING_AND_CLIFF_TOKEN_AMOUNT * 3) / 4;
        vesting.mock_setClaimedAmount(
            PRIMARY_POOL,
            alice,
            alreadyClaimedAmount
        );

        vm.warp(CLIFF_END_DATE + 60 days);
        uint256 unlockedAmount = vesting.getUnlockedTokenAmount(
            PRIMARY_POOL,
            alice
        );

        assertEq(
            unlockedAmount,
            LISTING_AND_CLIFF_TOKEN_AMOUNT +
                ((VESTING_TOKEN_AMOUNT * 2) / VESTING_DURATION_IN_MONTHS) -
                alreadyClaimedAmount,
            "Unlocked amount incorrect"
        );
    }
}
