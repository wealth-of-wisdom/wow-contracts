// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVesting, IVestingEvents} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Vesting_Unit_Test} from "../VestingUnit.t.sol";

contract Vesting_UnstakeVestedTokens_Unit_Test is Vesting_Unit_Test {
    function test_unstakeVestedTokens_RevertIf_PoolDoesNotExist() external {
        vm.expectRevert(Errors.Vesting__PoolDoesNotExist.selector);
        vm.prank(alice);
        vesting.unstakeVestedTokens(
            BAND_ID_0,
            PRIMARY_POOL,
            alice,
            BENEFICIARY_TOKEN_AMOUNT
        );
    }

    function test_unstakeVestedTokens_RevertIf_Vesting__BeneficiaryDoesNotExist()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.expectRevert(Errors.Vesting__BeneficiaryDoesNotExist.selector);
        vm.prank(alice);
        vesting.unstakeVestedTokens(
            BAND_ID_0,
            PRIMARY_POOL,
            bob,
            BENEFICIARY_TOKEN_AMOUNT
        );
    }

    function test_unstakeVestedTokens_RevertIf_TokenAmountZero()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.expectRevert(Errors.Vesting__TokenAmountZero.selector);
        vm.prank(alice);
        vesting.unstakeVestedTokens(BAND_ID_0, PRIMARY_POOL, alice, 0);
    }

    function test_unstakeVestedTokens_RevertIf_UnstakingTooManyTokens()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.expectRevert(Errors.Vesting__UnstakingTooManyTokens.selector);
        vm.prank(alice);
        vesting.unstakeVestedTokens(
            BAND_ID_0,
            PRIMARY_POOL,
            alice,
            BENEFICIARY_TOKEN_AMOUNT + 1
        );
    }

    function test_unstakeVestedTokens_ShouldUnstakeVestedTokens_AndUpdateData()
        external
        approveAndAddPool
        addBeneficiary(alice)
        stakeVestedTokens(alice)
    {
        vm.startPrank(alice);
        vesting.unstakeVestedTokens(
            BAND_ID_0,
            PRIMARY_POOL,
            alice,
            BENEFICIARY_TOKEN_AMOUNT
        );
        vm.stopPrank();
        IVesting.Beneficiary memory user = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(user.stakedTokenAmount, 0, "Staked tokens not set");
        assertEq(
            user.totalTokenAmount,
            BENEFICIARY_TOKEN_AMOUNT,
            "Token amount changed"
        );
    }

    function test_unstakeVestedTokens_EmitsStakedTokensUpdated()
        external
        approveAndAddPool
        addBeneficiary(alice)
        stakeVestedTokens(alice)
    {
        vm.startPrank(alice);
        vm.expectEmit(address(vesting));
        emit StakedTokensUpdated(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
        vesting.unstakeVestedTokens(
            BAND_ID_0,
            PRIMARY_POOL,
            alice,
            BENEFICIARY_TOKEN_AMOUNT
        );
        vm.stopPrank();
    }
}
