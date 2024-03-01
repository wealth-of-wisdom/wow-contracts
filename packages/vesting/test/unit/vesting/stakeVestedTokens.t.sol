// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVesting, IVestingEvents} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Vesting_Unit_Test} from "../VestingUnit.t.sol";

contract Vesting_StakeVestedTokens_Unit_Test is Vesting_Unit_Test {
    function test_stakeVestedTokens_RevertIf_PoolDoesNotExist() external {
        vm.expectRevert(Errors.Vesting__PoolDoesNotExist.selector);
        vm.prank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FLEXI,
            BAND_LEVEL_2,
            DEFAULT_STAKING_MONTH_AMOUNT,
            PRIMARY_POOL,
            BENEFICIARY_TOKEN_AMOUNT
        );
    }

    function test_stakeVestedTokens_RevertIf_NotBeneficiary()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__NotBeneficiary.selector);
        vm.prank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FLEXI,
            BAND_LEVEL_2,
            DEFAULT_STAKING_MONTH_AMOUNT,
            PRIMARY_POOL,
            BENEFICIARY_TOKEN_AMOUNT
        );
    }

    function test_stakeVestedTokens_RevertIf_TokenAmountZero()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.expectRevert(Errors.Vesting__TokenAmountZero.selector);
        vm.prank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FLEXI,
            BAND_LEVEL_2,
            DEFAULT_STAKING_MONTH_AMOUNT,
            PRIMARY_POOL,
            0
        );
    }

    function test_stakeVestedTokens_RevertIf_NotEnoughVestedTokensForStaking()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.expectRevert(
            Errors.Vesting__NotEnoughVestedTokensForStaking.selector
        );
        vm.prank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FLEXI,
            BAND_LEVEL_2,
            DEFAULT_STAKING_MONTH_AMOUNT,
            PRIMARY_POOL,
            BENEFICIARY_TOKEN_AMOUNT + 1
        );
    }

    function test_stakeVestedTokens_ShouldStakeVestedTokens_AndUpdateData()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.startPrank(alice);
        vm.expectCall(
            address(vesting),
            abi.encodeWithSelector(
                IVesting.stakeVestedTokens.selector,
                STAKING_TYPE_FLEXI,
                BAND_LEVEL_1,
                0,
                PRIMARY_POOL,
                BENEFICIARY_TOKEN_AMOUNT
            )
        );
        vesting.stakeVestedTokens(
            STAKING_TYPE_FLEXI,
            BAND_LEVEL_1,
            0,
            PRIMARY_POOL,
            BENEFICIARY_TOKEN_AMOUNT
        );
        vm.stopPrank();
        IVesting.Beneficiary memory user = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            user.stakedTokenAmount,
            BENEFICIARY_TOKEN_AMOUNT,
            "Staked tokens not set"
        );
        assertEq(
            user.totalTokenAmount,
            BENEFICIARY_TOKEN_AMOUNT,
            "Token amount changed"
        );
    }

    function test_stakeVestedTokens_EmitsVestedTokensStaked()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.startPrank(alice);
        vm.expectEmit(address(vesting));
        emit VestedTokensStaked(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FLEXI,
            BAND_LEVEL_1,
            0,
            PRIMARY_POOL,
            BENEFICIARY_TOKEN_AMOUNT
        );
        vm.stopPrank();
    }
}
