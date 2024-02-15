// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";
import {IStaking} from "../../../contracts/interfaces/IStaking.sol";

contract Staking_StakeVested_Unit_Test is Unit_Test {
    function test_stakeVested_RevertIf_NotVestingContract()
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
        staking.stakeVested(STAKING_TYPE_FLEXI, BAND_LEVEL_2, alice);
    }

    function test_stakeVested_RevertIf_InvalidBandLevel()
        external
        grantVestingRole
        setBandLevelData
    {
        uint16 fauxLevel = 100;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InvalidBandLevel.selector,
                fauxLevel
            )
        );
        vm.prank(alice);
        staking.stakeVested(STAKING_TYPE_FLEXI, fauxLevel, alice);
    }

    function test_stakeVested_StakesTokensSetsData()
        external
        grantVestingRole
        setBandLevelData
    {
        uint256 currentTimestamp = 100;
        vm.warp(currentTimestamp);
        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_2_PRICE);
        staking.stakeVested(STAKING_TYPE_FLEXI, BAND_LEVEL_2, alice);

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
            "Staking type set"
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

    function test_stakeVested_StakesTokensTransfersTokens()
        external
        grantVestingRole
        setBandLevelData
    {
        vm.startPrank(alice);
        uint256 alicePreStakingBalance = wowToken.balanceOf(alice);

        wowToken.approve(address(staking), BAND_2_PRICE);
        staking.stakeVested(STAKING_TYPE_FLEXI, BAND_LEVEL_2, alice);

        uint256 alicePostStakingBalance = wowToken.balanceOf(alice);
        uint256 stakingPostStakingBalance = wowToken.balanceOf(
            address(staking)
        );

        assertEq(
            stakingPostStakingBalance,
            0,
            "Tokens should not have been transfered to contract"
        );
        assertEq(
            alicePostStakingBalance,
            alicePreStakingBalance,
            "Tokens should not have been transfered from user"
        );
        vm.stopPrank();
    }

    function test_stakeVested_EmitsStaked()
        external
        grantVestingRole
        setBandLevelData
    {
        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_2_PRICE);
        vm.expectEmit(true, true, true, true);
        emit Staked(alice, BAND_LEVEL_2, STAKING_TYPE_FLEXI, true);
        staking.stakeVested(STAKING_TYPE_FLEXI, BAND_LEVEL_2, alice);
        vm.stopPrank();
    }
}
