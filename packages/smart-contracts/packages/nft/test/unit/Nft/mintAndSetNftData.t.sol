// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {INft} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_MintAndSetNftData_Unit_Test is Unit_Test {
    address internal minter = makeAddr("minter");
    address internal nftDataManager = makeAddr("nftDataManager");

    function setUp() public virtual override {
        Unit_Test.setUp();

        vm.startPrank(admin);
        nft.grantRole(MINTER_ROLE, minter);
        nft.grantRole(NFT_DATA_MANAGER_ROLE, nftDataManager);
        vm.stopPrank();
    }

    function test_mintAndSetNftData_RevertIf_NotNftDataManagerAndMinter()
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
        nft.mintAndSetNftData(alice, LEVEL_1, false);
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
        nft.mintAndSetNftData(alice, LEVEL_1, false);
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
        nft.mintAndSetNftData(alice, LEVEL_1, false);
    }

    function test_mintAndSetNftData_RevertIf_ReceiverAddressIsZero() external {
        vm.expectRevert(Errors.Nft__ZeroAddress.selector);
        vm.prank(admin);
        nft.mintAndSetNftData(ZERO_ADDRESS, LEVEL_1, false);
    }

    function test_mintAndSetNftData_RevertIf_LevelIsZero() external {
        uint16 level = 0;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Nft__InvalidLevel.selector, level)
        );
        vm.prank(admin);
        nft.mintAndSetNftData(alice, level, false);
    }

    function test_mintAndSetNftData_RevertIf_LevelIsTooHigh() external {
        uint16 level = MAX_LEVEL + 1;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Nft__InvalidLevel.selector, level)
        );
        vm.prank(admin);
        nft.mintAndSetNftData(alice, level, false);
    }

    function test_mintAndSetNftData_SetsNftData() external {
        vm.prank(admin);
        nft.mintAndSetNftData(alice, LEVEL_1, false);

        INft.NftData memory nftData = nft.getNftData(NFT_TOKEN_ID_0);
        assertEq(nftData.level, LEVEL_1);
        assertEq(nftData.isGenesis, false);
        assertEq(uint8(nftData.activityType), uint8(NFT_NOT_ACTIVATED));
        assertEq(nftData.activityEndTimestamp, 0);
        assertEq(nftData.extendedActivityEndTimestamp, 0);
    }

    function test_mintAndSetNftData_MintsNewNft() external {
        vm.prank(admin);
        nft.mintAndSetNftData(alice, LEVEL_1, false);

        assertEq(nft.ownerOf(NFT_TOKEN_ID_0), alice);
        assertEq(nft.balanceOf(alice), 1);
    }
}
