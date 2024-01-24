// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract NftSale_SetUSDTToken_Unit_Test is Unit_Test {
    IERC20 internal constant NEW_USDT_TOKEN = IERC20(address(100));

    function test_setUSDTToken_RevertIf_NotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        sale.setUSDTToken(NEW_USDT_TOKEN);
    }

    function test_setUSDTToken_RevertIf_NewTokenIsZero() external {
        vm.expectRevert(Errors.NftSale__ZeroAddress.selector);
        vm.prank(admin);
        sale.setUSDTToken(IERC20(ZERO_ADDRESS));
    }

    function test_setUSDTToken_SetsUSDTToken() external {
        vm.prank(admin);
        sale.setUSDTToken(NEW_USDT_TOKEN);
        assertEq(
            address(sale.getTokenUSDT()),
            address(NEW_USDT_TOKEN),
            "New token is incorrectly"
        );
    }

    function test_setUSDTTokendd_EmitsUSDTTokenSetEvent() external {
        vm.expectEmit(true, true, true, true);
        emit USDTTokenSet(NEW_USDT_TOKEN);

        vm.prank(admin);
        sale.setUSDTToken(NEW_USDT_TOKEN);
    }
}
