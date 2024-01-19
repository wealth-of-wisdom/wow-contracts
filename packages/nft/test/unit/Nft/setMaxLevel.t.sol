// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INft, INftEvents} from "@wealth-of-wisdom/nft/contracts/interfaces/INft.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {Nft_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftUnit.t.sol";

contract NftSale_SetMaxLevel_Unit_Test is INftEvents, Nft_Unit_Test {
    function test_setMaxLevel_RevertIf_NotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        nftContract.setMaxLevel(LEVEL_2);
    }

    function test_setMaxLevel_RevertIf_InvalidMaxLevel() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Nft__InvalidMaxLevel.selector,
                LEVEL_2
            )
        );
        vm.prank(admin);
        nftContract.setMaxLevel(LEVEL_2);
    }

    function test_setMaxLevel_setsNewMaxLevel() external {
        uint16 newLevel = 10;

        vm.prank(admin);
        nftContract.setMaxLevel(newLevel);

        assertEq(nftContract.getMaxLevel(), newLevel, "New level not set");
    }

    function test_setMaxLevel_EmitsMaxLevelSetEvent() external {
        uint16 newLevel = 10;

        vm.expectEmit(true, true, true, true);
        emit MaxLevelSet(newLevel);

        vm.prank(admin);
        nftContract.setMaxLevel(newLevel);
    }
}
