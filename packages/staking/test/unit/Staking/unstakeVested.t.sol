// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";
import {IStaking} from "../../../contracts/interfaces/IStaking.sol";

contract Staking_UnstakeVested_Unit_Test is Unit_Test {
    function test_unstakeVested_RevertIf_NotVestingContract()
        external
        setBandLevelData
        stakeTokens
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_VESTING_ROLE
            )
        );
        vm.prank(alice);
        staking.unstakeVested(FIRST_STAKED_BAND_ID, alice);
    }

    function test_unstakeVested_RevertIf_NotBandOwner()
        external
        setBandLevelData
        grantVestingRole
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__NotBandOwner.selector,
                FIRST_STAKED_BAND_ID,
                alice
            )
        );
        vm.prank(alice);
        staking.unstakeVested(FIRST_STAKED_BAND_ID, alice);
    }

    function test_unstakeVested_UnstakesTokensAndSetsData()
        external
        setBandLevelData
        stakeTokens
        grantVestingRole
    {
        vm.startPrank(alice);
        staking.unstakeVested(FIRST_STAKED_BAND_ID, alice);

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

    function test_unstakeVested_UnstakesAndTransfersTokens()
        external
        setBandLevelData
        stakeTokens
        grantVestingRole
    {
        vm.startPrank(alice);
        uint256 alicePreUnstakingBalance = wowToken.balanceOf(alice);
        uint256 stakingPreUnstakingBalance = wowToken.balanceOf(
            address(staking)
        );

        staking.unstakeVested(FIRST_STAKED_BAND_ID, alice);

        uint256 alicePostUnstakingBalance = wowToken.balanceOf(alice);
        uint256 stakingPostUnstakingBalance = wowToken.balanceOf(
            address(staking)
        );

        assertEq(
            stakingPostUnstakingBalance,
            stakingPreUnstakingBalance,
            "Tokens should not have been transfered to contract"
        );
        assertEq(
            alicePostUnstakingBalance,
            alicePreUnstakingBalance,
            "Tokens should not have been transfered from user"
        );
        vm.stopPrank();
    }

    function test_unstakeVested_EmitsUnstaked()
        external
        setBandLevelData
        stakeTokens
        grantVestingRole
    {
        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true);
        emit Unstaked(alice, FIRST_STAKED_BAND_ID, true);
        staking.unstakeVested(FIRST_STAKED_BAND_ID, alice);
        vm.stopPrank();
    }
}
