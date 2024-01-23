// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {INft} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_MintAndSetNftData_Unit_Test is Unit_Test {
    function test_mintAndSetNftData_RevertIf_NotNftDataManager() external {
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
