// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";
import {IStaking} from "../../../contracts/interfaces/IStaking.sol";

contract Staking_DeleteVestingUser_Unit_Test is Unit_Test {
    function test_deleteVestingUser_RevertIf_NotVestingContract() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                VESTING_ROLE
            )
        );
        vm.prank(alice);
        staking.deleteVestingUser(alice);
    }

    function test_deleteVestingUser_DeletesStakerData()
        external
        grantVestingRole
        setBandLevelData
        stakeTokens(STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        uint256 currentTimestamp = 100;
        vm.warp(currentTimestamp);

        vm.startPrank(alice);
        staking.deleteVestingUser(alice);
        (
            uint256 stakingStartDate,
            ,
            address owner,
            uint16 bandLevel,
            IStaking.StakingTypes stakingType
        ) = staking.getStakerBand(BAND_ID_0);

        assertEq(uint8(stakingType), 0, "Staking type not removed");
        assertEq(owner, address(0), "Owner not removed");
        assertEq(bandLevel, 0, "BandLevel Level not removed");
        assertEq(stakingStartDate, 0, "Timestamp not removed");

        assertEq(
            staking.getStakerBandIds(alice),
            EMPTY_STAKER_BAND_IDS,
            "BandLevel Id's not removed"
        );
        vm.stopPrank();
    }

    function test_deleteVestingUser_EmitsStaked()
        external
        grantVestingRole
        setBandLevelData
        stakeTokens(STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true);
        emit VestingUserDeleted(alice);
        staking.deleteVestingUser(alice);
        vm.stopPrank();
    }
}
