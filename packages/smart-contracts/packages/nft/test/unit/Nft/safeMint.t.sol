// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_SafeMint_Unit_Test is Unit_Test {
    function test_safeMint_RevertIf_NotMinter() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                MINTER_ROLE
            )
        );
        vm.prank(alice);
        nft.safeMint(alice, LEVEL_1, false);
    }

    function test_safeMint_RevertIf_ToAddressIsZero() external {
        vm.expectRevert(Errors.Nft__ZeroAddress.selector);
        vm.prank(admin);
        nft.safeMint(ZERO_ADDRESS, LEVEL_1, false);
    }

    function test_safeMint_RevertIf_LevelIsZero() external {
        uint16 level = 0;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Nft__InvalidLevel.selector, level)
        );
        vm.prank(admin);
        nft.safeMint(alice, level, false);
    }

    function test_safeMint_RevertIf_LevelIsTooHigh() external {
        uint16 level = MAX_LEVEL + 1;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Nft__InvalidLevel.selector, level)
        );
        vm.prank(admin);
        nft.safeMint(alice, level, false);
    }

    function test_safeMint_RevertIf_SupplyCapIsReached() external {
        // Simulate: 20 tokens minted
        nft.mock_setNftAmount(LEVEL_5, false, LEVEL_5_SUPPLY_CAP);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Nft__SupplyCapReached.selector,
                LEVEL_5,
                false,
                LEVEL_5_SUPPLY_CAP
            )
        );
        vm.prank(admin);
        nft.safeMint(alice, LEVEL_5, false);
    }

    function test_safeMint_IncreasesNextTokenIdBy1() external {
        vm.prank(admin);
        nft.safeMint(alice, LEVEL_1, false);

        assertEq(nft.getNextTokenId(), 1, "Next token ID not 1");
    }

    function test_safeMint_IncreasesNextTokenIdBy2() external {
        vm.startPrank(admin);
        nft.safeMint(alice, LEVEL_1, false);
        nft.safeMint(bob, LEVEL_2, true);
        vm.stopPrank();

        assertEq(nft.getNextTokenId(), 2, "Next token ID not 1");
    }

    function test_safeMint_IncreasesNextTokenIdBy10()
        external
        mintEachLevelNft
    {
        assertEq(nft.getNextTokenId(), 10, "Next token ID incorrect");
    }

    function test_safeMint_Mints1Token() external {
        vm.prank(admin);
        nft.safeMint(alice, LEVEL_1, false);

        assertEq(nft.ownerOf(NFT_TOKEN_ID_0), alice, "NFT not minted");
        assertEq(nft.balanceOf(alice), 1, "NFT minted to incorrect address");
    }

    function test_safeMint_Mints2TokensFor1User() external {
        vm.startPrank(admin);
        nft.safeMint(alice, LEVEL_1, false);
        nft.safeMint(alice, LEVEL_2, true);
        vm.stopPrank();

        assertEq(nft.ownerOf(NFT_TOKEN_ID_0), alice, "NFT not minted");
        assertEq(nft.ownerOf(NFT_TOKEN_ID_1), alice, "NFT not minted");
        assertEq(nft.balanceOf(alice), 2, "NFT minted to incorrect address");
    }

    function test_safeMint_Mints10TokenFor5Users() external mintEachLevelNft {
        assertEq(nft.ownerOf(NFT_TOKEN_ID_0), alice, "NFT not minted");
        assertEq(nft.ownerOf(NFT_TOKEN_ID_1), bob, "NFT not minted");
        assertEq(nft.ownerOf(NFT_TOKEN_ID_2), carol, "NFT not minted");
        assertEq(nft.ownerOf(NFT_TOKEN_ID_3), dan, "NFT not minted");
        assertEq(nft.ownerOf(NFT_TOKEN_ID_4), eve, "NFT not minted");
        assertEq(nft.ownerOf(5), eve, "NFT not minted");
        assertEq(nft.ownerOf(6), dan, "NFT not minted");
        assertEq(nft.ownerOf(7), carol, "NFT not minted");
        assertEq(nft.ownerOf(8), bob, "NFT not minted");
        assertEq(nft.ownerOf(9), alice, "NFT not minted");

        assertEq(nft.balanceOf(alice), 2, "NFT minted to incorrect address");
        assertEq(nft.balanceOf(bob), 2, "NFT minted to incorrect address");
        assertEq(nft.balanceOf(carol), 2, "NFT minted to incorrect address");
        assertEq(nft.balanceOf(dan), 2, "NFT minted to incorrect address");
        assertEq(nft.balanceOf(eve), 2, "NFT minted to incorrect address");
    }

    function test_safeMint_NftAmountIncreasesBy1() external {
        vm.prank(admin);
        nft.safeMint(alice, LEVEL_1, false);

        assertEq(nft.getLevelData(LEVEL_1, false).nftAmount, 1, "Wrong amount");
    }

    function test_safeMint_NftAmountIncreasesBy2() external {
        vm.startPrank(admin);
        nft.safeMint(alice, LEVEL_1, false);
        nft.safeMint(bob, LEVEL_1, false);
        vm.stopPrank();

        assertEq(nft.getLevelData(LEVEL_1, false).nftAmount, 2, "Wrong amount");
    }

    function test_safeMint_NftAmountIncreasesBy1ForAllLevels()
        external
        mintEachLevelNft
    {
        assertEq(nft.getLevelData(LEVEL_1, false).nftAmount, 1, "Wrong amount");
        assertEq(nft.getLevelData(LEVEL_2, false).nftAmount, 1, "Wrong amount");
        assertEq(nft.getLevelData(LEVEL_3, false).nftAmount, 1, "Wrong amount");
        assertEq(nft.getLevelData(LEVEL_4, false).nftAmount, 1, "Wrong amount");
        assertEq(nft.getLevelData(LEVEL_5, false).nftAmount, 1, "Wrong amount");
        assertEq(nft.getLevelData(LEVEL_1, true).nftAmount, 1, "Wrong amount");
        assertEq(nft.getLevelData(LEVEL_2, true).nftAmount, 1, "Wrong amount");
        assertEq(nft.getLevelData(LEVEL_3, true).nftAmount, 1, "Wrong amount");
        assertEq(nft.getLevelData(LEVEL_4, true).nftAmount, 1, "Wrong amount");
        assertEq(nft.getLevelData(LEVEL_5, true).nftAmount, 1, "Wrong amount");
    }

    function test_safeMint_NftAmountIncreasesBy2ForAllLevels()
        external
        mintEachLevelNft
        mintEachLevelNft
    {
        assertEq(nft.getLevelData(LEVEL_1, false).nftAmount, 2, "Wrong amount");
        assertEq(nft.getLevelData(LEVEL_2, false).nftAmount, 2, "Wrong amount");
        assertEq(nft.getLevelData(LEVEL_3, false).nftAmount, 2, "Wrong amount");
        assertEq(nft.getLevelData(LEVEL_4, false).nftAmount, 2, "Wrong amount");
        assertEq(nft.getLevelData(LEVEL_5, false).nftAmount, 2, "Wrong amount");
        assertEq(nft.getLevelData(LEVEL_1, true).nftAmount, 2, "Wrong amount");
        assertEq(nft.getLevelData(LEVEL_2, true).nftAmount, 2, "Wrong amount");
        assertEq(nft.getLevelData(LEVEL_3, true).nftAmount, 2, "Wrong amount");
        assertEq(nft.getLevelData(LEVEL_4, true).nftAmount, 2, "Wrong amount");
        assertEq(nft.getLevelData(LEVEL_5, true).nftAmount, 2, "Wrong amount");
    }

    function test_safeMint_SetsTokenURI() external {
        vm.prank(admin);
        nft.safeMint(alice, LEVEL_1, false);

        string memory expectedURI = string.concat(
            LEVEL_1_BASE_URI,
            "0",
            NFT_URI_SUFFIX
        );
        assertEq(nft.tokenURI(NFT_TOKEN_ID_0), expectedURI, "Wrong token URI");
    }

    function test_safeMint_SetsTokenURIForAllLevels()
        external
        mintEachLevelNft
    {
        string memory expectedURI;

        expectedURI = string.concat(LEVEL_1_BASE_URI, "0", NFT_URI_SUFFIX);
        assertEq(nft.tokenURI(NFT_TOKEN_ID_0), expectedURI, "Wrong token URI");

        expectedURI = string.concat(LEVEL_2_BASE_URI, "0", NFT_URI_SUFFIX);
        assertEq(nft.tokenURI(NFT_TOKEN_ID_1), expectedURI, "Wrong token URI");

        expectedURI = string.concat(LEVEL_3_BASE_URI, "0", NFT_URI_SUFFIX);
        assertEq(nft.tokenURI(NFT_TOKEN_ID_2), expectedURI, "Wrong token URI");

        expectedURI = string.concat(LEVEL_4_BASE_URI, "0", NFT_URI_SUFFIX);
        assertEq(nft.tokenURI(NFT_TOKEN_ID_3), expectedURI, "Wrong token URI");

        expectedURI = string.concat(LEVEL_5_BASE_URI, "0", NFT_URI_SUFFIX);
        assertEq(nft.tokenURI(NFT_TOKEN_ID_4), expectedURI, "Wrong token URI");

        expectedURI = string.concat(
            LEVEL_1_GENESIS_BASE_URI,
            "0",
            NFT_URI_SUFFIX
        );
        assertEq(nft.tokenURI(5), expectedURI, "Wrong token URI");

        expectedURI = string.concat(
            LEVEL_2_GENESIS_BASE_URI,
            "0",
            NFT_URI_SUFFIX
        );
        assertEq(nft.tokenURI(6), expectedURI, "Wrong token URI");

        expectedURI = string.concat(
            LEVEL_3_GENESIS_BASE_URI,
            "0",
            NFT_URI_SUFFIX
        );
        assertEq(nft.tokenURI(7), expectedURI, "Wrong token URI");

        expectedURI = string.concat(
            LEVEL_4_GENESIS_BASE_URI,
            "0",
            NFT_URI_SUFFIX
        );
        assertEq(nft.tokenURI(8), expectedURI, "Wrong token URI");

        expectedURI = string.concat(
            LEVEL_5_GENESIS_BASE_URI,
            "0",
            NFT_URI_SUFFIX
        );
        assertEq(nft.tokenURI(9), expectedURI, "Wrong token URI");
    }

    function test_safeMint_EmitsNftMintedEvent() external {
        vm.expectEmit(true, true, true, true);
        emit NftMinted(alice, NFT_TOKEN_ID_0, LEVEL_1, false, NFT_TOKEN_ID_0);

        vm.prank(admin);
        nft.safeMint(alice, LEVEL_1, false);
    }
}
