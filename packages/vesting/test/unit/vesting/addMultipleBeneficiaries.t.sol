// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Vesting_Unit_Test} from "../VestingUnit.t.sol";

contract Vesting_AddMultipleBeneficiaries_Unit_Test is Vesting_Unit_Test {
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

    function test_addMultipleBeneficiaries_RevertIf_ArraySizesDoNotMatch()
        external
        approveAndAddPool
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

        IVesting.Beneficiary memory aliceBeneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        IVesting.Beneficiary memory bobBeneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            bob
        );
        IVesting.Beneficiary memory carolBeneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            carol
        );

        // Validate beneficiaries
        assertBeneficiaryData(aliceBeneficiary, BENEFICIARY_TOKEN_AMOUNT, 0);
        assertBeneficiaryData(bobBeneficiary, BENEFICIARY_TOKEN_AMOUNT, 0);
        assertBeneficiaryData(carolBeneficiary, BENEFICIARY_TOKEN_AMOUNT, 0);

        // Validate pool
        assertGeneralPoolData(
            vesting,
            PRIMARY_POOL,
            BENEFICIARY_TOKEN_AMOUNT * 3
        );
    }
}
