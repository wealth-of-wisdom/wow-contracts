// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";
import {IStaking} from "../../../contracts/interfaces/IStaking.sol";

contract Staking_Stake_Unit_Test is Unit_Test {
    function test_stake_RevertIf_InvalidBandLevel() external setBandLevelData {
        uint16 fauxLevel = 100;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InvalidBandLevel.selector,
                fauxLevel
            )
        );
        vm.prank(alice);
        staking.stake(STAKING_TYPE_FLEXI, fauxLevel);
    }

    //NOTE: won't pass due to enum restrictions
    // function test_stake_RevertIf_InvalidStakingType()
    //     external
    //     setBandLevelData
    // {
    //     vm.expectRevert(Errors.Staking__InvalidStakingType.selector);
    //     vm.prank(alice);
    //     staking.stake(3, BAND_LEVEL_1);
    // }

    function test_stake_StakesTokensSetsData() external setBandLevelData {
        uint256 currentTimestamp = 100;
        vm.warp(currentTimestamp);

        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_2_PRICE);
        staking.stake(STAKING_TYPE_FLEXI, BAND_LEVEL_2);

        (
            uint256 stakingStartDate,
            ,
            address owner,
            uint16 bandLevel,
            IStaking.StakingTypes stakingType
        ) = staking.getStakerBand(BAND_LEVEL_0);

        assertEq(
            uint8(stakingType),
            uint8(STAKING_TYPE_FLEXI),
            "Staking type not set"
        );
        assertEq(owner, alice, "Owner not set");
        assertEq(bandLevel, BAND_LEVEL_2, "BandLevel Level not set");
        assertEq(stakingStartDate, currentTimestamp, "Timestamp not set");

        assertEq(
            staking.getStakerBandIds(alice),
            STAKER_BAND_IDS,
            "Incorrect band Id's set"
        );

        vm.stopPrank();
    }

    function test_stake_StakesTokensTransfersTokens()
        external
        setBandLevelData
    {
        vm.startPrank(alice);
        uint256 alicePreStakingBalance = wowToken.balanceOf(alice);

        wowToken.approve(address(staking), BAND_2_PRICE);
        staking.stake(STAKING_TYPE_FLEXI, BAND_LEVEL_2);

        uint256 alicePostStakingBalance = wowToken.balanceOf(alice);
        uint256 stakingPostStakingBalance = wowToken.balanceOf(
            address(staking)
        );

        assertEq(
            stakingPostStakingBalance,
            BAND_2_PRICE,
            "Tokens not transfered to contract"
        );
        assertEq(
            alicePostStakingBalance,
            alicePreStakingBalance - BAND_2_PRICE,
            "Tokens not transfered from staker"
        );
        vm.stopPrank();
    }

    function test_stake_MultipleTokenStake() external setBandLevelData {
        uint256 currentTimestamp = 100;
        vm.warp(currentTimestamp);

        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_2_PRICE);
        staking.stake(STAKING_TYPE_FLEXI, BAND_LEVEL_2);

        uint256 secondStakeBandId = staking.getNextBandId();
        wowToken.approve(address(staking), BAND_5_PRICE);
        staking.stake(STAKING_TYPE_FIX, BAND_LEVEL_5);

        (
            uint256 stakingStartDate,
            ,
            address owner,
            uint16 bandLevel,
            IStaking.StakingTypes stakingType
        ) = staking.getStakerBand(BAND_LEVEL_0);

        assertEq(
            uint8(stakingType),
            uint8(STAKING_TYPE_FLEXI),
            "Staking type not set"
        );
        assertEq(owner, alice, "Owner not set");
        assertEq(bandLevel, BAND_LEVEL_2, "BandLevel Level not set");
        assertEq(stakingStartDate, currentTimestamp, "Timestamp not set");

        (stakingStartDate, , owner, bandLevel, stakingType) = staking
            .getStakerBand(secondStakeBandId);

        assertEq(
            uint8(stakingType),
            uint8(STAKING_TYPE_FIX),
            "Staking type not set"
        );
        assertEq(owner, alice, "Owner not set");
        assertEq(bandLevel, BAND_LEVEL_5, "BandLevel Level not set");
        assertEq(stakingStartDate, currentTimestamp, "Timestamp not set");
        vm.stopPrank();
    }

    function test_stake_EmitsStaked() external setBandLevelData {
        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_2_PRICE);
        vm.expectEmit(true, true, true, true);
        emit Staked(alice, BAND_LEVEL_2, 0, STAKING_TYPE_FLEXI, false);
        staking.stake(STAKING_TYPE_FLEXI, BAND_LEVEL_2);
        vm.stopPrank();
    }
}
