// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Vesting_Unit_Test} from "../VestingUnit.t.sol";

contract Vesting_GetVestingPeriodsPassed_Unit_Test is Vesting_Unit_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier setDailyUnlockType() {
        vesting.mock_setPoolUnlockType(
            PRIMARY_POOL,
            IVesting.UnlockTypes.DAILY
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    DAILY UNLOCK
    //////////////////////////////////////////////////////////////////////////*/

    function test_getVestingPeriodsPassed_DailyUnlock_ReturnsVestingDurationIfCliffNotReached()
        external
        approveAndAddPool
        setDailyUnlockType
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE - 1 minutes);
        (, uint16 duration) = vesting.getVestingPeriodsPassed(PRIMARY_POOL);

        assertEq(
            duration,
            VESTING_DURATION_IN_DAYS,
            "Vesting duration incorrect"
        );
    }

    function test_getVestingPeriodsPassed_DailyUnlock_ReturnsVestingDurationOneMonthAfterCliff()
        external
        approveAndAddPool
        setDailyUnlockType
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE + MONTH);
        (, uint16 duration) = vesting.getVestingPeriodsPassed(PRIMARY_POOL);

        assertEq(
            duration,
            VESTING_DURATION_IN_DAYS,
            "Vesting duration incorrect"
        );
    }

    function test_getVestingPeriodsPassed_DailyUnlock_ReturnsZeroPeriodsPassedIfCliffNotReached()
        external
        approveAndAddPool
        setDailyUnlockType
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE - 1 minutes);
        (uint16 periodsPassed, ) = vesting.getVestingPeriodsPassed(
            PRIMARY_POOL
        );

        assertEq(periodsPassed, 0, "Periods passed should be zero");
    }

    function test_getVestingPeriodsPassed_DailyUnlock_ReturnsZeroPeriodsPassedIfCliffReachedButDayNotPassed()
        external
        approveAndAddPool
        setDailyUnlockType
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE + DAY - 1 minutes);
        (uint16 periodsPassed, ) = vesting.getVestingPeriodsPassed(
            PRIMARY_POOL
        );

        assertEq(periodsPassed, 0, "Periods passed should be zero");
    }

    function test_getVestingPeriodsPassed_DailyUnlock_Returns30PeriodsPassedOneMonthAfterCliff()
        external
        approveAndAddPool
        setDailyUnlockType
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE + MONTH);
        (uint16 periodsPassed, ) = vesting.getVestingPeriodsPassed(
            PRIMARY_POOL
        );

        assertEq(periodsPassed, 30, "Periods passed incorrect");
    }

    function test_getVestingPeriodsPassed_DailyUnlock_Returns720PeriodsPassedTwoYearsAfterCliff()
        external
        approveAndAddPool
        setDailyUnlockType
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE + MONTH * 24);
        (uint16 periodsPassed, ) = vesting.getVestingPeriodsPassed(
            PRIMARY_POOL
        );

        assertEq(periodsPassed, 720, "Periods passed incorrect");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    MONTHLY UNLOCK
    //////////////////////////////////////////////////////////////////////////*/

    function test_getVestingPeriodsPassed_MonthlyUnlock_ReturnsVestingDurationIfCliffNotReached()
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

    function test_getVestingPeriodsPassed_MonthlyUnlock_ReturnsVestingDurationOneMonthAfterCliff()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE + MONTH);
        (, uint16 duration) = vesting.getVestingPeriodsPassed(PRIMARY_POOL);

        assertEq(
            duration,
            VESTING_DURATION_IN_MONTHS,
            "Vesting duration incorrect"
        );
    }

    function test_getVestingPeriodsPassed_MonthlyUnlock_ReturnsZeroPeriodsPassedIfCliffNotReached()
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

    function test_getVestingPeriodsPassed_MonthlyUnlock_ReturnsZeroPeriodsPassedIfCliffReachedButMonthNotPassed()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE + MONTH - 1 minutes);
        (uint16 periodsPassed, ) = vesting.getVestingPeriodsPassed(
            PRIMARY_POOL
        );

        assertEq(periodsPassed, 0, "Periods passed should be zero");
    }

    function test_getVestingPeriodsPassed_MonthlyUnlock_Returns1PeriodPassedOneMonthAfterCliff()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE + MONTH);
        (uint16 periodsPassed, ) = vesting.getVestingPeriodsPassed(
            PRIMARY_POOL
        );

        assertEq(periodsPassed, 1, "Periods passed incorrect");
    }

    function test_getVestingPeriodsPassed_MonthlyUnlock_Returns24PeriodPassedTwoYearsAfterCliff()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE + MONTH * 24);
        (uint16 periodsPassed, ) = vesting.getVestingPeriodsPassed(
            PRIMARY_POOL
        );

        assertEq(periodsPassed, 24, "Periods passed incorrect");
    }
}
