// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Vesting_UpdatePoolCliffData_Unit_Test is Unit_Test {
    function test_updatePoolCliffData_RevertIf_CallerNotAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        vesting.updatePoolListingData(
            PRIMARY_POOL,
            LISTING_PERCENTAGE_DIVIDEND_15,
            LISTING_PERCENTAGE_DIVISOR_40
        );
    }

    function test_updatePoolCliffData_RevertIf_BeneficiariesAdded()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.expectRevert(Errors.Vesting__PoolHasBeneficiaries.selector);
        _updatePoolCliffData();
    }

    function test_updatePoolCliffData_RevertIf_ListingAndCliffPercentageOverflow()
        external
        approveAndAddPool
    {
        vm.expectRevert(
            Errors.Vesting__ListingAndCliffPercentageOverflow.selector
        );
        vm.prank(admin);
        vesting.updatePoolListingData(PRIMARY_POOL, 99, 100);
    }

    function test_updatePoolCliffData_RevertIf_CliffDivisorZero()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__PercentageDivisorZero.selector);
        vm.prank(admin);
        vesting.updatePoolCliffData(
            PRIMARY_POOL,
            CLIFF_IN_DAYS_2,
            CLIFF_PERCENTAGE_DIVIDEND_3,
            0
        );
    }

    function test_updatePoolCliffData_RevertIf_CliffPercentageOverflow()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__PercentageOverflow.selector);
        vm.prank(admin);
        vesting.updatePoolCliffData(PRIMARY_POOL, CLIFF_IN_DAYS_2, 100, 51);
    }

    function test_updatePoolCliffData_UpdatesCliffEndDateCorrectly()
        external
        approveAndAddPool
        updatePoolCliffData
    {
        (uint32 cliffEndDate, , , ) = vesting.getPoolCliffData(PRIMARY_POOL);
        assertEq(
            cliffEndDate,
            LISTING_DATE + CLIFF_IN_SECONDS_2,
            "Cliff end date incorrect"
        );
    }

    function test_updatePoolCliffData_UpdatesCliffInDaysCorrectly()
        external
        approveAndAddPool
        updatePoolCliffData
    {
        (, uint16 inDays, , ) = vesting.getPoolCliffData(PRIMARY_POOL);
        assertEq(inDays, CLIFF_IN_DAYS_2, "Cliff in days incorrect");
    }

    function test_updatePoolCliffData_UpdatesCliffPercentageDividendCorrectly()
        external
        approveAndAddPool
        updatePoolCliffData
    {
        (, , uint16 dividend, ) = vesting.getPoolCliffData(PRIMARY_POOL);
        assertEq(
            dividend,
            CLIFF_PERCENTAGE_DIVIDEND_3,
            "Listing percentage dividend incorrect"
        );
    }

    function test_updatePoolCliffData_UpdatesCliffPercentageDivisorCorrectly()
        external
        approveAndAddPool
        updatePoolCliffData
    {
        (, , , uint16 divisor) = vesting.getPoolCliffData(PRIMARY_POOL);
        assertEq(
            divisor,
            CLIFF_PERCENTAGE_DIVISOR_20,
            "Listing percentage divisor incorrect"
        );
    }

    function test_updatePoolCliffData_EmitsVestingPoolUpdatedEvent()
        external
        approveAndAddPool
    {
        uint32 cliffEndDate = LISTING_DATE + CLIFF_IN_SECONDS_2;
        vm.expectEmit(address(vesting));
        emit PoolCliffDataUpdated(
            PRIMARY_POOL,
            cliffEndDate,
            CLIFF_IN_DAYS_2,
            CLIFF_PERCENTAGE_DIVIDEND_3,
            CLIFF_PERCENTAGE_DIVISOR_20
        );

        _updatePoolCliffData();
    }
}
