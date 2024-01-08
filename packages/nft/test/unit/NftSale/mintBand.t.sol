// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {INft} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Nft_Sale_Unit_Test} from "../NftSaleUnit.t.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Nft_Sale_MintBand_Unit_Test is Nft_Sale_Unit_Test {
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

        assertEq(
            sale.getCurrentTokenId(),
            STARTER_TOKEN_ID,
            "Token was not minted and ID not changed"
        );
        assertTrue(
            sale.getBand(STARTER_TOKEN_ID).isActive,
            "Band not activated"
        );
        assertFalse(
            sale.getBand(STARTER_TOKEN_ID).isGenesis,
            "Band set as genesis"
        );
        assertEq(
            sale.getBand(STARTER_TOKEN_ID).level,
            DEFAULT_LEVEL,
            "Band level set incorrectly"
        );
        assertEq(nftContract.balanceOf(alice), 1, "User did not receive nft");
        assertEq(
            tokenUSDT.balanceOf(address(sale)),
            price,
            "Funds not transfered"
        );
    }
}