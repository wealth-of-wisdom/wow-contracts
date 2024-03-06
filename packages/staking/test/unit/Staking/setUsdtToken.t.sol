// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_SetUsdtToken_Unit_Test is Unit_Test {
    IERC20 private newUsdtToken = IERC20(makeAddr("newUsdtToken"));

    function test_setUsdtToken_RevertIf_CallerNotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        staking.setUsdtToken(newUsdtToken);
    }

    function test_setUsdtToken_RevertIf_TokenAddressZero() external {
        vm.expectRevert(
            Errors.Staking__ZeroAddress.selector
        );
        vm.prank(admin);
        staking.setUsdtToken(IERC20(ZERO_ADDRESS));
    }

    function test_setUsdtToken_SetsUsdtToken() external {
        vm.prank(admin);
        staking.setUsdtToken(newUsdtToken);
        assertEq(
            address(staking.getTokenUSDT()),
            address(newUsdtToken),
            "New USDT token not set"
        );
    }

    function test_setUsdtToken_EmitsUsdtTokenSet() external {
        vm.expectEmit(address(staking));
        emit UsdtTokenSet(newUsdtToken);

        vm.prank(admin);
        staking.setUsdtToken(newUsdtToken);
    }
}
