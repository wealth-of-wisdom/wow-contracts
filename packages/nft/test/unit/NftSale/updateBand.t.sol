// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {INft} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Nft_Sale_Unit_Test} from "../NftSaleUnit.t.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Nft_Sale_UpdateBand_Unit_Test is Nft_Sale_Unit_Test {
    function test_updateBand_RevertIf_InvalidLevel()
        external
        mintOneBandForUser
    {
        uint16 fakeLevel = 16;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Nft__InvalidLevel.selector, fakeLevel)
        );
        vm.prank(admin);
        sale.updateBand(STARTER_TOKEN_ID, fakeLevel, tokenUSDT);
    }

    function test_updateBand_RevertIf_NonExistantPayment()
        external
        mintOneBandForUser
    {
        vm.expectRevert(Errors.Nft__NonExistantPayment.selector);
        vm.prank(admin);
        sale.updateBand(STARTER_TOKEN_ID, DEFAULT_LEVEL, IERC20(ZERO_ADDRESS));
    }

    function test_updateBand_RevertIf_NotBandOwner()
        external
        mintOneBandForUser
    {
        vm.expectRevert(Errors.Nft__NotBandOwner.selector);
        vm.prank(bob);
        sale.updateBand(STARTER_TOKEN_ID, DEFAULT_LEVEL, tokenUSDT);
    }

    function test_updateBand_RevertIf_Nft__InvalidLevel()
        external
        mintOneBandForUser
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Nft__InvalidLevel.selector,
                DEFAULT_LEVEL
            )
        );
        vm.prank(alice);
        sale.updateBand(STARTER_TOKEN_ID, DEFAULT_LEVEL, tokenUSDT);
    }

    function test_updateBand_EmitsBandUpdated() external mintOneBandForUser {
        uint256 newPrice = sale.getLevelPriceInUSD(DEFAULT_NEW_LEVEL);
        uint256 oldPrice = sale.getLevelPriceInUSD(DEFAULT_LEVEL);
        uint256 upgradePrice = newPrice - oldPrice;

        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        vm.expectEmit(true, true, true, true);
        emit BandUpdated(
            alice,
            STARTER_TOKEN_ID,
            DEFAULT_LEVEL,
            DEFAULT_NEW_LEVEL
        );
        sale.updateBand(STARTER_TOKEN_ID, DEFAULT_NEW_LEVEL, tokenUSDT);
        vm.stopPrank();
    }

    function test_updateBand_UpdatesBandToNewLevel()
        external
        mintOneBandForUser
    {
        uint256 newPrice = sale.getLevelPriceInUSD(DEFAULT_NEW_LEVEL);
        uint256 oldPrice = sale.getLevelPriceInUSD(DEFAULT_LEVEL);
        uint256 upgradePrice = newPrice - oldPrice;

        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        vm.expectEmit(true, true, true, true);
        emit BandUpdated(
            alice,
            STARTER_TOKEN_ID,
            DEFAULT_LEVEL,
            DEFAULT_NEW_LEVEL
        );
        sale.updateBand(STARTER_TOKEN_ID, DEFAULT_NEW_LEVEL, tokenUSDT);
        vm.stopPrank();

        assertEq(
            sale.getCurrentTokenId(),
            FIRST_MINTED_TOKEN_ID + 1,
            "Token was not minted and ID not changed"
        );
        assertEq(
            uint8(sale.getBand(STARTER_TOKEN_ID).activityType),
            uint8(NFT_ACTIVITY_TYPE_DEACTIVATED),
            "Band not deactivated"
        );
        assertEq(
            uint8(sale.getBand(FIRST_MINTED_TOKEN_ID).activityType),
            uint8(NFT_ACTIVITY_TYPE_INACTIVE),
            "Band not activated"
        );
        assertFalse(
            sale.getBand(STARTER_TOKEN_ID).isGenesis,
            "Band set as genesis"
        );
        assertEq(
            sale.getBand(FIRST_MINTED_TOKEN_ID).level,
            DEFAULT_NEW_LEVEL,
            "Band level set incorrectly"
        );
        assertEq(
            nftContract.balanceOf(alice),
            2,
            "User did not receive new nft"
        );
        assertEq(
            tokenUSDT.balanceOf(address(sale)),
            oldPrice + upgradePrice,
            "Funds not transfered"
        );
    }

    function test_updateBand_UpdatesBandToLowerLevel()
        external
        mintOneBandForUser
    {
        uint16 newLevel = 1;
        uint256 newPrice = sale.getLevelPriceInUSD(newLevel);
        uint256 oldPrice = sale.getLevelPriceInUSD(DEFAULT_LEVEL);
        uint256 refundPrice = oldPrice - newPrice;
        uint256 aliceBalanceBefore = tokenUSDT.balanceOf(alice);

        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true);
        emit BandUpdated(alice, STARTER_TOKEN_ID, DEFAULT_LEVEL, newLevel);
        sale.updateBand(STARTER_TOKEN_ID, newLevel, tokenUSDT);
        vm.stopPrank();

        assertEq(
            sale.getCurrentTokenId(),
            FIRST_MINTED_TOKEN_ID + 1,
            "Token was not minted and ID not changed"
        );
        assertEq(
            uint8(sale.getBand(STARTER_TOKEN_ID).activityType),
            uint8(NFT_ACTIVITY_TYPE_DEACTIVATED),
            "Band not deactivated"
        );
        assertEq(
            uint8(sale.getBand(FIRST_MINTED_TOKEN_ID).activityType),
            uint8(NFT_ACTIVITY_TYPE_INACTIVE),
            "Band not activated"
        );
        assertFalse(
            sale.getBand(STARTER_TOKEN_ID).isGenesis,
            "Band set as genesis"
        );
        assertEq(
            sale.getBand(FIRST_MINTED_TOKEN_ID).level,
            newLevel,
            "Band level set incorrectly"
        );
        assertEq(
            nftContract.balanceOf(alice),
            2,
            "User did not receive new nft"
        );
        assertEq(
            tokenUSDT.balanceOf(address(sale)),
            oldPrice - refundPrice,
            "Funds not transfered"
        );

        assertEq(
            tokenUSDT.balanceOf(alice),
            aliceBalanceBefore + refundPrice,
            "Refund not transfered"
        );
    }
}
