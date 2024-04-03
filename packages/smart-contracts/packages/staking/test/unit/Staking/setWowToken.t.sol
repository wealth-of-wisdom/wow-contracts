// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_SetWowToken_Unit_Test is Unit_Test {
    IERC20 private newWowToken = IERC20(makeAddr("newWowToken"));

    function test_setWowToken_RevertIf_CallerNotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        staking.setWowToken(newWowToken);
    }

    function test_setWowToken_RevertIf_TokenAddressZero() external {
        vm.expectRevert(
            Errors.Staking__ZeroAddress.selector
        );
        vm.prank(admin);
        staking.setWowToken(IERC20(ZERO_ADDRESS));
    }

    function test_setWowToken_SetsWowToken() external {
        vm.prank(admin);
        staking.setWowToken(newWowToken);
        assertEq(
            address(staking.getTokenWOW()),
            address(newWowToken),
            "New WOW token not set"
        );
    }

    function test_setWowToken_EmitsWowTokenSet() external {
        vm.expectEmit(address(staking));
        emit WowTokenSet(newWowToken);

        vm.prank(admin);
        staking.setWowToken(newWowToken);
    }
}
