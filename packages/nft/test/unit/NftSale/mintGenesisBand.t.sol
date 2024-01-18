// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.20;

// import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
// import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
// import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
// import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
// import {NftSale_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftSaleUnit.t.sol";

// contract NftSale_MintGenesisBand_Unit_Test is NftSale_Unit_Test {
//     function assertGenesisBand(
//         INftSale.NftData memory band,
//         uint16 level
//     ) internal {
//         assertEq(band.level, level, "Band level set incorrectly");
//         assertEq(
//             uint8(band.activityType),
//             uint8(NFT_ACTIVITY_TYPE_NOT_ACTIVATED),
//             "Band not activated"
//         );
//         assertTrue(band.isGenesis, "Band not set as genesis");
//     }

//     function test_mintGenesisBand_RevertIf_NotDefaultAdmin() external {
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 IAccessControl.AccessControlUnauthorizedAccount.selector,
//                 alice,
//                 DEFAULT_ADMIN_ROLE
//             )
//         );
//         vm.prank(alice);
//         sale.mintGenesisBand(alice, LEVEL_2, DEFAULT_GENESIS_AMOUNT);
//     }

//     function test_mintGenesisBand_RevertIf_ReceiverIsZeroAddress() external {
//         vm.expectRevert(Errors.Nft__ZeroAddress.selector);
//         vm.prank(admin);
//         sale.mintGenesisBand(
//             ZERO_ADDRESS,
//             LEVEL_2,
//             DEFAULT_GENESIS_AMOUNT
//         );
//     }

//     function test_mintGenesisBand_RevertIf_InvalidLevel() external {
//         uint16 fakeLevel = 16;
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 Errors.NftSale__InvalidLevel.selector,
//                 fakeLevel
//             )
//         );
//         vm.prank(admin);
//         sale.mintGenesisBand(alice, fakeLevel, DEFAULT_GENESIS_AMOUNT);
//     }

//     function test_mintGenesisBand_RevertIf_PassedZeroAmount() external {
//         vm.expectRevert(Errors.Nft__PassedZeroAmount.selector);
//         vm.prank(admin);
//         sale.mintGenesisBand(alice, LEVEL_2, 0);
//     }

//     function test_mintGenesisBand_Creates1NewBand() external {
//         vm.prank(admin);
//         sale.mintGenesisBand(alice, LEVEL_2, 1);

//         INftSale.NftData memory nftData = sale.getNftData(NFT_TOKEN_ID_0);
//         assertGenesisBand(nftData, LEVEL_2);
//     }

//     function test_mintGenesisBand_Creates5NewBands() external {
//         vm.prank(admin);
//         sale.mintGenesisBand(alice, LEVEL_2, DEFAULT_GENESIS_AMOUNT);

//         INftSale.NftData memory nftData = sale.getNftData(NFT_TOKEN_ID_0);
//         assertGenesisBand(nftData, LEVEL_2);

//         assertGenesisBand(sale.getNftData(NFT_TOKEN_ID_0), LEVEL_2);
//         assertGenesisBand(sale.getNftData(NFT_TOKEN_ID_1), LEVEL_2);
//         assertGenesisBand(sale.getNftData(NFT_TOKEN_ID_2), LEVEL_2);
//         assertGenesisBand(sale.getNftData(3), LEVEL_2);
//         assertGenesisBand(sale.getNftData(4), LEVEL_2);
//     }

//     function test_mintGenesisBand_Mints1Nft() external {
//         vm.prank(admin);
//         sale.mintGenesisBand(alice, LEVEL_2, 1);

//         assertEq(
//             nftContract.getNextTokenId(),
//             NFT_TOKEN_ID_1,
//             "Token was not minted and ID not changed"
//         );
//         assertEq(nftContract.balanceOf(alice), 1, "User did not receive nft");
//         assertEq(
//             nftContract.ownerOf(NFT_TOKEN_ID_0),
//             alice,
//             "NFT not minted to correct address"
//         );
//     }

//     function test_mintGenesisBand_Mints5Nft() external {
//         vm.prank(admin);
//         sale.mintGenesisBand(alice, LEVEL_2, DEFAULT_GENESIS_AMOUNT);

//         assertEq(
//             nftContract.getNextTokenId(),
//             5,
//             "Token was not minted and ID not changed"
//         );
//         assertEq(nftContract.balanceOf(alice), 5, "User did not receive nft");
//         assertEq(
//             nftContract.ownerOf(NFT_TOKEN_ID_0),
//             alice,
//             "NFT not minted to correct address"
//         );
//         assertEq(
//             nftContract.ownerOf(NFT_TOKEN_ID_1),
//             alice,
//             "NFT not minted to correct address"
//         );
//         assertEq(
//             nftContract.ownerOf(NFT_TOKEN_ID_2),
//             alice,
//             "NFT not minted to correct address"
//         );
//         assertEq(
//             nftContract.ownerOf(3),
//             alice,
//             "NFT not minted to correct address"
//         );
//         assertEq(
//             nftContract.ownerOf(4),
//             alice,
//             "NFT not minted to correct address"
//         );
//     }

//     function test_mintGenesisBand_EmitsBandMintedEvent5Times() external {
//         vm.expectEmit(true, true, true, true);
//         emit NftMinted(alice, NFT_TOKEN_ID_0, LEVEL_2, true);

//         vm.expectEmit(true, true, true, true);
//         emit NftMinted(alice, NFT_TOKEN_ID_1, LEVEL_2, true);

//         vm.expectEmit(true, true, true, true);
//         emit NftMinted(alice, NFT_TOKEN_ID_2, LEVEL_2, true);

//         vm.expectEmit(true, true, true, true);
//         emit NftMinted(alice, 3, LEVEL_2, true);

//         vm.expectEmit(true, true, true, true);
//         emit NftMinted(alice, 4, LEVEL_2, true);

//         vm.prank(admin);
//         sale.mintGenesisBand(alice, LEVEL_2, DEFAULT_GENESIS_AMOUNT);
//     }
// }
