// function test_updateBand_TransferNftAndUpdateBand()
//     external
//     mintLevel2BandForAlice
// {
//     assertEq(nftContract.balanceOf(admin), 0, "NFT pre-minted to admin");
//     assertEq(nftContract.balanceOf(alice), 1, "NFT not pre-minted to alice");

//     uint256 newPrice = sale.getLevelPriceInUSD(LEVEL_3);
//     uint256 oldPrice = sale.getLevelPriceInUSD(DEFAULT_LEVEL_2);
//     uint256 upgradePrice = newPrice - oldPrice;

//     vm.prank(admin);
//     nftContract.grantRole(MINTER_ROLE, address(alice));

//     vm.prank(alice);
//     nftContract.safeTransferFrom(alice, admin, NFT_TOKEN_ID_0);

//     assertEq(
//         nftContract.balanceOf(admin),
//         1,
//         "NFT transfered to incorrect address"
//     );
//     assertEq(
//         nftContract.balanceOf(alice),
//         0,
//         "NFT transfered to incorrect address"
//     );

//     vm.startPrank(admin);
//     tokenUSDT.approve(address(sale), upgradePrice);
//     sale.updateBand(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
//     vm.stopPrank();

//     INftSale.Band memory starterBandData = sale.getBand(NFT_TOKEN_ID_0);
//     INftSale.Band memory newBandData = sale.getBand(NFT_TOKEN_ID_1);

//     assertEq(
//         nftContract.getNextTokenId(),
//         NFT_TOKEN_ID_1 + 1,
//         "Token was not minted and ID not changed"
//     );
//     assertEq(
//         uint8(starterBandData.activityType),
//         uint8(NFT_ACTIVITY_TYPE_DEACTIVATED),
//         "Band not deactivated"
//     );
//     assertEq(
//         uint8(newBandData.activityType),
//         uint8(NFT_ACTIVITY_TYPE_INACTIVE),
//         "Band not activated"
//     );
//     assertFalse(starterBandData.isGenesis, "Band set as genesis");
//     assertEq(newBandData.level, LEVEL_3, "Band level set incorrectly");
//     assertEq(
//         nftContract.ownerOf(NFT_TOKEN_ID_0),
//         admin,
//         "User did not receive new nft"
//     );
//     assertEq(
//         tokenUSDT.balanceOf(address(sale)),
//         oldPrice + upgradePrice,
//         "Funds not transfered"
//     );
// }
