// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_SetTotalPoolAmount_Unit_Test is Unit_Test {
    uint16 internal constant NEW_TOTAL_POOL_AMOUNT = 7;

    function test_setTotalPoolAmount_RevertIf_CallerNotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        staking.setTotalPoolAmount(NEW_TOTAL_POOL_AMOUNT);
    }

    function test_setTotalPoolAmount_RevertIf_LevelAmountZero() external {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Staking__ZeroAmount.selector)
        );
        vm.prank(admin);
        staking.setTotalPoolAmount(0);
    }

    function test_setTotalPoolAmount_SetsTotalPoolAmount() external {
        vm.prank(admin);
        staking.setTotalPoolAmount(NEW_TOTAL_POOL_AMOUNT);
        assertEq(
            staking.getTotalPools(),
            NEW_TOTAL_POOL_AMOUNT,
            "New total pool amount not set"
        );
    }

    function test_setTotalPoolAmount_EmitsTotalBandLevelsAmountSet() external {
        vm.expectEmit(address(staking));
        emit TotalPoolAmountSet(NEW_TOTAL_POOL_AMOUNT);

        vm.prank(admin);
        staking.setTotalPoolAmount(NEW_TOTAL_POOL_AMOUNT);
    }
}
