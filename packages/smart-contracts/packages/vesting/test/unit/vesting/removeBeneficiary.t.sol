// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IStaking} from "@wealth-of-wisdom/staking/contracts/interfaces/IStaking.sol";
import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Vesting_RemoveBeneficiary_Unit_Test is Unit_Test {
    uint256 calculatedUnlockedPoolTokens =
        TOTAL_POOL_TOKEN_AMOUNT -
            (BENEFICIARY_TOKEN_AMOUNT * CLIFF_PERCENTAGE_DIVIDEND) /
            CLIFF_PERCENTAGE_DIVISOR -
            (BENEFICIARY_TOKEN_AMOUNT * LISTING_PERCENTAGE_DIVIDEND) /
            LISTING_PERCENTAGE_DIVISOR;

    function test_removeBeneficiary_RevertIf_NotAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);
    }

    function test_removeBeneficiary_RevertIf_PoolDoesNotExist() external {
        vm.expectRevert(Errors.Vesting__PoolDoesNotExist.selector);
        vm.prank(admin);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);
    }

    function test_removeBeneficiary_RevertIf_BeneficiaryDoesNotExist()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__BeneficiaryDoesNotExist.selector);
        vm.prank(admin);
        vesting.removeBeneficiary(PRIMARY_POOL, bob);
    }

    function test_removeBeneficiary_RevertIf_BeneficiaryIsZeroAddress()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__BeneficiaryDoesNotExist.selector);
        vm.prank(admin);
        vesting.removeBeneficiary(PRIMARY_POOL, address(0));
    }

    function test_removeBeneficiary_RemovesTotalUserAmountFromDedicatedAmountWhenNoTokensWereStakedOrClaimed()
        external
        approveAndAddPool
        addBeneficiary(alice)
        addBeneficiary(bob)
    {
        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(admin);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);

        (, , , uint256 dedicatedAmount) = vesting.getGeneralPoolData(
            PRIMARY_POOL
        );
        assertEq(
            dedicatedAmount,
            BENEFICIARY_TOKEN_AMOUNT,
            "Dedicated amount is incorrect"
        );
    }

    function test_removeBeneficiary_DoesNotChangeDedicatedAmountWhenTokensAreClaimedButNotStaked()
        external
        approveAndAddPool
        addBeneficiary(alice)
        addBeneficiary(bob)
    {
        vm.warp(VESTING_END_DATE + 1 minutes);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);

        vm.prank(admin);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);

        (, , , uint256 dedicatedAmount) = vesting.getGeneralPoolData(
            PRIMARY_POOL
        );
        assertEq(
            dedicatedAmount,
            BENEFICIARY_TOKEN_AMOUNT * 2,
            "Dedicated amount is incorrect"
        );
    }

    function test_removeBeneficiary_DeletesUserWhenNoTokensAreStakedOrClaimed()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(admin);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);

        IVesting.Beneficiary memory aliceBeneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );

        assertBeneficiaryData(aliceBeneficiary, 0, 0, 0);
    }

    function test_removeBeneficiary_DeletesUserWhenTokensAreStaked()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE);
        vm.prank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FIX,
            BAND_LEVEL_1,
            MONTH_1,
            PRIMARY_POOL
        );

        vm.prank(admin);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);

        IVesting.Beneficiary memory aliceBeneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertBeneficiaryData(aliceBeneficiary, 0, 0, 0);
    }

    function test_removeBeneficiary_DeletesUserWhenTokensAreClaimed()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);

        vm.prank(admin);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);

        IVesting.Beneficiary memory aliceBeneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertBeneficiaryData(aliceBeneficiary, 0, 0, 0);
    }

    function test_removeBeneficiary_CallsStakingWhenNoTokensAreStakedOrClaimed()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(LISTING_DATE + 1 minutes);
        vm.expectCall(
            address(staking),
            abi.encodeWithSelector(IStaking.deleteVestingUser.selector, alice)
        );
        vm.prank(admin);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);
    }

    function test_removeBeneficiary_CallsStakingWhenTokensAreStaked()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE);
        vm.prank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FIX,
            BAND_LEVEL_1,
            MONTH_1,
            PRIMARY_POOL
        );

        vm.expectCall(
            address(staking),
            abi.encodeWithSelector(IStaking.deleteVestingUser.selector, alice)
        );
        vm.prank(admin);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);
    }

    function test_removeBeneficiary_CallsStakingWhenTokensAreClaimed()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(CLIFF_END_DATE);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);

        vm.expectCall(
            address(staking),
            abi.encodeWithSelector(IStaking.deleteVestingUser.selector, alice)
        );
        vm.prank(admin);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);
    }

    function test_removeBeneficiary_EmitsBeneficiaryRemovedEvent()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(LISTING_DATE + 1 minutes);
        vm.expectEmit(true, true, true, true);
        emit BeneficiaryRemoved(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);

        vm.prank(admin);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);
    }
}
