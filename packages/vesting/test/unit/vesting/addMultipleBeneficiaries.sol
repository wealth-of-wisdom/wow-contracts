// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Vesting_Unit_Test} from "./VestingUnit.t.sol";

contract Vesting_AddMultipleBeneficiaries_Unit_Test is Vesting_Unit_Test {
    function test_addMultipleBeneficiaries_RevertIf_ArraySizesDoNotMatch()
        external
    {
        tokenAmounts.push(BENEFICIARY_TOKEN_AMOUNT);

        vm.expectRevert(Errors.Vesting__ArraySizeMismatch.selector);
        vm.prank(admin);
        vesting.addMultipleBeneficiaries(
            PRIMARY_POOL,
            beneficiaries,
            tokenAmounts
        );
    }

    function test_addMultipleBeneficiaries_RevertIf_NotAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        vesting.addMultipleBeneficiaries(
            PRIMARY_POOL,
            beneficiaries,
            tokenAmounts
        );
    }

    function test_addMultipleBeneficiaries_RevertIf_PoolDoesNotExist()
        external
    {
        vm.expectRevert(Errors.Vesting__PoolDoesNotExist.selector);
        vm.prank(admin);
        vesting.addMultipleBeneficiaries(
            PRIMARY_POOL,
            beneficiaries,
            tokenAmounts
        );
    }

    function test_addMultipleBeneficiaries_RevertIf_BeneficiaryIsZeroAddress()
        external
        approveAndAddPool
    {
        beneficiaries[2] = ZERO_ADDRESS;

        vm.expectRevert(Errors.Vesting__ZeroAddress.selector);
        vm.prank(admin);
        vesting.addMultipleBeneficiaries(
            PRIMARY_POOL,
            beneficiaries,
            tokenAmounts
        );
    }

    function test_addMultipleBeneficiaries_RevertIf_TokenAmountIsZero()
        external
        approveAndAddPool
    {
        tokenAmounts[2] = 0;

        vm.expectRevert(Errors.Vesting__TokenAmountZero.selector);
        vm.prank(admin);
        vesting.addMultipleBeneficiaries(
            PRIMARY_POOL,
            beneficiaries,
            tokenAmounts
        );
    }

    function test_addMultipleBeneficiaries_RevertIf_TokenAmountExeedsTotalPoolAmount()
        external
        approveAndAddPool
    {
        tokenAmounts[2] = TOTAL_POOL_TOKEN_AMOUNT;

        vm.expectRevert(
            Errors.Vesting__TokenAmountExeedsTotalPoolAmount.selector
        );
        vm.prank(admin);
        vesting.addMultipleBeneficiaries(
            PRIMARY_POOL,
            beneficiaries,
            tokenAmounts
        );
    }

    function test_addMultipleBeneficiaries_AddsMultipleBeneficiaries()
        external
        approveAndAddPool
    {
        vm.prank(admin);
        vesting.addMultipleBeneficiaries(
            PRIMARY_POOL,
            beneficiaries,
            tokenAmounts
        );

        _checkBeneficiaryData(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT, 0);
        _checkBeneficiaryData(PRIMARY_POOL, bob, BENEFICIARY_TOKEN_AMOUNT, 0);
        _checkBeneficiaryData(PRIMARY_POOL, carol, BENEFICIARY_TOKEN_AMOUNT, 0);
    }
}
