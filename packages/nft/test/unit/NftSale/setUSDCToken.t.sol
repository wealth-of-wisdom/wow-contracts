// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract NftSale_SetUSDCToken_Unit_Test is Unit_Test {
    IERC20 internal constant NEW_USDC_TOKEN = IERC20(address(100));

    function test_setUSDCToken_RevertIf_NotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        sale.setUSDCToken(NEW_USDC_TOKEN);
    }

    function test_setUSDCToken_RevertIf_NewTokenIsZero() external {
        vm.expectRevert(Errors.NftSale__ZeroAddress.selector);
        vm.prank(admin);
        sale.setUSDCToken(IERC20(ZERO_ADDRESS));
    }

    function test_setUSDCToken_SetsUSDCToken() external {
        vm.prank(admin);
        sale.setUSDCToken(NEW_USDC_TOKEN);
        assertEq(
            address(sale.getTokenUSDC()),
            address(NEW_USDC_TOKEN),
            "New token is incorrectly"
        );
    }

    function test_setUSDCToken_EmitsUSDCTokenSetEvent() external {
        vm.expectEmit(true, true, true, true);
        emit USDCTokenSet(NEW_USDC_TOKEN);

        vm.prank(admin);
        sale.setUSDCToken(NEW_USDC_TOKEN);
    }
}
