// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Vesting_UpdateVestinData_Unit_Test is Unit_Test {
    function test_updateVestingData_RevertIf_CallerNotAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        vesting.updatePoolVestingData(
            PRIMARY_POOL,
            VESTING_DURATION_IN_MONTHS_5
        );
    }

    function test_updateVestingData_RevertIf_BeneficiariesAdded()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.expectRevert(Errors.Vesting__PoolHasBeneficiaries.selector);
        _updatePoolVestingData();
    }

    function test_updateVestingData_RevertIf_VestingDurationZero()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__VestingDurationZero.selector);
        vm.prank(admin);
        vesting.updatePoolVestingData(PRIMARY_POOL, 0);
    }

    function test_updateVestingData_UpdatesVestingDurationInDaysCorrectly()
        external
        approveAndAddPool
        updatePoolVestingData
    {
        (, , uint16 vestingDurationInDays) = vesting.getPoolVestingData(
            PRIMARY_POOL
        );
        assertEq(
            vestingDurationInDays,
            VESTING_DURATION_IN_MONTHS_5 * 30,
            "Vesting duration in days incorrect"
        );
    }

    function test_updateVestingData_UpdatesVestingDurationInMonthsCorrectly()
        external
        approveAndAddPool
        updatePoolVestingData
    {
        (, uint16 vestingDurationInMonths, ) = vesting.getPoolVestingData(
            PRIMARY_POOL
        );
        assertEq(
            vestingDurationInMonths,
            VESTING_DURATION_IN_MONTHS_5,
            "Vesting duration in months incorrect"
        );
    }

    function test_updateVestingData_UpdatesVestingEndDateCorrectly()
        external
        approveAndAddPool
        updatePoolVestingData
    {
        (uint32 endDate, , ) = vesting.getPoolVestingData(PRIMARY_POOL);
        uint32 actualEndDate = uint32(
            LISTING_DATE + CLIFF_IN_SECONDS + VESTING_DURATION_IN_SECONDS_5
        );

        assertEq(endDate, actualEndDate, "Vesting end date incorrect");
    }

    function test_updateVestingData_EmitsVestingPoolUpdatedEvent()
        external
        approveAndAddPool
    {
        vm.expectEmit(address(vesting));
        uint32 newVestingEndDate = CLIFF_END_DATE +
            VESTING_DURATION_IN_SECONDS_5;
        emit PoolVestingDataUpdated(
            PRIMARY_POOL,
            newVestingEndDate,
            VESTING_DURATION_IN_MONTHS_5,
            VESTING_DURATION_IN_DAYS_5
        );

        _updatePoolVestingData();
    }
}
