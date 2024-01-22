// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.20;

// import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
// import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
// import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
// import {INft} from "@wealth-of-wisdom/nft/contracts/interfaces/INft.sol";
// import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
// import {Nft_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftUnit.t.sol";

// contract NftSale_MintNft_Unit_Test is Nft_Unit_Test {
//     uint256 internal level2Price;

//     function setUp() public override {
//         Nft_Unit_Test.setUp();

//         level2Price = nft.getLevelData(LEVEL_2).price;

//         vm.prank(alice);
//         tokenUSDT.approve(address(sale), level2Price);
//     }

//     function test_mintNft_RevertIf_NonExistantPayment() external {
//         vm.expectRevert(Errors.NftSale__NonExistantPayment.selector);
//         vm.prank(alice);
//         sale.mintNft(LEVEL_2, IERC20(makeAddr("FakeToken")));
//     }

//     function test_mintNft_RevertIf_TokenIsZeroAddress() external {
//         vm.expectRevert(Errors.NftSale__NonExistantPayment.selector);
//         vm.prank(alice);
//         sale.mintNft(LEVEL_2, IERC20(ZERO_ADDRESS));
//     }

//     function test_mintNft_RevertIf_InvalidLevel() external {
//         uint16 fakeLevel = 16;
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 Errors.NftSale__InvalidLevel.selector,
//                 fakeLevel
//             )
//         );
//         vm.prank(alice);
//         sale.mintNft(fakeLevel, tokenUSDT);
//     }

//     function test_mintNft_SetsNftDataCorrectly() external {
//         vm.prank(alice);
//         sale.mintNft(LEVEL_2, tokenUSDT);

//         INft.NftData memory nftData = nft.getNftData(NFT_TOKEN_ID_0);

//         assertEq(uint8(nftData.level), uint8(LEVEL_2), "Nft didnt set level");
//         assertEq(nftData.isGenesis, false, "Nft didnt set genesis type");
//         assertEq(
//             uint8(nftData.activityType),
//             uint8(NFT_ACTIVITY_TYPE_NOT_ACTIVATED),
//             "Nft not activated"
//         );
//         assertEq(
//             nftData.activityEndTimestamp,
//             0,
//             "Nft didnt assign natural lifecycle"
//         );
//         assertEq(
//             nftData.extendedActivityEndTimestamp,
//             0,
//             "Nft didnt assign extended lifecycle"
//         );

//         assertFalse(nftData.isGenesis, "Nft set as genesis");
//         assertEq(nftData.level, LEVEL_2, "Nft level set incorrectly");
//     }

//     function test_mintNft_TransfersTokensFromMsgSender() external {
//         uint256 startingAliceBalance = tokenUSDT.balanceOf(alice);

//         vm.prank(alice);
//         sale.mintNft(LEVEL_2, tokenUSDT);

//         uint256 endingAliceBalance = tokenUSDT.balanceOf(alice);

//         assertEq(
//             startingAliceBalance - level2Price,
//             endingAliceBalance,
//             "Tokens not transferred"
//         );
//     }

//     function test_mintNft_TransfersTokensToContract() external {
//         uint256 startingContractBalance = tokenUSDT.balanceOf(address(sale));

//         vm.prank(alice);
//         sale.mintNft(LEVEL_2, tokenUSDT);

//         uint256 endingContractBalance = tokenUSDT.balanceOf(address(sale));

//         assertEq(
//             startingContractBalance + level2Price,
//             endingContractBalance,
//             "Tokens not transferred"
//         );
//     }

//     function test_mintNft_MintsNewNft() external {
//         vm.prank(alice);
//         sale.mintNft(LEVEL_2, tokenUSDT);

//         assertEq(nft.balanceOf(alice), 1, "User did not receive nft");
//         assertEq(
//             nft.ownerOf(NFT_TOKEN_ID_0),
//             alice,
//             "NFT not minted to correct address"
//         );
//         assertEq(
//             nft.getNextTokenId(),
//             NFT_TOKEN_ID_1,
//             "Token was not minted and ID not changed"
//         );
//     }

//     function test_mintNft_EmitsPurchasePaidEvent() external {
//         vm.expectEmit(true, true, true, true);
//         emit PurchasePaid(tokenUSDT, level2Price);

//         vm.prank(alice);
//         sale.mintNft(LEVEL_2, tokenUSDT);
//     }

//     function test_mintNft_EmitsNftMintedEvent() external {
//         vm.expectEmit(true, true, true, true);
//         emit NftMinted(alice, LEVEL_2, false, 0);

//         vm.prank(alice);
//         sale.mintNft(LEVEL_2, tokenUSDT);
//     }
// }
