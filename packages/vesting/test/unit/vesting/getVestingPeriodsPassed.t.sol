// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
import {Errors} from "@wealth-of-wisdom/vesting/contracts/libraries/Errors.sol";
import {Vesting_Unit_Test} from "@wealth-of-wisdom/vesting/test/unit/VestingUnit.t.sol";

contract Vesting_GetVestingPeriodsPassed_Unit_Test is Vesting_Unit_Test {
    function test_getVestingPeriodsPassed_ReturnsZeroPeriodsPassedIfCliffNotReached()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE - 1 minutes);
        (uint16 periodsPassed, ) = vesting.getVestingPeriodsPassed(
            PRIMARY_POOL
        );

        assertEq(periodsPassed, 0, "Periods passed should be zero");
    }

    function test_getVestingPeriodsPassed_ReturnsVestingDurationInMonthsIfCliffNotReached()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE - 1 minutes);
        (, uint16 duration) = vesting.getVestingPeriodsPassed(PRIMARY_POOL);

        assertEq(
            duration,
            VESTING_DURATION_IN_MONTHS,
            "Vesting duration incorrect"
        );
    }

    function test_getVestingPeriodsPassed_Returns30PeriodsPassedIfUnlockTypeIsDailyAndCliffReached()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vesting.mock_setPoolUnlockType(
            PRIMARY_POOL,
            IVesting.UnlockTypes.DAILY
        );

        vm.warp(CLIFF_END_DATE + 30 days);
        (uint16 periodsPassed, ) = vesting.getVestingPeriodsPassed(
            PRIMARY_POOL
        );

        assertEq(periodsPassed, 30, "Periods passed incorrect");
    }

    function test_getVestingPeriodsPassed_Returns1PeriodPassedIfUnlockTypeIsMonthlyAndCliffReached()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vesting.mock_setPoolUnlockType(
            PRIMARY_POOL,
            IVesting.UnlockTypes.MONTHLY
        );

        vm.warp(CLIFF_END_DATE + 30 days);
        (uint16 periodsPassed, ) = vesting.getVestingPeriodsPassed(
            PRIMARY_POOL
        );

        assertEq(periodsPassed, 1, "Periods passed incorrect");
    }

    function test_getVestingPeriodsPassed_ReturnDurationInDaysIfUnlockTypeIsDailyAndCliffReached()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vesting.mock_setPoolUnlockType(
            PRIMARY_POOL,
            IVesting.UnlockTypes.DAILY
        );

        vm.warp(CLIFF_END_DATE + 30 days);
        (, uint16 duration) = vesting.getVestingPeriodsPassed(PRIMARY_POOL);

        assertEq(
            duration,
            VESTING_DURATION_IN_MONTHS * 30,
            "Periods passed incorrect"
        );
    }

    function test_getVestingPeriodsPassed_ReturnDurationInMonthsIfUnlockTypeIsMonthlyAndCliffReached()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vesting.mock_setPoolUnlockType(
            PRIMARY_POOL,
            IVesting.UnlockTypes.MONTHLY
        );

        vm.warp(CLIFF_END_DATE + 30 days);
        (, uint16 duration) = vesting.getVestingPeriodsPassed(PRIMARY_POOL);

        assertEq(
            duration,
            VESTING_DURATION_IN_MONTHS,
            "Periods passed incorrect"
        );
    }
}
