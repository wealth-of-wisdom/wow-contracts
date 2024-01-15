// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {NftSale_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftSaleUnit.t.sol";

contract NftSale_SetUSDTToken_Unit_Test is NftSale_Unit_Test {
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

    function test_setUSDTToken_SetsUSDTToken() external {
        vm.prank(admin);
        sale.setUSDTToken(NEW_USDT_TOKEN);
        assertEq(
            address(sale.getTokenUSDT()),
            address(NEW_USDT_TOKEN),
            "New token is incorrectly"
        );
    }

    function test_setUSDTTokendd_EmitsPromotionalVestingPIDSetEvent()
        external
    {
        vm.expectEmit(true, true, true, true);
        emit USDTTokenSet(NEW_USDT_TOKEN);

        vm.prank(admin);
        sale.setUSDTToken(NEW_USDT_TOKEN);
    }
}
