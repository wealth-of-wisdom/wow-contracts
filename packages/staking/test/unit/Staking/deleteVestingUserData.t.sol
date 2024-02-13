// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";
import {IStaking} from "../../../contracts/interfaces/IStaking.sol";

contract Staking_DeleteVestingUserData_Unit_Test is Unit_Test {
    function test_deleteVestingUserData_RevertIf_NotVestingContract() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_VESTING_ROLE
            )
        );
        vm.prank(alice);
        staking.deleteVestingUserData(alice);
    }

    function test_deleteVestingUserData_DeletesStakerData()
        external
        grantVestingRole
        setBandLevelData
        stakeTokens
    {
        uint256 currentTimestamp = 100;
        vm.warp(currentTimestamp);

        vm.startPrank(alice);
        staking.deleteVestingUserData(alice);
        (
            ,
            ,
            address owner,
            uint16 bandLevel,
            uint256 stakingStartTimestamp,
            ,

        ) = staking.getStakerBandData(FIRST_STAKED_BAND_ID);

        assertEq(owner, address(0), "Owner not removed");
        assertEq(bandLevel, 0, "Band Level not removed");
        assertEq(stakingStartTimestamp, 0, "Timestamp not removed");

        assertEq(
            staking.getStakerBandIds(alice),
            EMPTY_STAKER_BAND_IDS,
            "Band Id's not removed"
        );
        vm.stopPrank();
    }

    function test_deleteVestingUserData_EmitsStaked()
        external
        grantVestingRole
        setBandLevelData
        stakeTokens
    {
        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true);
        emit VestingUserRemoved(alice);
        staking.deleteVestingUserData(alice);
        vm.stopPrank();
    }
}
