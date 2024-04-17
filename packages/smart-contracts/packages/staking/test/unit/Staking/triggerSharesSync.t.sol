// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_TriggerSharesSync_Unit_Test is Unit_Test {
    function test_triggerSharesSync_RevertIf_NotGelatoExecutor() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                GELATO_EXECUTOR_ROLE
            )
        );
        vm.prank(alice);
        staking.triggerSharesSync();
    }

    function test_triggerSharesSync_EmitsSharesSyncTriggeredEvent() external {
        vm.expectEmit(address(staking));
        emit SharesSyncTriggered();

        vm.prank(GELATO_EXECUTOR_ADDRESS);
        staking.triggerSharesSync();
    }
}
