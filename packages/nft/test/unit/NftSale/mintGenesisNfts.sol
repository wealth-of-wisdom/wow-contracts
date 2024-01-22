// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.20;

// import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
// import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
// import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
// import {INft} from "@wealth-of-wisdom/nft/contracts/interfaces/INft.sol";
// import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
// import {Nft_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftUnit.t.sol";

// contract NftSale_MintGenesisNft_Unit_Test is Nft_Unit_Test {
//     address[] genesisUser = [alice];
//     address[] threeGenesisUsers = [alice, alice, bob];
//     address[] zeroAddress = [ZERO_ADDRESS];

//     uint16[] lvl = [LEVEL_2];
//     uint16[] threeLevels = [LEVEL_1, LEVEL_2, LEVEL_3];
//     uint16[] fakeLevel = [16];

//     function assertGenesisNft(
//         INft.NftData memory nftData,
//         uint16 level
//     ) internal {
//         assertEq(nftData.level, level, "Nft level set incorrectly");
//         assertEq(
//             uint8(nftData.activityType),
//             uint8(NFT_ACTIVITY_TYPE_NOT_ACTIVATED),
//             "Nft not activated"
//         );
//         assertTrue(nftData.isGenesis, "Nft not set as genesis");
//     }

//     function test_mintGenesisNft_RevertIf_NotDefaultAdmin() external {
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 IAccessControl.AccessControlUnauthorizedAccount.selector,
//                 alice,
//                 DEFAULT_ADMIN_ROLE
//             )
//         );
//         vm.prank(alice);
//         sale.mintGenesisNfts(genesisUser, lvl);
//     }

//     function test_mintGenesisNft_RevertIf_ReceiverIsZeroAddress() external {
//         vm.expectRevert(Errors.Nft__ZeroAddress.selector);
//         vm.prank(admin);
//         sale.mintGenesisNfts(zeroAddress, lvl);
//     }

//     function test_mintGenesisNft_Creates1NewNft() external {
//         vm.prank(admin);
//         sale.mintGenesisNfts(genesisUser, lvl);

//         INft.NftData memory nftData = nft.getNftData(NFT_TOKEN_ID_0);
//         assertGenesisNft(nftData, LEVEL_2);
//     }

//     function test_mintGenesisNft_Creates3NewNfts() external {
//         vm.prank(admin);
//         sale.mintGenesisNfts(threeGenesisUsers, threeLevels);

//         assertGenesisNft(nft.getNftData(NFT_TOKEN_ID_0), LEVEL_1);
//         assertGenesisNft(nft.getNftData(NFT_TOKEN_ID_1), LEVEL_2);
//         assertGenesisNft(nft.getNftData(NFT_TOKEN_ID_2), LEVEL_3);
//     }

//     function test_mintGenesisNft_Mints1Nft() external {
//         vm.prank(admin);
//         sale.mintGenesisNfts(genesisUser, lvl);

//         assertEq(
//             nft.getNextTokenId(),
//             NFT_TOKEN_ID_1,
//             "Token was not minted and ID not changed"
//         );
//         assertEq(nft.balanceOf(alice), 1, "User did not receive nft");
//         assertEq(
//             nft.ownerOf(NFT_TOKEN_ID_0),
//             alice,
//             "NFT not minted to correct address"
//         );
//     }

//     function test_mintGenesisNft_Mints3Nft() external {
//         vm.prank(admin);
//         sale.mintGenesisNfts(threeGenesisUsers, threeLevels);

//         assertEq(
//             nft.getNextTokenId(),
//             3,
//             "Token was not minted and ID not changed"
//         );
//         assertEq(nft.balanceOf(alice), 2, "Alice did not receive nft");
//         assertEq(nft.balanceOf(bob), 1, "Bob did not receive nft");
//         assertEq(
//             nft.ownerOf(NFT_TOKEN_ID_0),
//             alice,
//             "NFT not minted to correct address"
//         );
//         assertEq(
//             nft.ownerOf(NFT_TOKEN_ID_1),
//             alice,
//             "NFT not minted to correct address"
//         );
//         assertEq(
//             nft.ownerOf(NFT_TOKEN_ID_2),
//             bob,
//             "NFT not minted to correct address"
//         );
//     }

//     function test_mintGenesisNft_EmitsNftMintedEvent3Times() external {
//         vm.expectEmit(true, true, true, true);
//         emit NftMinted(alice, LEVEL_1, true, 0);

//         vm.expectEmit(true, true, true, true);
//         emit NftMinted(alice, LEVEL_2, true, 0);

//         vm.expectEmit(true, true, true, true);
//         emit NftMinted(bob, LEVEL_3, true, 0);

//         vm.prank(admin);
//         sale.mintGenesisNfts(threeGenesisUsers, threeLevels);
//     }
// }
