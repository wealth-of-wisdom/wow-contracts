// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {NftSale_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftSaleUnit.t.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract NftSale_UpdateBand_Unit_Test is NftSale_Unit_Test {
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

    function test_updateBand_RevertIf_UnupdatableBandIsGenesis() external {
        vm.prank(admin);
        sale.mintGenesisBand(alice, DEFAULT_LEVEL, DEFAULT_GENESIS_AMOUNT);

        vm.startPrank(alice);
        vm.expectRevert(Errors.Nft__UnupdatableBand.selector);
        sale.updateBand(STARTER_TOKEN_ID, DEFAULT_LEVEL, tokenUSDT);
        vm.stopPrank();
    }

    function test_updateBand_RevertIf_UnupdatableBandIsDisabled()
        external
        mintOneBandForUser
    {
        uint256 newPrice = sale.getLevelPriceInUSD(DEFAULT_NEW_LEVEL);
        uint256 oldPrice = sale.getLevelPriceInUSD(DEFAULT_LEVEL);
        uint256 upgradePrice = newPrice - oldPrice;

        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateBand(STARTER_TOKEN_ID, DEFAULT_NEW_LEVEL, tokenUSDT);
        vm.expectRevert(Errors.Nft__UnupdatableBand.selector);
        sale.updateBand(STARTER_TOKEN_ID, DEFAULT_LEVEL, tokenUSDT);
        vm.stopPrank();
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
        sale.updateBand(STARTER_TOKEN_ID, DEFAULT_NEW_LEVEL, tokenUSDT);
        vm.stopPrank();

        assertEq(
            nftContract.getNextTokenId(),
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

    function test_updateBand_TransferNftAndUpdateBand()
        external
        mintOneBandForUser
    {
        assertEq(nftContract.balanceOf(admin), 0, "NFT pre-minted to admin");
        assertEq(
            nftContract.balanceOf(alice),
            1,
            "NFT not pre-minted to alice"
        );

        uint256 newPrice = sale.getLevelPriceInUSD(DEFAULT_NEW_LEVEL);
        uint256 oldPrice = sale.getLevelPriceInUSD(DEFAULT_LEVEL);
        uint256 upgradePrice = newPrice - oldPrice;

        vm.prank(admin);
        nftContract.grantRole(MINTER_ROLE, address(alice));

        vm.prank(alice);
        nftContract.safeTransferFrom(alice, admin, STARTER_TOKEN_ID);

        assertEq(
            nftContract.balanceOf(admin),
            1,
            "NFT transfered to incorrect address"
        );
        assertEq(
            nftContract.balanceOf(alice),
            0,
            "NFT transfered to incorrect address"
        );

        vm.startPrank(admin);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateBand(STARTER_TOKEN_ID, DEFAULT_NEW_LEVEL, tokenUSDT);
        vm.stopPrank();

        assertEq(
            nftContract.getNextTokenId(),
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
            nftContract.ownerOf(STARTER_TOKEN_ID),
            admin,
            "User did not receive new nft"
        );
        assertEq(
            tokenUSDT.balanceOf(address(sale)),
            oldPrice + upgradePrice,
            "Funds not transfered"
        );
    }
}
