// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
import {INft} from "@wealth-of-wisdom/nft/contracts/interfaces/INft.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {NftSale_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftSaleUnit.t.sol";

contract NftSale_SetNftContract_Unit_Test is NftSale_Unit_Test {
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
