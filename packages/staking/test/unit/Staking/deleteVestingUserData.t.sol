// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";
import {IStaking} from "../../../contracts/interfaces/IStaking.sol";

contract Staking_DeleteVestingUserData_Unit_Test is Unit_Test {
    uint256[] stakerBandIds;

    modifier mGrantVestingRole() {
        vm.prank(admin);
        staking.grantRole(DEFAULT_VESTING_ROLE, alice);
        _;
    }

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
        mGrantVestingRole
        setBandLevelData
        stakeTokens
    {
        uint256 currentTimestamp = 100;
        vm.warp(currentTimestamp);

        vm.startPrank(alice);
        staking.deleteVestingUserData(alice);
        (
            ,
            uint256 startingSharesAmount,
            address owner,
            uint16 bandLevel,
            uint256 stakingStartTimestamp,
            uint256 usdtRewardsClaimed,
            uint256 usdcRewardsClaimed
        ) = staking.getStakerBandData(FIRST_STAKED_BAND_ID);

        assertEq(owner, address(0), "Owner not removed");
        assertEq(bandLevel, 0, "Band Level not removed");
        assertEq(stakingStartTimestamp, 0, "Timestamp not removed");
        assertEq(usdtRewardsClaimed, 0, "USDT rewards claimed changed");
        assertEq(usdcRewardsClaimed, 0, "USDC rewards claimed changed");

        assertEq(
            staking.getStakerBandIds(alice),
            stakerBandIds,
            "Band Id's not removed"
        );
        vm.stopPrank();
    }

    function test_deleteVestingUserData_EmitsStaked()
        external
        mGrantVestingRole
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
