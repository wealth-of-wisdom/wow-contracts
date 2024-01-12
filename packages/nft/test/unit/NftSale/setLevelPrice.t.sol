// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {NftSale_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftSaleUnit.t.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract NftSale_SetLevelPrice_Unit_Test is NftSale_Unit_Test {
    uint256 internal constant NEW_USD_PRICE = 50 * USD_DECIMALS;

    function test_setLevelPrice_RevertIf_AccessControlUnauthorizedAccount()
        external
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        sale.setLevelPrice(DEFAULT_LEVEL_2, NEW_USD_PRICE);
    }

    function test_setLevelPrice_RevertIf_InvalidMaxLevel() external {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.NftSale__InvalidLevel.selector, 0)
        );
        vm.prank(admin);
        sale.setLevelPrice(0, NEW_USD_PRICE);
    }

    function test_setLevelPrice_RevertIf_PassedZeroAmount() external {
        vm.expectRevert(Errors.NftSale__PassedZeroAmount.selector);
        vm.prank(admin);
        sale.setLevelPrice(DEFAULT_LEVEL_2, 0);
    }

    function test_setLevelPrice_setsNewLevelPrice() external {
        vm.prank(admin);
        sale.setLevelPrice(DEFAULT_LEVEL_2, NEW_USD_PRICE);
        assertEq(
            sale.getLevelPriceInUSD(DEFAULT_LEVEL_2),
            NEW_USD_PRICE,
            "New price not set"
        );
    }
}
