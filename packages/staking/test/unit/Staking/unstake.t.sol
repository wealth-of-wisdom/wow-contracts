// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";
import {IStaking} from "../../../contracts/interfaces/IStaking.sol";

contract Staking_Unstake_Unit_Test is Unit_Test {
    function test_unstake_RevertIf_NotBandOwner()
        external
        setBandLevelData
        stakeTokens
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__NotBandOwner.selector,
                FIRST_STAKED_BAND_ID,
                bob
            )
        );
        vm.prank(bob);
        staking.unstake(FIRST_STAKED_BAND_ID);
    }

    function test_unstake_UnstakesTokensAndSetsData()
        external
        setBandLevelData
        stakeTokens
    {
        vm.startPrank(alice);
        staking.unstake(FIRST_STAKED_BAND_ID);

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

    function test_unstake_UnstakesAndTransfersTokens()
        external
        setBandLevelData
        stakeTokens
    {
        vm.startPrank(alice);
        uint256 alicePreUnstakingBalance = wowToken.balanceOf(alice);

        staking.unstake(FIRST_STAKED_BAND_ID);

        uint256 alicePostUnstakingBalance = wowToken.balanceOf(alice);
        uint256 stakingPostUnstakingBalance = wowToken.balanceOf(
            address(staking)
        );
        assertEq(
            stakingPostUnstakingBalance,
            0,
            "Tokens not transfered from contract"
        );
        assertEq(
            alicePostUnstakingBalance,
            alicePreUnstakingBalance + BAND_4_PRICE,
            "Tokens and rewards not transfered to staker"
        );
        vm.stopPrank();
    }

    function test_unstake_EmitsUnstaked()
        external
        setBandLevelData
        stakeTokens
    {
        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true);
        emit Unstaked(alice, FIRST_STAKED_BAND_ID, false);
        staking.unstake(FIRST_STAKED_BAND_ID);
        vm.stopPrank();
    }
}
