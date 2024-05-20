// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {INft} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_MintAndUpdateNftData_Unit_Test is Unit_Test {
    address internal minter = makeAddr("minter");
    address internal nftDataManager = makeAddr("nftDataManager");

    function setUp() public virtual override {
        Unit_Test.setUp();

        vm.startPrank(admin);
        nft.grantRole(MINTER_ROLE, minter);
        nft.grantRole(NFT_DATA_MANAGER_ROLE, nftDataManager);
        vm.stopPrank();
    }

    function test_mintAndUpdateNftData_RevertIf_NotNftDataManagerAndMinter()
        external
    {
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

    function test_mintAndSetNftData_RevertIf_SenderIsOnlyMinter() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                minter,
                NFT_DATA_MANAGER_ROLE
            )
        );
        vm.prank(minter);
        nft.mintAndUpdateNftData(alice, NFT_TOKEN_ID_0, LEVEL_2);
    }

    function test_mintAndSetNftData_RevertIf_SenderIsOnlyNftDataManager()
        external
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                nftDataManager,
                MINTER_ROLE
            )
        );
        vm.prank(nftDataManager);
        nft.mintAndUpdateNftData(alice, NFT_TOKEN_ID_0, LEVEL_2);
    }

    function test_mintAndUpdateNftData_RevertIf_ReceiverAddressIsZero()
        external
        mintLevel2NftForAlice
    {
        vm.expectRevert(Errors.Nft__ReceiverNotOwner.selector);
        vm.prank(admin);
        nft.mintAndUpdateNftData(ZERO_ADDRESS, NFT_TOKEN_ID_0, LEVEL_3);
    }

    function test_mintAndUpdateNftData_RevertIf_LevelIsZero()
        external
        mintLevel2NftForAlice
    {
        uint16 level = 0;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Nft__InvalidLevel.selector, level)
        );
        vm.prank(admin);
        nft.mintAndUpdateNftData(alice, NFT_TOKEN_ID_0, level);
    }

    function test_mintAndUpdateNftData_RevertIf_LevelIsTooHigh()
        external
        mintLevel2NftForAlice
    {
        uint16 level = MAX_LEVEL + 1;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Nft__InvalidLevel.selector, level)
        );
        vm.prank(admin);
        nft.mintAndUpdateNftData(alice, NFT_TOKEN_ID_0, level);
    }

    function test_mintAndUpdateNftData_RevertIf_ReceiverNotOwnerOfOldNft()
        external
        mintLevel2NftForAlice
    {
        vm.expectRevert(Errors.Nft__ReceiverNotOwner.selector);
        vm.prank(admin);
        nft.mintAndUpdateNftData(bob, NFT_TOKEN_ID_0, LEVEL_3);
    }

    function test_mintAndUpdateNftData_RevertIf_NftDoesNotExist() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC721Errors.ERC721NonexistentToken.selector,
                NFT_TOKEN_ID_0
            )
        );
        vm.prank(admin);
        nft.mintAndUpdateNftData(bob, NFT_TOKEN_ID_0, LEVEL_3);
    }

    function test_mintAndUpdateNftData_RevertIf_OldNftIsGenesis() external {
        vm.startPrank(admin);
        nft.mintAndSetNftData(alice, LEVEL_1, true);

        vm.expectRevert(Errors.Nft__GenesisNftNotUpdatable.selector);
        nft.mintAndUpdateNftData(alice, NFT_TOKEN_ID_0, LEVEL_3);
        vm.stopPrank();
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

    function test_mintAndUpdateNftData_DeletesPreviousActiveNft()
        external
        mintLevel2NftForAlice
        mintLevel2NftForAlice
    {
        vm.prank(admin);
        nft.mintAndUpdateNftData(alice, NFT_TOKEN_ID_1, LEVEL_3);

        assertEq(nft.getActiveNft(alice), 0, "Active NFT ID is incorrect");
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
