// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {NftSale_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftSaleUnit.t.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract NftSale_SetMaxLevel_Unit_Test is NftSale_Unit_Test {
    function test_setMaxLevel_RevertIf_AccessControlUnauthorizedAccount()
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
        sale.setMaxLevel(DEFAULT_LEVEL);
    }

    function test_setMaxLevel_RevertIf_InvalidMaxLevel() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Nft__InvalidMaxLevel.selector,
                DEFAULT_LEVEL
            )
        );
        vm.prank(admin);
        sale.setMaxLevel(DEFAULT_LEVEL);
    }

    function test_setMaxLevel_setsNewMaxLevel() external {
        uint16 newLevel = 10;
        vm.prank(admin);
        sale.setMaxLevel(newLevel);
        assertEq(sale.getMaxLevel(), newLevel, "New level not set");
    }
}
