// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVesting, IVestingEvents} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Vesting_UnstakeVestedTokens_Unit_Test is Unit_Test {
    function test_unstakeVestedTokens_RevertIf_Vesting__BeneficiaryDoesNotExist()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.expectRevert(Errors.Vesting__BeneficiaryDoesNotExist.selector);
        vm.prank(bob);
        vesting.unstakeVestedTokens(BAND_ID_0);
    }

    function test_unstakeVestedTokens_ShouldUnstakeVestedTokens_AndUpdateData()
        external
        approveAndAddPool
        addBeneficiary(alice)
        stakeVestedTokens(alice)
    {
        vm.startPrank(alice);
        vm.expectCall(
            address(vesting),
            abi.encodeWithSelector(
                IVesting.unstakeVestedTokens.selector,
                BAND_ID_0
            )
        );
        vesting.unstakeVestedTokens(BAND_ID_0);
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

    function test_unstakeVestedTokens_EmitsVestedTokensUnstaked()
        external
        approveAndAddPool
        addBeneficiary(alice)
        stakeVestedTokens(alice)
    {
        vm.startPrank(alice);
        vm.expectEmit(address(vesting));
        emit VestedTokensUnstaked(PRIMARY_POOL, alice, BAND_1_PRICE, BAND_ID_0);
        vesting.unstakeVestedTokens(BAND_ID_0);
        vm.stopPrank();
    }
}
