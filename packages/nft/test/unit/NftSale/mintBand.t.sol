// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {NftSale_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftSaleUnit.t.sol";

contract NftSale_MintBand_Unit_Test is NftSale_Unit_Test {
    uint256 internal level2Price;

    function setUp() public override {
        NftSale_Unit_Test.setUp();

        level2Price = sale.getLevelPriceInUSD(DEFAULT_LEVEL_2);

        vm.prank(alice);
        tokenUSDT.approve(address(sale), level2Price);
    }

    function test_mintBand_RevertIf_NonExistantPayment() external {
        vm.expectRevert(Errors.NftSale__NonExistantPayment.selector);
        vm.prank(alice);
        sale.mintBand(DEFAULT_LEVEL_2, IERC20(makeAddr("FakeToken")));
    }

    function test_mintBand_RevertIf_TokenIsZeroAddress() external {
        vm.expectRevert(Errors.NftSale__NonExistantPayment.selector);
        vm.prank(alice);
        sale.mintBand(DEFAULT_LEVEL_2, IERC20(ZERO_ADDRESS));
    }

    function test_mintBand_RevertIf_InvalidLevel() external {
        uint16 fakeLevel = 16;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.NftSale__InvalidLevel.selector,
                fakeLevel
            )
        );
        vm.prank(alice);
        sale.mintBand(fakeLevel, tokenUSDT);
    }

    function test_mintBand_SetsBandDataCorrectly() external {
        vm.prank(alice);
        sale.mintBand(DEFAULT_LEVEL_2, tokenUSDT);

        INftSale.Band memory bandData = sale.getBand(NFT_TOKEN_ID_0);
        assertEq(
            uint8(bandData.activityType),
            uint8(NFT_ACTIVITY_TYPE_INACTIVE),
            "Band not activated"
        );
        assertFalse(bandData.isGenesis, "Band set as genesis");
        assertEq(bandData.level, DEFAULT_LEVEL_2, "Band level set incorrectly");
    }

    function test_mintBand_TransfersTokensFromMsgSender() external {
        uint256 startingAliceBalance = tokenUSDT.balanceOf(alice);

        vm.prank(alice);
        sale.mintBand(DEFAULT_LEVEL_2, tokenUSDT);

        uint256 endingAliceBalance = tokenUSDT.balanceOf(alice);

        assertEq(
            startingAliceBalance - level2Price,
            endingAliceBalance,
            "Tokens not transferred"
        );
    }

    function test_mintBand_TransfersTokensToContract() external {
        uint256 startingContractBalance = tokenUSDT.balanceOf(address(sale));

        vm.prank(alice);
        sale.mintBand(DEFAULT_LEVEL_2, tokenUSDT);

        uint256 endingContractBalance = tokenUSDT.balanceOf(address(sale));

        assertEq(
            startingContractBalance + level2Price,
            endingContractBalance,
            "Tokens not transferred"
        );
    }

    function test_mintBand_MintsNewNft() external {
        vm.prank(alice);
        sale.mintBand(DEFAULT_LEVEL_2, tokenUSDT);

        assertEq(nftContract.balanceOf(alice), 1, "User did not receive nft");
        assertEq(
            nftContract.ownerOf(NFT_TOKEN_ID_0),
            alice,
            "NFT not minted to correct address"
        );
        assertEq(
            nftContract.getNextTokenId(),
            NFT_TOKEN_ID_1,
            "Token was not minted and ID not changed"
        );
    }

    function test_mintBand_EmitsPurchasePaidEvent() external {
        vm.expectEmit(true, true, true, true);
        emit PurchasePaid(tokenUSDT, level2Price);

        vm.prank(alice);
        sale.mintBand(DEFAULT_LEVEL_2, tokenUSDT);
    }

    function test_mintBand_EmitsBandMintedEvent() external {
        vm.expectEmit(true, true, true, true);
        emit BandMinted(alice, NFT_TOKEN_ID_0, DEFAULT_LEVEL_2, false);

        vm.prank(alice);
        sale.mintBand(DEFAULT_LEVEL_2, tokenUSDT);
    }
}
