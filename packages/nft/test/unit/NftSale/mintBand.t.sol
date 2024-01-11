// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {NftSale_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftSaleUnit.t.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract NftSale_MintBand_Unit_Test is NftSale_Unit_Test {
    function test_mintBand_RevertIf_NonExistantPayment() external {
        vm.expectRevert(Errors.Nft__NonExistantPayment.selector);
        vm.prank(alice);
        sale.mintBand(DEFAULT_LEVEL, IERC20(ZERO_ADDRESS));
    }

    function test_mintBand_RevertIf_InvalidLevel() external {
        uint16 fakeLevel = 16;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Nft__InvalidLevel.selector, fakeLevel)
        );
        vm.prank(alice);
        sale.mintBand(fakeLevel, tokenUSDT);
    }

    function test_mintBand_EmitsBandMinted() external {
        vm.startPrank(alice);
        uint256 price = sale.getLevelPriceInUSD(DEFAULT_LEVEL);
        tokenUSDT.approve(address(sale), price);
        vm.expectEmit(true, true, true, true);
        emit BandMinted(alice, STARTER_TOKEN_ID, DEFAULT_LEVEL, false);
        sale.mintBand(DEFAULT_LEVEL, sale.getTokenUSDT());
        vm.stopPrank();
    }

    function test_mintBand_PurchaseAndMintBandWithDataUpdates() external {
        vm.startPrank(alice);
        uint256 price = sale.getLevelPriceInUSD(DEFAULT_LEVEL);
        tokenUSDT.approve(address(sale), price);
        sale.mintBand(DEFAULT_LEVEL, tokenUSDT);
        vm.stopPrank();

        INftSale.Band memory bandData = sale.getBand(STARTER_TOKEN_ID);

        assertEq(
            nftContract.getNextTokenId(),
            FIRST_MINTED_TOKEN_ID,
            "Token was not minted and ID not changed"
        );
        assertEq(
            uint8(bandData.activityType),
            uint8(NFT_ACTIVITY_TYPE_INACTIVE),
            "Band not activated"
        );
        assertFalse(bandData.isGenesis, "Band set as genesis");
        assertEq(bandData.level, DEFAULT_LEVEL, "Band level set incorrectly");
        assertEq(nftContract.balanceOf(alice), 1, "User did not receive nft");
        assertEq(
            tokenUSDT.balanceOf(address(sale)),
            price,
            "Funds not transfered"
        );
    }

    function test_mintBand_PurchaseAndMintBandThenTransfer() external {
        assertEq(nftContract.balanceOf(admin), 0, "NFT pre-minted to admin");
        assertEq(nftContract.balanceOf(alice), 0, "NFT pre-minted to alice");

        uint256 price = sale.getLevelPriceInUSD(DEFAULT_LEVEL);
        vm.startPrank(admin);
        tokenUSDT.approve(address(sale), price);
        sale.mintBand(DEFAULT_LEVEL, tokenUSDT);

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

        nftContract.safeTransferFrom(admin, alice, STARTER_TOKEN_ID);
        vm.stopPrank();

        assertEq(nftContract.balanceOf(admin), 0, "NFT transfer not complete");
        assertEq(nftContract.balanceOf(alice), 1, "NFT transfer not complete");
    }
}
