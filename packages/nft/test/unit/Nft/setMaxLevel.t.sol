// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_SetMaxLevel_Unit_Test is Unit_Test {
    function test_setMaxLevel_RevertIf_NotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        nft.setMaxLevel(LEVEL_4);
    }

    function test_setMaxLevel_RevertIf_InvalidMaxLevel() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Nft__InvalidMaxLevel.selector,
                LEVEL_4
            )
        );
        vm.prank(admin);
        nft.setMaxLevel(LEVEL_4);
    }

    function test_setMaxLevel_SetsNewMaxLevel() external {
        uint16 newLevel = 10;

        vm.prank(admin);
        nft.setMaxLevel(newLevel);

        assertEq(nft.getMaxLevel(), newLevel, "New level not set");
    }

    function test_setMaxLevel_EmitsMaxLevelSetEvent() external {
        uint16 newLevel = 10;

        vm.expectEmit(true, true, true, true);
        emit MaxLevelSet(newLevel);

        vm.prank(admin);
        nft.setMaxLevel(newLevel);
    }
}
