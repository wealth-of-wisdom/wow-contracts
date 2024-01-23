// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_SafeTransferFrom_Unit_Test is Unit_Test {
    function test_safeTransferFrom_RevertIf_NotWhitelistedSender()
        external
        mintLevel2NftForAlice
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                WHITELISTED_SENDER_ROLE
            )
        );
        vm.prank(alice);
        nft.safeTransferFrom(alice, bob, NFT_TOKEN_ID_0);
    }

    function test_safeTransferFrom_TransfersNftSuccessfully()
        external
        mintLevel2NftForAlice
    {
        assertEq(nft.balanceOf(alice), 1, "NFT not minted to alice");
        assertEq(nft.balanceOf(bob), 0, "NFT minted to bob");

        vm.prank(admin);
        nft.grantRole(WHITELISTED_SENDER_ROLE, alice);

        vm.prank(alice);
        nft.safeTransferFrom(alice, bob, NFT_TOKEN_ID_0);

        assertEq(nft.balanceOf(alice), 0, "Alice balance incorrect");
        assertEq(nft.balanceOf(bob), 1, "Bob balance incorrect");
    }
}
