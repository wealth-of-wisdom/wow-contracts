// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_SetProjectsQuantity_Unit_Test is Unit_Test {
    function test_setProjectsQuantity_RevertIf_NotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        nft.setProjectsQuantity(LEVEL_5, false, PROJECT_TYPE_STANDARD, 10);
    }

    function test_setProjectsQuantity_RevertIf_LevelIsZero() external {
        uint16 level = 0;

        vm.expectRevert(
            abi.encodeWithSelector(Errors.Nft__InvalidLevel.selector, level)
        );
        vm.prank(admin);
        nft.setProjectsQuantity(level, false, PROJECT_TYPE_STANDARD, 10);
    }

    function test_setProjectsQuantity_RevertIf_LevelIsTooHigh() external {
        uint16 level = MAX_LEVEL + 1;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Nft__InvalidLevel.selector, level)
        );
        vm.prank(admin);
        nft.setProjectsQuantity(level, false, PROJECT_TYPE_STANDARD, 10);
    }

    function test_setProjectsQuantity_RevertIf_ProjectTypeIsUnsupported()
        external
    {
        uint8 project = TOTAL_PROJECT_TYPES;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Nft__InvalidProjectType.selector,
                project
            )
        );
        vm.prank(admin);
        nft.setProjectsQuantity(LEVEL_5, false, project, 10);
    }

    function test_setProjectsQuantity_SetsQuantity() external {
        uint16 actualQuantity = 10;

        vm.prank(admin);
        nft.setProjectsQuantity(LEVEL_5, false, PROJECT_TYPE_STANDARD, actualQuantity);

        uint256 quantity = nft.getProjectsQuantity(
            LEVEL_5,
            false,
            PROJECT_TYPE_STANDARD
        );
        assertEq(quantity, actualQuantity);
    }

    function test_setProjectsQuantity_EmitsProjectsQuantitySetEvent() external {
        uint16 actualQuantity = 10;

        vm.expectEmit(true, true, true, true);
        emit ProjectsQuantitySet(
            LEVEL_5,
            false,
            PROJECT_TYPE_STANDARD,
            actualQuantity
        );

        vm.prank(admin);
        nft.setProjectsQuantity(LEVEL_5, false, PROJECT_TYPE_STANDARD, actualQuantity);
    }
}
