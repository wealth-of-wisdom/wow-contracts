// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_SetPromotionalVestingPID_Unit_Test is Unit_Test {
    uint16 internal constant NEW_PROMOTIONAL_VESTING_PID = 4;

    function test_setPromotionalVestingPID_RevertIf_NotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        nft.setPromotionalVestingPID(NEW_PROMOTIONAL_VESTING_PID);
    }

    function test_setPromotionalVestingPID_SetsVestingPID() external {
        vm.prank(admin);
        nft.setPromotionalVestingPID(NEW_PROMOTIONAL_VESTING_PID);
        assertEq(
            nft.getPromotionalPID(),
            NEW_PROMOTIONAL_VESTING_PID,
            "New vesting pool id set incorrectly"
        );
    }

    function test_setPromotionalVestingPIDdd_EmitsPromotionalVestingPIDSetEvent()
        external
    {
        vm.expectEmit(true, true, true, true);
        emit PromotionalVestingPIDSet(NEW_PROMOTIONAL_VESTING_PID);

        vm.prank(admin);
        nft.setPromotionalVestingPID(NEW_PROMOTIONAL_VESTING_PID);
    }
}
