// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {INftSale} from "../../../contracts/interfaces/INftSale.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {NftSale_Unit_Test} from "../NftSaleUnit.t.sol";

contract Nft_TransferFrom_Unit_Test is NftSale_Unit_Test {
    function test_transferFrom_RevertIf_AccessControlUnauthorizedAccount()
        external
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                MINTER_ROLE
            )
        );
        vm.prank(alice);
        nftContract.transferFrom(admin, alice, STARTER_TOKEN_ID);
    }

    function test_transferFrom_transferTokenOnlyWithMinterRole() external {
        assertEq(nftContract.balanceOf(admin), 0, "NFT pre-minted to admin");
        assertEq(nftContract.balanceOf(alice), 0, "NFT pre-minted to alice");

        vm.startPrank(admin);
        nftContract.safeMint(admin);

        assertEq(
            nftContract.balanceOf(admin),
            1,
            "NFT minted to incorrect address"
        );
        assertEq(
            nftContract.balanceOf(alice),
            0,
            "NFT minted to incorrect address"
        );

        nftContract.transferFrom(admin, alice, STARTER_TOKEN_ID);
        vm.stopPrank();

        assertEq(nftContract.balanceOf(admin), 0, "NFT transfer not complete");
        assertEq(nftContract.balanceOf(alice), 1, "NFT transfer not complete");
    }
}
