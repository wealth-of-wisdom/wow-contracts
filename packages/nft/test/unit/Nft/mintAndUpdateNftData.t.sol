// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {INft} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_MintAndUpdateNftData_Unit_Test is Unit_Test {
    function test_mintAndUpdateNftData_RevertIf_NotNftDataManager() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                NFT_DATA_MANAGER_ROLE
            )
        );
        vm.prank(alice);
        nft.mintAndUpdateNftData(alice, NFT_TOKEN_ID_0, LEVEL_3);
    }

    function test_mintAndUpdateNftData_DeactivatesOldNft()
        external
        mintLevel2NftForAlice
    {
        vm.prank(admin);
        nft.mintAndUpdateNftData(alice, NFT_TOKEN_ID_0, LEVEL_3);

        INft.NftData memory nftData = nft.getNftData(NFT_TOKEN_ID_0);
        assertEq(nftData.level, LEVEL_2);
        assertEq(nftData.isGenesis, false);
        assertEq(uint8(nftData.activityType), uint8(NFT_DEACTIVATED));
        assertEq(nftData.activityEndTimestamp, 0);
        assertEq(nftData.extendedActivityEndTimestamp, 0);
    }

    function test_mintAndUpdateNftData_SetsNftDataForNewNft()
        external
        mintLevel2NftForAlice
    {
        vm.prank(admin);
        nft.mintAndUpdateNftData(alice, NFT_TOKEN_ID_0, LEVEL_3);

        INft.NftData memory nftData = nft.getNftData(NFT_TOKEN_ID_1);
        assertEq(nftData.level, LEVEL_3);
        assertEq(nftData.isGenesis, false);
        assertEq(uint8(nftData.activityType), uint8(NFT_NOT_ACTIVATED));
        assertEq(nftData.activityEndTimestamp, 0);
        assertEq(nftData.extendedActivityEndTimestamp, 0);
    }

    function test_mintAndUpdateNftData_MintsNewNft()
        external
        mintLevel2NftForAlice
    {
        vm.prank(admin);
        nft.mintAndUpdateNftData(alice, NFT_TOKEN_ID_0, LEVEL_3);

        assertEq(nft.ownerOf(NFT_TOKEN_ID_0), alice);
        assertEq(nft.ownerOf(NFT_TOKEN_ID_1), alice);
        assertEq(nft.balanceOf(alice), 2);
    }
}
