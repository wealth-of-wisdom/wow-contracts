// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console2} from "forge-std/Test.sol";
import {INft} from "../../contracts/interfaces/INft.sol";
import {Base_Test} from "../Base.t.sol";

contract Nft_Fuzz_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();

        _setNftLevels();
    }

    function testFuzz_mintAndSetNftData_MintsNewNftAndSetsData(
        address receiver,
        uint16 level,
        bool isGenesis
    ) external {
        vm.assume(receiver != ZERO_ADDRESS);
        level = uint16(bound(level, 1, MAX_LEVEL));

        vm.prank(admin);
        nft.mintAndSetNftData(receiver, level, isGenesis);

        INft.NftData memory nftData = nft.getNftData(NFT_TOKEN_ID_0);
        string memory uri = string.concat(
            isGenesis ? GENESIS_BASE_URIS[level - 1] : BASE_URIS[level - 1],
            "0",
            NFT_URI_SUFFIX
        );

        assertEq(nftData.level, level, "level");
        assertEq(nftData.isGenesis, isGenesis, "isGenesis");
        assertEq(
            uint8(nftData.activityType),
            uint8(NFT_NOT_ACTIVATED),
            "activityType"
        );
        assertEq(nftData.activityEndTimestamp, 0, "activityEndTimestamp");
        assertEq(
            nftData.extendedActivityEndTimestamp,
            0,
            "extendedActivityEndTimestamp"
        );
        assertEq(nft.tokenURI(NFT_TOKEN_ID_0), uri, "tokenURI");
        assertEq(nft.getNextTokenId(), 1, "getNextTokenId");
        assertEq(nft.balanceOf(receiver), 1, "balanceOf");
        assertEq(nft.ownerOf(NFT_TOKEN_ID_0), receiver, "ownerOf");
    }

    function testFuzz_mintAndUpdateNftData_MintsNewNftAndUpdatesData(
        address receiver,
        uint16 level,
        uint16 newLevel
    ) external {
        vm.assume(receiver != ZERO_ADDRESS);
        level = uint16(bound(level, 1, MAX_LEVEL - 1));
        newLevel = uint16(bound(newLevel, level + 1, MAX_LEVEL));

        vm.startPrank(admin);
        nft.mintAndSetNftData(receiver, level, false);
        nft.mintAndUpdateNftData(receiver, NFT_TOKEN_ID_0, newLevel);
        vm.stopPrank();

        INft.NftData memory nftData = nft.getNftData(NFT_TOKEN_ID_1);
        string memory uri = string.concat(
            BASE_URIS[newLevel - 1],
            "0",
            NFT_URI_SUFFIX
        );

        assertEq(nftData.level, newLevel, "level");
        assertFalse(nftData.isGenesis, "isGenesis");
        assertEq(
            uint8(nftData.activityType),
            uint8(NFT_NOT_ACTIVATED),
            "activityType"
        );
        assertEq(nftData.activityEndTimestamp, 0, "activityEndTimestamp");
        assertEq(
            nftData.extendedActivityEndTimestamp,
            0,
            "extendedActivityEndTimestamp"
        );
        assertEq(nft.tokenURI(NFT_TOKEN_ID_1), uri, "tokenURI");
        assertEq(nft.getNextTokenId(), 2, "getNextTokenId");
        assertEq(nft.balanceOf(receiver), 2, "balanceOf");
        assertEq(nft.ownerOf(NFT_TOKEN_ID_1), receiver, "ownerOf");
    }
}
