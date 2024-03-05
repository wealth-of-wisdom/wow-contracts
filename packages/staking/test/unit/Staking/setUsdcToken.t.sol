// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_SetUsdcToken_Unit_Test is Unit_Test {
    IERC20 private newUsdcToken = IERC20(makeAddr("newUsdcToken"));

    function test_setUsdcToken_RevertIf_CallerNotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        staking.setUsdcToken(newUsdcToken);
    }

    function test_setUsdcToken_RevertIf_TokenAddressZero() external {
        vm.expectRevert(
            Errors.Staking__ZeroAddress.selector
        );
        vm.prank(admin);
        staking.setUsdcToken(IERC20(ZERO_ADDRESS));
    }

    function test_setUsdcToken_SetsUsdcToken() external {
        vm.prank(admin);
        staking.setUsdcToken(newUsdcToken);
        assertEq(
            address(staking.getTokenUSDC()),
            address(newUsdcToken),
            "New USDC token not set"
        );
    }

    function test_setUsdcToken_EmitsUsdcTokenSet() external {
        vm.expectEmit(address(staking));
        emit UsdcTokenSet(newUsdcToken);

        vm.prank(admin);
        staking.setUsdcToken(newUsdcToken);
    }
}
