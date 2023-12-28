// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Vesting_Unit_Test} from "./VestingUnit.t.sol";

contract Vesting_UpdateVestedStakedTokens_Unit_Test is Vesting_Unit_Test {
    function test_updateVestedStakedTokens_RevertIf_NotStaking() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                STAKING_ROLE
            )
        );
        vm.prank(alice);
        vesting.updateVestedStakedTokens(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_TOKEN_AMOUNT,
            true
        );
    }

    function test_updateVestedStakedTokens_RevertIf_PoolDoesNotExist()
        external
    {
        vm.expectRevert(Errors.Vesting__PoolDoesNotExist.selector);
        vm.prank(staking);
        vesting.updateVestedStakedTokens(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_TOKEN_AMOUNT,
            true
        );
    }

    function test_updateVestedStakedTokens_RevertIf_BeneficiaryDoesNotExist()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__BeneficiaryDoesNotExist.selector);
        vm.prank(staking);
        vesting.updateVestedStakedTokens(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_TOKEN_AMOUNT,
            true
        );
    }

    function test_updateVestedStakedTokens_RevertIf_TokenAmountZero()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.expectRevert(Errors.Vesting__TokenAmountZero.selector);
        vm.prank(staking);
        vesting.updateVestedStakedTokens(PRIMARY_POOL, alice, 0, true);
    }

    function test_updateVestedStakedTokens_RevertIf_NotEnoughVestedTokensForStaking()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.expectRevert(
            Errors.Vesting__NotEnoughVestedTokensForStaking.selector
        );
        vm.prank(staking);
        vesting.updateVestedStakedTokens(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_TOKEN_AMOUNT + 1 wei,
            true
        );
    }

    function test_updateVestedStakedTokens_IncreasesStakedTokenAmount()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.prank(staking);
        vesting.updateVestedStakedTokens(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_TOKEN_AMOUNT,
            true
        );

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            beneficiary.stakedTokenAmount,
            BENEFICIARY_TOKEN_AMOUNT,
            "Staked amount is incorrect"
        );
    }

    function test_updateVestedStakedTokens_RevertIf_NotEnoughStakedTokens()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.expectRevert(Errors.Vesting__NotEnoughStakedTokens.selector);
        vm.prank(staking);
        vesting.updateVestedStakedTokens(PRIMARY_POOL, alice, 1 wei, false);
    }

    function test_updateVestedStakedTokens_DecreasesStakedTokenAmount()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.startPrank(staking);
        vesting.updateVestedStakedTokens(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_TOKEN_AMOUNT,
            true
        );

        vesting.updateVestedStakedTokens(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_TOKEN_AMOUNT,
            false
        );
        vm.stopPrank();

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            beneficiary.stakedTokenAmount,
            0,
            "Staked amount is incorrect"
        );
    }

    function test_updateVestedStakedTokens_EmitsStakedTokensUpdatedEventWhenStaking()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.expectEmit(true, true, true, true);
        emit StakedTokensUpdated(PRIMARY_POOL, BENEFICIARY_TOKEN_AMOUNT, true);

        vm.prank(staking);
        vesting.updateVestedStakedTokens(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_TOKEN_AMOUNT,
            true
        );
    }

    function test_updateVestedStakedTokens_EmitsStakedTokensUpdatedEventWhenUnstaking()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.prank(staking);
        vesting.updateVestedStakedTokens(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_TOKEN_AMOUNT,
            true
        );

        vm.expectEmit(true, true, true, true);
        emit StakedTokensUpdated(
            PRIMARY_POOL,
            BENEFICIARY_TOKEN_AMOUNT - 10 wei,
            false
        );

        vm.prank(staking);
        vesting.updateVestedStakedTokens(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_TOKEN_AMOUNT - 10 wei,
            false
        );
    }
}
