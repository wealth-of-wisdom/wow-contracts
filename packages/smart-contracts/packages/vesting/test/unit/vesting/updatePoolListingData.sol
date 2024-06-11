// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Vesting_UpdatePoolListingData_Unit_Test is Unit_Test {
    function test_updatePoolListingData_RevertIf_CallerNotAdmin() external {
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
            LISTING_PERCENTAGE_DIVIDEND_2,
            LISTING_PERCENTAGE_DIVISOR_2
        );
    }

    function test_updatePoolListingData_RevertIf_BeneficiariesAdded()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.expectRevert(Errors.Vesting__PoolHasBeneficiaries.selector);
        _updatePoolListingData();
    }

    function test_updatePoolListingData_RevertIf_ListingDivisorZero()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__PercentageDivisorZero.selector);
        vm.prank(admin);
        vesting.updatePoolListingData(
            PRIMARY_POOL,
            LISTING_PERCENTAGE_DIVIDEND_2,
            0
        );
    }

    function test_updatePoolListingData_RevertIf_ListingPercentageOverflow()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__PercentageOverflow.selector);
        vm.prank(admin);
        vesting.updatePoolListingData(PRIMARY_POOL, 100, 51);
    }

    function test_updatePoolListingData_UpdatesListingPercentageDividendCorrectly()
        external
        approveAndAddPool
        updatePoolListingData
    {
        (uint16 dividend, ) = vesting.getPoolListingData(PRIMARY_POOL);
        assertEq(
            dividend,
            LISTING_PERCENTAGE_DIVIDEND_2,
            "Listing percentage dividend incorrect"
        );
    }

    function test_updatePoolListingData_UpdatesListingPercentageDivisorCorrectly()
        external
        approveAndAddPool
        updatePoolListingData
    {
        (, uint16 divisor) = vesting.getPoolListingData(PRIMARY_POOL);
        assertEq(
            divisor,
            LISTING_PERCENTAGE_DIVISOR_2,
            "Listing percentage divisor incorrect"
        );
    }

    function test_updatePoolListingData_EmitsVestingPoolUpdatedEvent()
        external
        approveAndAddPool
    {
        vm.expectEmit(address(vesting));
        emit PoolListingDataUpdated(
            PRIMARY_POOL,
            LISTING_PERCENTAGE_DIVIDEND_2,
            LISTING_PERCENTAGE_DIVISOR_2
        );

        _updatePoolListingData();
    }
}
