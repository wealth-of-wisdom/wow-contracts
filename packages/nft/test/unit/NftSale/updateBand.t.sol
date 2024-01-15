// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {NftSale_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftSaleUnit.t.sol";

contract NftSale_UpdateBand_Unit_Test is NftSale_Unit_Test {
    uint256 internal upgradePrice;

    function setUp() public override {
        NftSale_Unit_Test.setUp();

        uint256 newPrice = sale.getLevelPriceInUSD(LEVEL_3);
        uint256 oldPrice = sale.getLevelPriceInUSD(DEFAULT_LEVEL_2);
        upgradePrice = newPrice - oldPrice;
    }

    function test_updateBand_RevertIf_InvalidLevel()
        external
        mintLevel2BandForAlice
    {
        uint16 fakeLevel = 16;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.NftSale__InvalidLevel.selector,
                fakeLevel
            )
        );
        vm.prank(admin);
        sale.updateBand(NFT_TOKEN_ID_0, fakeLevel, tokenUSDT);
    }

    function test_updateBand_RevertIf_NonExistantPayment()
        external
        mintLevel2BandForAlice
    {
        vm.expectRevert(Errors.NftSale__NonExistantPayment.selector);
        vm.prank(admin);
        sale.updateBand(
            NFT_TOKEN_ID_0,
            DEFAULT_LEVEL_2,
            IERC20(makeAddr("FakeToken"))
        );
    }

    function test_updateBand_RevertIf_TokenIsZeroAddress() external {
        vm.expectRevert(Errors.NftSale__NonExistantPayment.selector);
        vm.prank(admin);
        sale.updateBand(NFT_TOKEN_ID_0, DEFAULT_LEVEL_2, IERC20(ZERO_ADDRESS));
    }

    function test_updateBand_RevertIf_NotBandOwner()
        external
        mintLevel2BandForAlice
    {
        vm.expectRevert(Errors.NftSale__NotBandOwner.selector);
        vm.prank(bob);
        sale.updateBand(NFT_TOKEN_ID_0, DEFAULT_LEVEL_2, tokenUSDT);
    }

    function test_updateBand_RevertIf_UnupdatableBandIsGenesis() external {
        vm.prank(admin);
        sale.mintGenesisBand(alice, DEFAULT_LEVEL_2, DEFAULT_GENESIS_AMOUNT);

        vm.startPrank(alice);
        vm.expectRevert(Errors.NftSale__UnupdatableBand.selector);
        sale.updateBand(NFT_TOKEN_ID_0, DEFAULT_LEVEL_2, tokenUSDT);
        vm.stopPrank();
    }

    function test_updateBand_RevertIf_UnupdatableBandIsDisabled()
        external
        mintLevel2BandForAlice
    {
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateBand(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.expectRevert(Errors.NftSale__UnupdatableBand.selector);
        sale.updateBand(NFT_TOKEN_ID_0, DEFAULT_LEVEL_2, tokenUSDT);
        vm.stopPrank();
    }

    function test_updateBand_RevertIf_NewLevelIsTheSame()
        external
        mintLevel2BandForAlice
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.NftSale__InvalidLevel.selector,
                DEFAULT_LEVEL_2
            )
        );
        vm.prank(alice);
        sale.updateBand(NFT_TOKEN_ID_0, DEFAULT_LEVEL_2, tokenUSDT);
    }

    function test_updateBand_RevertIf_NewLevelIsTheSmaller()
        external
        mintLevel2BandForAlice
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.NftSale__InvalidLevel.selector,
                LEVEL_1
            )
        );
        vm.prank(alice);
        sale.updateBand(NFT_TOKEN_ID_0, LEVEL_1, tokenUSDT);
    }

    function test_updateBand_ChangesOldNftActivityTypeOnly()
        external
        mintLevel2BandForAlice
    {
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateBand(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.stopPrank();

        INftSale.Band memory bandData = sale.getBand(NFT_TOKEN_ID_0);

        assertEq(bandData.level, DEFAULT_LEVEL_2, "Band level set incorrectly");
        assertFalse(bandData.isGenesis, "Band set as genesis");
        assertEq(
            uint8(bandData.activityType),
            uint8(NFT_ACTIVITY_TYPE_DEACTIVATED),
            "Band not deactivated"
        );
    }

    function test_updateBand_CreatesNewBand() external mintLevel2BandForAlice {
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateBand(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.stopPrank();

        INftSale.Band memory bandData = sale.getBand(NFT_TOKEN_ID_1);

        assertEq(bandData.level, LEVEL_3, "Band level set incorrectly");
        assertFalse(bandData.isGenesis, "Band set as genesis");
        assertEq(
            uint8(bandData.activityType),
            uint8(NFT_ACTIVITY_TYPE_INACTIVE),
            "Band not deactivated"
        );
    }

    function test_updateBand_TransfersTokensFromMsgSender()
        external
        mintLevel2BandForAlice
    {
        uint256 startingAliceBalance = tokenUSDT.balanceOf(alice);

        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateBand(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.stopPrank();

        uint256 endingAliceBalance = tokenUSDT.balanceOf(alice);

        assertEq(
            startingAliceBalance - upgradePrice,
            endingAliceBalance,
            "Tokens not transferred"
        );
    }

    function test_updateBand_TransfersTokensToContract()
        external
        mintLevel2BandForAlice
    {
        uint256 startingContractBalance = tokenUSDT.balanceOf(address(sale));

        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateBand(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.stopPrank();

        uint256 endingContractBalance = tokenUSDT.balanceOf(address(sale));

        assertEq(
            startingContractBalance + upgradePrice,
            endingContractBalance,
            "Tokens not transferred"
        );
    }

    function test_updateBand_MintsNewNft() external mintLevel2BandForAlice {
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);
        sale.updateBand(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.stopPrank();

        assertEq(nftContract.balanceOf(alice), 2, "User did not receive nft");
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
            nftContract.getNextTokenId(),
            NFT_TOKEN_ID_2,
            "Token was not minted and ID not changed"
        );
    }

    function test_updateBand_EmitsPurchasePaidEvent()
        external
        mintLevel2BandForAlice
    {
        vm.prank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);

        vm.expectEmit(true, true, true, true);
        emit PurchasePaid(tokenUSDT, upgradePrice);

        vm.prank(alice);
        sale.mintBand(DEFAULT_LEVEL_2, tokenUSDT);
    }

    function test_updateBand_EmitsBandUpdated()
        external
        mintLevel2BandForAlice
    {
        vm.prank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);

        vm.expectEmit(true, true, true, true);
        emit BandUpdated(alice, NFT_TOKEN_ID_0, DEFAULT_LEVEL_2, LEVEL_3);

        vm.prank(alice);
        sale.updateBand(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
    }
}
