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
                BAND_LEVEL_0,
                bob
            )
        );
        vm.prank(bob);
        staking.unstake(BAND_LEVEL_0);
    }

    function test_unstake_UnstakesTokensAndSetsData()
        external
        setBandLevelData
        stakeTokens
    {
        vm.startPrank(alice);
        staking.unstake(BAND_LEVEL_0);

        (
            IStaking.StakingTypes stakingType,
            ,
            address owner,
            uint16 bandLevel,
            uint256 stakingStartTimestamp,
            ,

        ) = staking.getStakerBandData(BAND_LEVEL_0);

        assertEq(uint8(stakingType), 0, "Staking type not removed");
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

        staking.unstake(BAND_LEVEL_0);

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
        emit Unstaked(alice, BAND_LEVEL_0, false);
        staking.unstake(BAND_LEVEL_0);
        vm.stopPrank();
    }
}
