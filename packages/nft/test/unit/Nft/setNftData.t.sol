// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {INft} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_SetNftData_Unit_Test is Unit_Test {
    function test_setNftData_RevertIf_NotNftDataManager() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                NFT_DATA_MANAGER_ROLE
            )
        );
        vm.prank(alice);
        nft.setNftData(
            NFT_TOKEN_ID_0,
            LEVEL_1,
            false,
            NFT_NOT_ACTIVATED,
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            block.timestamp +
                LEVEL_1_LIFECYCLE_DURATION +
                LEVEL_1_EXTENSION_DURATION
        );
    }

    function test_setNftData_RevertIf_LevelIsZero() external {
        uint16 level = 0;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Nft__InvalidLevel.selector, level)
        );
        vm.prank(admin);
        nft.setNftData(
            NFT_TOKEN_ID_0,
            level,
            false,
            NFT_NOT_ACTIVATED,
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            block.timestamp +
                LEVEL_1_LIFECYCLE_DURATION +
                LEVEL_1_EXTENSION_DURATION
        );
    }

    function test_setNftData_RevertIf_LevelIsTooHigh() external {
        uint16 level = MAX_LEVEL + 1;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Nft__InvalidLevel.selector, level)
        );
        vm.prank(admin);
        nft.setNftData(
            NFT_TOKEN_ID_0,
            level,
            false,
            NFT_NOT_ACTIVATED,
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            block.timestamp +
                LEVEL_1_LIFECYCLE_DURATION +
                LEVEL_1_EXTENSION_DURATION
        );
    }

    function test_setNftData_SetsAllDataCorrectly() external {
        vm.prank(admin);
        nft.setNftData(
            NFT_TOKEN_ID_0,
            LEVEL_1,
            false,
            NFT_NOT_ACTIVATED,
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            block.timestamp +
                LEVEL_1_LIFECYCLE_DURATION +
                LEVEL_1_EXTENSION_DURATION
        );

        INft.NftData memory nftData = nft.getNftData(NFT_TOKEN_ID_0);

        assertEq(nftData.level, LEVEL_1, "Level data not set");
        assertFalse(nftData.isGenesis, "Genesis data not set");
        assertEq(
            uint8(nftData.activityType),
            uint8(NFT_NOT_ACTIVATED),
            "Activity type not set"
        );
        assertEq(
            nftData.activityEndTimestamp,
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            "Activity end timestamp not set"
        );
        assertEq(
            nftData.extendedActivityEndTimestamp,
            block.timestamp +
                LEVEL_1_LIFECYCLE_DURATION +
                LEVEL_1_EXTENSION_DURATION,
            "Activity extension end timestamp not set"
        );
    }

    function test_setNftData_EmitsNftDataSetEvent() external {
        vm.expectEmit(true, true, true, true);
        emit NftDataSet(
            NFT_TOKEN_ID_0,
            LEVEL_1,
            false,
            uint256(NFT_NOT_ACTIVATED),
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            block.timestamp +
                LEVEL_1_LIFECYCLE_DURATION +
                LEVEL_1_EXTENSION_DURATION
        );

        vm.prank(admin);
        nft.setNftData(
            NFT_TOKEN_ID_0,
            LEVEL_1,
            false,
            NFT_NOT_ACTIVATED,
            block.timestamp + LEVEL_1_LIFECYCLE_DURATION,
            block.timestamp +
                LEVEL_1_LIFECYCLE_DURATION +
                LEVEL_1_EXTENSION_DURATION
        );
    }
}
