// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {NftSale_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftSaleUnit.t.sol";

contract NftSale_MintGenesisBand_Unit_Test is NftSale_Unit_Test {
    function assertGenesisBand(
        INftSale.Band memory band,
        uint16 level
    ) internal {
        assertEq(band.level, level, "Band level set incorrectly");
        assertEq(
            uint8(band.activityType),
            uint8(NFT_ACTIVITY_TYPE_INACTIVE),
            "Band not activated"
        );
        assertTrue(band.isGenesis, "Band not set as genesis");
    }

    function test_mintGenesisBand_RevertIf_NotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        sale.mintGenesisBand(alice, DEFAULT_LEVEL_2, DEFAULT_GENESIS_AMOUNT);
    }

    function test_mintGenesisBand_RevertIf_ReceiverIsZeroAddress() external {
        vm.expectRevert(Errors.NftSale__ZeroAddress.selector);
        vm.prank(admin);
        sale.mintGenesisBand(
            ZERO_ADDRESS,
            DEFAULT_LEVEL_2,
            DEFAULT_GENESIS_AMOUNT
        );
    }

    function test_mintGenesisBand_RevertIf_InvalidLevel() external {
        uint16 fakeLevel = 16;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.NftSale__InvalidLevel.selector,
                fakeLevel
            )
        );
        vm.prank(admin);
        sale.mintGenesisBand(alice, fakeLevel, DEFAULT_GENESIS_AMOUNT);
    }

    function test_mintGenesisBand_RevertIf_PassedZeroAmount() external {
        vm.expectRevert(Errors.NftSale__PassedZeroAmount.selector);
        vm.prank(admin);
        sale.mintGenesisBand(alice, DEFAULT_LEVEL_2, 0);
    }

    function test_mintGenesisBand_Creates1NewBand() external {
        vm.prank(admin);
        sale.mintGenesisBand(alice, DEFAULT_LEVEL_2, 1);

        INftSale.Band memory bandData = sale.getBand(NFT_TOKEN_ID_0);
        assertGenesisBand(bandData, DEFAULT_LEVEL_2);
    }

    function test_mintGenesisBand_Creates5NewBands() external {
        vm.prank(admin);
        sale.mintGenesisBand(alice, DEFAULT_LEVEL_2, DEFAULT_GENESIS_AMOUNT);

        INftSale.Band memory bandData = sale.getBand(NFT_TOKEN_ID_0);
        assertGenesisBand(bandData, DEFAULT_LEVEL_2);

        assertGenesisBand(sale.getBand(NFT_TOKEN_ID_0), DEFAULT_LEVEL_2);
        assertGenesisBand(sale.getBand(NFT_TOKEN_ID_1), DEFAULT_LEVEL_2);
        assertGenesisBand(sale.getBand(NFT_TOKEN_ID_2), DEFAULT_LEVEL_2);
        assertGenesisBand(sale.getBand(3), DEFAULT_LEVEL_2);
        assertGenesisBand(sale.getBand(4), DEFAULT_LEVEL_2);
    }

    function test_mintGenesisBand_Mints1Nft() external {
        vm.prank(admin);
        sale.mintGenesisBand(alice, DEFAULT_LEVEL_2, 1);

        assertEq(
            nftContract.getNextTokenId(),
            NFT_TOKEN_ID_1,
            "Token was not minted and ID not changed"
        );
        assertEq(nftContract.balanceOf(alice), 1, "User did not receive nft");
        assertEq(
            nftContract.ownerOf(NFT_TOKEN_ID_0),
            alice,
            "NFT not minted to correct address"
        );
    }

    function test_mintGenesisBand_Mints5Nft() external {
        vm.prank(admin);
        sale.mintGenesisBand(alice, DEFAULT_LEVEL_2, DEFAULT_GENESIS_AMOUNT);

        assertEq(
            nftContract.getNextTokenId(),
            5,
            "Token was not minted and ID not changed"
        );
        assertEq(nftContract.balanceOf(alice), 5, "User did not receive nft");
        assertEq(
            nftContract.ownerOf(NFT_TOKEN_ID_0),
            alice,
            "NFT not minted to correct address"
        );
        assertEq(
            nftContract.ownerOf(NFT_TOKEN_ID_1),
            alice,
            "NFT not minted to correct address"
        );
        assertEq(
            nftContract.ownerOf(NFT_TOKEN_ID_2),
            alice,
            "NFT not minted to correct address"
        );
        assertEq(
            nftContract.ownerOf(3),
            alice,
            "NFT not minted to correct address"
        );
        assertEq(
            nftContract.ownerOf(4),
            alice,
            "NFT not minted to correct address"
        );
    }

    function test_mintGenesisBand_EmitsBandMintedEvent5Times() external {
        vm.expectEmit(true, true, true, true);
        emit BandMinted(alice, NFT_TOKEN_ID_0, DEFAULT_LEVEL_2, true);

        vm.expectEmit(true, true, true, true);
        emit BandMinted(alice, NFT_TOKEN_ID_1, DEFAULT_LEVEL_2, true);

        vm.expectEmit(true, true, true, true);
        emit BandMinted(alice, NFT_TOKEN_ID_2, DEFAULT_LEVEL_2, true);

        vm.expectEmit(true, true, true, true);
        emit BandMinted(alice, 3, DEFAULT_LEVEL_2, true);

        vm.expectEmit(true, true, true, true);
        emit BandMinted(alice, 4, DEFAULT_LEVEL_2, true);

        vm.prank(admin);
        sale.mintGenesisBand(alice, DEFAULT_LEVEL_2, DEFAULT_GENESIS_AMOUNT);
    }
}
