// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_SetTotalProjectTypes_Unit_Test is Unit_Test {
    function test_setTotalProjectTypes_RevertIf_NotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        nft.setTotalProjectTypes(TOTAL_PROJECT_TYPES + 1);
    }

    function test_setTotalProjectTypes_RevertIf_NewTotalIsTooLow() external {
        uint8 newTotal = TOTAL_PROJECT_TYPES - 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Nft__InvalidTotalProjectTypes.selector,
                newTotal
            )
        );
        vm.prank(admin);
        nft.setTotalProjectTypes(newTotal);
    }

    function test_setTotalProjectTypes_SetsTotalProjectTypes() external {
        uint8 newTotal = TOTAL_PROJECT_TYPES * 2;

        vm.prank(admin);
        nft.setTotalProjectTypes(newTotal);

        uint256 actualTotal = nft.getTotalProjectTypes();
        assertEq(actualTotal, newTotal);
    }

    function test_setTotalProjectTypes_EmitsTotalProjectTypesSetEvent()
        external
    {
        uint8 newTotal = TOTAL_PROJECT_TYPES * 2;

        vm.expectEmit(true, true, true, true);
        emit TotalProjectTypesSet(newTotal);

        vm.prank(admin);
        nft.setTotalProjectTypes(newTotal);
    }
}
