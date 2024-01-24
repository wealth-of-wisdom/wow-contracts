// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {INft} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_SetMultipleProjectsQuantity_Unit_Test is Unit_Test {
    uint16[] internal quantities = [1, 2, 3, 4, 5];

    function test_setMultipleProjectsQuantity_RevertIf_NotDefaultAdmin()
        external
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        nft.setMultipleProjectsQuantity(
            false,
            PROJECT_TYPE_STANDARD,
            quantities
        );
    }

    function test_setMultipleProjectsQuantity_RevertIf_ArrayLengthsMismatch()
        external
    {
        quantities.push(6);

        vm.expectRevert(Errors.Nft__MismatchInVariableLength.selector);
        vm.prank(admin);
        nft.setMultipleProjectsQuantity(
            false,
            PROJECT_TYPE_STANDARD,
            quantities
        );
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
        nft.setMultipleProjectsQuantity(false, project, quantities);
    }

    function test_setProjectsQuantity_SetsAllQuantities() external {
        vm.prank(admin);
        nft.setMultipleProjectsQuantity(
            false,
            PROJECT_TYPE_STANDARD,
            quantities
        );

        uint256 level1Quantity = nft.getProjectsQuantity(
            LEVEL_1,
            false,
            PROJECT_TYPE_STANDARD
        );
        uint256 level2Quantity = nft.getProjectsQuantity(
            LEVEL_2,
            false,
            PROJECT_TYPE_STANDARD
        );
        uint256 level3Quantity = nft.getProjectsQuantity(
            LEVEL_3,
            false,
            PROJECT_TYPE_STANDARD
        );
        uint256 level4Quantity = nft.getProjectsQuantity(
            LEVEL_4,
            false,
            PROJECT_TYPE_STANDARD
        );
        uint256 level5Quantity = nft.getProjectsQuantity(
            LEVEL_5,
            false,
            PROJECT_TYPE_STANDARD
        );

        assertEq(level1Quantity, quantities[0], "Level 1 quantity mismatch");
        assertEq(level2Quantity, quantities[1], "Level 2 quantity mismatch");
        assertEq(level3Quantity, quantities[2], "Level 3 quantity mismatch");
        assertEq(level4Quantity, quantities[3], "Level 4 quantity mismatch");
        assertEq(level5Quantity, quantities[4], "Level 5 quantity mismatch");
    }

    function test_setProjectsQuantity_EmitsProjectsQuantitySetEvent5Times()
        external
    {

        vm.expectEmit(true, true, true, true);
        emit ProjectsQuantitySet(
            LEVEL_1,
            false,
            PROJECT_TYPE_STANDARD,
            quantities[0]
        );

        vm.expectEmit(true, true, true, true);
        emit ProjectsQuantitySet(
            LEVEL_2,
            false,
            PROJECT_TYPE_STANDARD,
            quantities[1]
        );

        vm.expectEmit(true, true, true, true);
        emit ProjectsQuantitySet(
            LEVEL_3,
            false,
            PROJECT_TYPE_STANDARD,
            quantities[2]
        );

        vm.expectEmit(true, true, true, true);
        emit ProjectsQuantitySet(
            LEVEL_4,
            false,
            PROJECT_TYPE_STANDARD,
            quantities[3]
        );

        vm.expectEmit(true, true, true, true);
        emit ProjectsQuantitySet(
            LEVEL_5,
            false,
            PROJECT_TYPE_STANDARD,
            quantities[4]
        );

        vm.prank(admin);
        nft.setMultipleProjectsQuantity(
            false,
            PROJECT_TYPE_STANDARD,
            quantities
        );
    }
}
