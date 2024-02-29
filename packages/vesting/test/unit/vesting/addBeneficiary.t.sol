// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Vesting_Unit_Test} from "../VestingUnit.t.sol";

contract Vesting_AddBeneficiary_Unit_Test is Vesting_Unit_Test {
    function test_addBeneficiary_RevertIf_CallerNotAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                BENEFICIARIES_MANAGER_ROLE
            )
        );
        vm.prank(alice);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
    }

    function test_addBeneficiary_RevertIf_PoolDoesNotExist() external {
        vm.expectRevert(Errors.Vesting__PoolDoesNotExist.selector);
        vm.prank(admin);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
    }

    function test_addBeneficiary_RevertIf_BeneficiaryIsZeroAddress()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__ZeroAddress.selector);
        vm.prank(admin);
        vesting.addBeneficiary(
            PRIMARY_POOL,
            ZERO_ADDRESS,
            BENEFICIARY_TOKEN_AMOUNT
        );
    }

    function test_addBeneficiary_RevertIf_TokenAmountIsZero()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__TokenAmountZero.selector);
        vm.prank(admin);
        vesting.addBeneficiary(PRIMARY_POOL, alice, 0);
    }

    function test_addBeneficiary_RevertIf_TokenAmountExeedsTotalPoolAmount()
        external
        approveAndAddPool
    {
        vm.expectRevert(
            Errors.Vesting__TokenAmountExeedsTotalPoolAmount.selector
        );
        vm.prank(admin);
        vesting.addBeneficiary(
            PRIMARY_POOL,
            alice,
            TOTAL_POOL_TOKEN_AMOUNT + 1 wei
        );
    }

    function test_addBeneficiary_IncreasesDedicatedPoolTokenAmountWithOneBeneficiary()
        external
        approveAndAddPool
    {
        vm.prank(admin);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);

        (, , , uint256 lockedAmount) = vesting.getGeneralPoolData(PRIMARY_POOL);
        assertEq(
            lockedAmount,
            BENEFICIARY_TOKEN_AMOUNT,
            "Incorrect locked amount"
        );
    }

    function test_addBeneficiary_IncreasesDedicatedPoolTokenAmountWithTwoBeneficiaries()
        external
        approveAndAddPool
    {
        vm.startPrank(admin);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
        vesting.addBeneficiary(PRIMARY_POOL, bob, BENEFICIARY_TOKEN_AMOUNT);
        vm.stopPrank();

        (, , , uint256 lockedAmount) = vesting.getGeneralPoolData(PRIMARY_POOL);
        assertEq(
            lockedAmount,
            BENEFICIARY_TOKEN_AMOUNT * 2,
            "Incorrect locked amount"
        );
    }

    function test_addBeneficiary_IncreasesUserTotalTokenAmountWhenAddingUserForTheFirstTime()
        external
        approveAndAddPool
    {
        vm.prank(admin);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            beneficiary.totalTokenAmount,
            BENEFICIARY_TOKEN_AMOUNT,
            "Incorrect user total token amount"
        );
    }

    function test_addBeneficiary_IncreasesUserTotalTokenAmountWhenAddingUserForTheSecondTime()
        external
        approveAndAddPool
    {
        vm.startPrank(admin);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
        vm.stopPrank();

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            beneficiary.totalTokenAmount,
            BENEFICIARY_TOKEN_AMOUNT * 2,
            "Incorrect user total token amount"
        );
    }

    function test_addBeneficiary_SetsUserListingTokenAmountWhenAddingUserForTheFirstTime()
        external
        approveAndAddPool
    {
        vm.prank(admin);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            beneficiary.listingTokenAmount,
            (BENEFICIARY_TOKEN_AMOUNT * LISTING_PERCENTAGE_DIVIDEND) /
                LISTING_PERCENTAGE_DIVISOR,
            "Incorrect user listing token amount"
        );
    }

    function test_addBeneficiary_SetsUserListingTokenAmountWhenAddingUserForTheSecondTime()
        external
        approveAndAddPool
    {
        vm.startPrank(admin);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
        vm.stopPrank();

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            beneficiary.listingTokenAmount,
            (BENEFICIARY_TOKEN_AMOUNT * 2 * LISTING_PERCENTAGE_DIVIDEND) /
                LISTING_PERCENTAGE_DIVISOR,
            "Incorrect user listing token amount"
        );
    }

    function test_addBeneficiary_SetsUserCliffTokenAmountWhenAddingUserForTheFirstTime()
        external
        approveAndAddPool
    {
        vm.prank(admin);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            beneficiary.cliffTokenAmount,
            (BENEFICIARY_TOKEN_AMOUNT * CLIFF_PERCENTAGE_DIVIDEND) /
                CLIFF_PERCENTAGE_DIVISOR,
            "Incorrect user cliff token amount"
        );
    }

    function test_addBeneficiary_SetsUserCliffTokenAmountWhenAddingUserForTheSecondTime()
        external
        approveAndAddPool
    {
        vm.startPrank(admin);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
        vm.stopPrank();

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            beneficiary.cliffTokenAmount,
            (BENEFICIARY_TOKEN_AMOUNT * 2 * CLIFF_PERCENTAGE_DIVIDEND) /
                CLIFF_PERCENTAGE_DIVISOR,
            "Incorrect user cliff token amount"
        );
    }

    function test_addBeneficiary_SetsUserVestedTokenAmountWhenAddingUserForTheFirstTime()
        external
        approveAndAddPool
    {
        vm.prank(admin);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            beneficiary.vestedTokenAmount,
            BENEFICIARY_TOKEN_AMOUNT -
                beneficiary.listingTokenAmount -
                beneficiary.cliffTokenAmount,
            "Incorrect user vested token amount"
        );
    }

    function test_addBeneficiary_SetsUserVestedTokenAmountWhenAddingUserForTheSecondTime()
        external
        approveAndAddPool
    {
        vm.startPrank(admin);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
        vm.stopPrank();

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            beneficiary.vestedTokenAmount,
            (BENEFICIARY_TOKEN_AMOUNT * 2) -
                beneficiary.listingTokenAmount -
                beneficiary.cliffTokenAmount,
            "Incorrect user vested token amount"
        );
    }

    function test_addBeneficiary_EmitsBeneficiaryAddedEvent()
        external
        approveAndAddPool
    {
        vm.expectEmit(address(vesting));
        emit BeneficiaryAdded(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);

        vm.prank(admin);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
    }
}
