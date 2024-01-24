// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INft} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract NftSale_SetNftContract_Unit_Test is Unit_Test {
    INft internal constant newNft = INft(address(100));

    function test_setNftContract_RevertIf_NotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        sale.setNftContract(newNft);
    }

    function test_setNftContract_RevertIf_ZeroAddress() external {
        vm.expectRevert(Errors.NftSale__ZeroAddress.selector);
        vm.prank(admin);
        sale.setNftContract(INft(ZERO_ADDRESS));
    }

    function test_setNftContract_SetsNftContract() external {
        vm.prank(admin);
        sale.setNftContract(newNft);
        assertEq(
            address(sale.getNftContract()),
            address(newNft),
            "New NFT contract incorrect"
        );
    }

    function test_setNftContract_EmitsNftContractSetEvent() external {
        vm.expectEmit(true, true, true, true);
        emit NftContractSet(newNft);

        vm.prank(admin);
        sale.setNftContract(newNft);
    }
}
