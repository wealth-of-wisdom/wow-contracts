// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INft} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract NftSale_MintNft_Unit_Test is Unit_Test {
    uint256 internal level2Price;

    function setUp() public override {
        Unit_Test.setUp();

        level2Price = nft.getLevelData(LEVEL_2, false).price;

        vm.prank(alice);
        tokenUSDT.approve(address(sale), level2Price);
    }

    function test_mintNft_RevertIf_NonExistantPayment() external {
        vm.expectRevert(Errors.NftSale__NonExistantPayment.selector);
        vm.prank(alice);
        sale.mintNft(LEVEL_2, IERC20(makeAddr("FakeToken")));
    }

    function test_mintNft_RevertIf_TokenIsZeroAddress() external {
        vm.expectRevert(Errors.NftSale__NonExistantPayment.selector);
        vm.prank(alice);
        sale.mintNft(LEVEL_2, IERC20(ZERO_ADDRESS));
    }

    function test_mintNft_RevertIf_LevelIsZero() external {
        uint16 fakeLevel = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.NftSale__InvalidLevel.selector,
                fakeLevel
            )
        );
        vm.prank(alice);
        sale.mintNft(fakeLevel, tokenUSDT);
    }

    function test_mintNft_RevertIf_LevelIsTooHigh() external {
        uint16 fakeLevel = MAX_LEVEL + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.NftSale__InvalidLevel.selector,
                fakeLevel
            )
        );
        vm.prank(alice);
        sale.mintNft(fakeLevel, tokenUSDT);
    }

    function test_mintNft_TransfersTokensFromMsgSender() external {
        uint256 startingAliceBalance = tokenUSDT.balanceOf(alice);

        vm.prank(alice);
        sale.mintNft(LEVEL_2, tokenUSDT);

        uint256 endingAliceBalance = tokenUSDT.balanceOf(alice);

        assertEq(
            startingAliceBalance - level2Price,
            endingAliceBalance,
            "Tokens not transferred"
        );
    }

    function test_mintNft_TransfersTokensToContract() external {
        uint256 startingContractBalance = tokenUSDT.balanceOf(address(sale));

        vm.prank(alice);
        sale.mintNft(LEVEL_2, tokenUSDT);

        uint256 endingContractBalance = tokenUSDT.balanceOf(address(sale));

        assertEq(
            startingContractBalance + level2Price,
            endingContractBalance,
            "Tokens not transferred"
        );
    }

    function test_mintNft_SetsNftDataCorrectly() external {
        vm.prank(alice);
        sale.mintNft(LEVEL_2, tokenUSDT);

        INft.NftData memory nftData = nft.getNftData(NFT_TOKEN_ID_0);

        assertEq(nftData.level, LEVEL_2, "Nft didn't set level");
        assertFalse(nftData.isGenesis, "Nft didn't set genesis type");
        assertEq(
            uint8(nftData.activityType),
            uint8(NFT_ACTIVITY_TYPE_NOT_ACTIVATED),
            "Nft not activated"
        );
        assertEq(
            nftData.activityEndTimestamp,
            0,
            "Nft didn't assign natural lifecycle"
        );
        assertEq(
            nftData.extendedActivityEndTimestamp,
            0,
            "Nft didn't assign extended lifecycle"
        );
    }

    function test_mintNft_MintsNewNft() external {
        vm.prank(alice);
        sale.mintNft(LEVEL_2, tokenUSDT);

        assertEq(nft.balanceOf(alice), 1, "User did not receive nft");
        assertEq(
            nft.ownerOf(NFT_TOKEN_ID_0),
            alice,
            "NFT not minted to correct address"
        );
        assertEq(
            nft.getNextTokenId(),
            NFT_TOKEN_ID_1,
            "Token was not minted and ID not changed"
        );
    }

    function test_mintNft_EmitsPurchasePaidEvent() external {
        vm.expectEmit(true, true, true, true);
        emit PurchasePaid(tokenUSDT, level2Price);

        vm.prank(alice);
        sale.mintNft(LEVEL_2, tokenUSDT);
    }

    function test_mintNft_EmitsNftMintedEvent() external {
        vm.expectEmit(true, true, true, true);
        emit NftMinted(alice, LEVEL_2, false, 0);

        vm.prank(alice);
        sale.mintNft(LEVEL_2, tokenUSDT);
    }
}
