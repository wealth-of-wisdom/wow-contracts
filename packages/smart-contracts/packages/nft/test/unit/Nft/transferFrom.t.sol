// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {INft} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_TransferFrom_Unit_Test is Unit_Test {
    modifier grantWhitelistedSenderRoles() {
        vm.startPrank(admin);
        nft.grantRole(WHITELISTED_SENDER_ROLE, alice);
        nft.grantRole(WHITELISTED_SENDER_ROLE, bob);
        nft.grantRole(WHITELISTED_SENDER_ROLE, carol);
        vm.stopPrank();
        _;
    }

    function test_transferFrom_RevertIf_NotWhitelistedSender()
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
        nft.transferFrom(alice, bob, NFT_TOKEN_ID_0);
    }

    function test_transferFrom_RevertIf_UserOwnsActiveNft()
        external
        grantWhitelistedSenderRoles
        mintLevel2NftForAlice
    {
        vm.prank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, true);

        vm.startPrank(bob);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_2, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_1, true);

        vm.expectRevert(Errors.Nft__UserOwnsActiveNft.selector);
        nft.transferFrom(bob, alice, NFT_TOKEN_ID_1);
        vm.stopPrank();
    }

    function test_transferFrom_TransfersNftSuccessfully()
        external
        grantWhitelistedSenderRoles
        mintLevel2NftForAlice
    {
        assertEq(nft.balanceOf(alice), 1, "NFT not minted to alice");
        assertEq(nft.balanceOf(bob), 0, "NFT minted to bob");

        vm.prank(alice);
        nft.transferFrom(alice, bob, NFT_TOKEN_ID_0);

        assertEq(nft.balanceOf(alice), 0, "Alice balance incorrect");
        assertEq(nft.balanceOf(bob), 1, "Bob balance incorrect");
    }

    function test_transferFrom_RevertIf_SenderAndReceiverDoNotHaveNfts()
        external
        grantWhitelistedSenderRoles
    {
        vm.startPrank(carol);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_2, tokenUSDT);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Errors.ERC721IncorrectOwner.selector,
                alice,
                NFT_TOKEN_ID_0,
                carol
            )
        );
        nft.transferFrom(alice, bob, NFT_TOKEN_ID_0);
        vm.stopPrank();
    }

    function test_transferFrom_TransferCompletes_SenderAndReceiverHaveInactiveNfts()
        external
        grantWhitelistedSenderRoles
    {
        vm.startPrank(bob);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_2, tokenUSDT);
        vm.stopPrank();

        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_3, tokenUSDT);
        nft.transferFrom(alice, bob, NFT_TOKEN_ID_1);
        vm.stopPrank();

        assertEq(nft.balanceOf(alice), 0, "Alice balance incorrect");
        assertEq(nft.balanceOf(bob), 2, "Bob balance incorrect");
    }

    function test_transferFrom_RevertIf_SenderAndReceiverHaveActiveNfts()
        external
        grantWhitelistedSenderRoles
    {
        vm.startPrank(bob);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_2, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        vm.stopPrank();

        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_3, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_1, true);

        vm.expectRevert(Errors.Nft__UserOwnsActiveNft.selector);
        nft.transferFrom(alice, bob, NFT_TOKEN_ID_1);
        vm.stopPrank();
    }

    function test_transferFrom_TransferCompletes_SenderHasInactiveAndReceiverDoesNotHaveNft()
        external
        grantWhitelistedSenderRoles
    {
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_2, tokenUSDT);
        vm.stopPrank();

        assertEq(nft.balanceOf(bob), 0, "Bob balance incorrect");

        vm.prank(alice);
        nft.transferFrom(alice, bob, NFT_TOKEN_ID_0);

        assertEq(nft.balanceOf(alice), 0, "Alice balance incorrect");
        assertEq(nft.balanceOf(bob), 1, "Bob balance incorrect");
    }

    function test_transferFrom_RevertIf_ReceiverHasInactiveAndSenderDoesNotHaveNft()
        external
        grantWhitelistedSenderRoles
    {
        vm.startPrank(bob);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_2, tokenUSDT);
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Errors.ERC721InsufficientApproval.selector,
                alice,
                NFT_TOKEN_ID_0
            )
        );
        vm.prank(alice);
        nft.transferFrom(alice, bob, NFT_TOKEN_ID_0);
    }

    function test_transferFrom_TransferCompletes_SenderHasActiveAndReceiverDoesNotHaveNft()
        external
        grantWhitelistedSenderRoles
    {
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_2, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        vm.stopPrank();

        assertEq(nft.balanceOf(bob), 0, "Bob balance incorrect");

        vm.prank(alice);
        nft.transferFrom(alice, bob, NFT_TOKEN_ID_0);

        assertEq(nft.balanceOf(alice), 0, "Alice balance incorrect");
        assertEq(nft.balanceOf(bob), 1, "Bob balance incorrect");
    }

    function test_transferFrom_RevertIf_ReceiverHasActiveAndSenderDoesNotHaveNft()
        external
        grantWhitelistedSenderRoles
    {
        vm.startPrank(bob);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_2, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        vm.stopPrank();

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Errors.ERC721InsufficientApproval.selector,
                alice,
                NFT_TOKEN_ID_0
            )
        );
        vm.prank(alice);
        nft.transferFrom(alice, bob, NFT_TOKEN_ID_0);
    }

    function test_transferFrom_TransferCompletes_SenderHasActiveAndReceiverHasInactiveNft()
        external
        grantWhitelistedSenderRoles
    {
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_2, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_3, tokenUSDT);
        vm.stopPrank();

        assertEq(nft.balanceOf(alice), 1, "Alice balance incorrect");
        assertEq(nft.balanceOf(bob), 1, "Bob balance incorrect");

        vm.prank(alice);
        nft.transferFrom(alice, bob, NFT_TOKEN_ID_0);

        assertEq(nft.balanceOf(alice), 0, "Alice balance incorrect");
        assertEq(nft.balanceOf(bob), 2, "Bob balance incorrect");
    }

    function test_transferFrom_TransferCompletes_ReceiverHasActiveAndSenderHasInactiveNft()
        external
        grantWhitelistedSenderRoles
    {
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_2, tokenUSDT);
        vm.stopPrank();

        vm.startPrank(bob);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_3, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_1, true);
        vm.stopPrank();

        assertEq(nft.balanceOf(alice), 1, "Alice balance incorrect");
        assertEq(nft.balanceOf(bob), 1, "Bob balance incorrect");

        vm.prank(alice);
        nft.transferFrom(alice, bob, NFT_TOKEN_ID_0);

        assertEq(nft.balanceOf(alice), 0, "Alice balance incorrect");
        assertEq(nft.balanceOf(bob), 2, "Bob balance incorrect");
    }

    function test_transferFrom_DeletesActiveNftForSender()
        external
        grantWhitelistedSenderRoles
        mintLevel2NftForAlice
        mintLevel2NftForAlice
    {
        vm.startPrank(alice);
        nft.activateNftData(NFT_TOKEN_ID_1, true);
        nft.transferFrom(alice, bob, NFT_TOKEN_ID_1);
        vm.stopPrank();

        // Zero is default value
        assertEq(nft.getActiveNft(alice), 0, "Alice active NFT incorrect");
    }

    function test_transferFrom_UpdatesActiveNftForReceiver()
        external
        grantWhitelistedSenderRoles
        mintLevel2NftForAlice
        mintLevel2NftForAlice
    {
        vm.startPrank(alice);
        nft.activateNftData(NFT_TOKEN_ID_1, true);
        nft.transferFrom(alice, bob, NFT_TOKEN_ID_1);
        vm.stopPrank();

        INft.ActivityType activityType = nft
            .getNftData(NFT_TOKEN_ID_1)
            .activityType;

        assertEq(
            nft.getActiveNft(bob),
            NFT_TOKEN_ID_1,
            "Bob active NFT incorrect"
        );
        assertEq(
            uint8(activityType),
            uint8(NFT_ACTIVATION_TRIGGERED),
            "Activity type incorrect"
        );
    }

    function test_transferFrom_DoesNotUpdateActiveNftsIfNotOwnerOfZeroIdNft()
        external
        grantWhitelistedSenderRoles
        mintLevel2NftForAlice
    {
        vm.prank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, true);

        vm.startPrank(bob);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_3, tokenUSDT);
        nft.transferFrom(bob, alice, NFT_TOKEN_ID_1);
        vm.stopPrank();

        assertEq(
            nft.getActiveNft(alice),
            NFT_TOKEN_ID_0,
            "Bob active NFT incorrect"
        );
        assertEq(
            nft.getActiveNft(bob),
            0, // Zero is default value
            "Bob active NFT incorrect"
        );
    }

    function test_transferFrom_DoesNotUpdateActiveNftsIfTransferringNotActiveNft()
        external
        grantWhitelistedSenderRoles
        mintLevel2NftForAlice
        mintLevel2NftForAlice
    {
        vm.startPrank(bob);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_3, tokenUSDT);
        nft.activateNftData(NFT_TOKEN_ID_2, true);
        vm.stopPrank();

        vm.startPrank(alice);
        nft.activateNftData(NFT_TOKEN_ID_0, true);
        nft.transferFrom(alice, bob, NFT_TOKEN_ID_1);
        vm.stopPrank();

        assertEq(
            nft.getActiveNft(alice),
            NFT_TOKEN_ID_0,
            "Bob active NFT incorrect"
        );
        assertEq(
            nft.getActiveNft(bob),
            NFT_TOKEN_ID_2,
            "Bob active NFT incorrect"
        );
    }
}
