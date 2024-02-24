// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";
import {IStaking} from "../../../contracts/interfaces/IStaking.sol";

contract Staking_DowngradeBand_Unit_Test is Unit_Test {
    function test_downgradeBand_RevertIf_NotBandOwner()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__NotBandOwner.selector,
                BAND_ID_0,
                bob
            )
        );
        vm.prank(bob);
        staking.downgradeBand(BAND_ID_0, BAND_LEVEL_1);
    }

    function test_downgradeBand_RevertIf_InvalidBandLevel()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        uint16 fauxBand = 100;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InvalidBandLevel.selector,
                fauxBand
            )
        );
        vm.prank(alice);
        staking.downgradeBand(BAND_ID_0, fauxBand);
    }

    function test_downgradeBand_RevertIf_CantModifyFixTypeBand()
        external
        setBandLevelData
    {
        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_4_PRICE);
        staking.stake(STAKING_TYPE_FIX, BAND_LEVEL_4);
        vm.expectRevert(Errors.Staking__CantModifyFixTypeBand.selector);
        staking.downgradeBand(BAND_ID_0, BAND_LEVEL_1);
        vm.stopPrank();
    }

    function test_downgradeBand_SetsBandData()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        (
            uint256 previousStakingStartTimestamp,
            ,
            address previousOwner,
            uint16 previousBandLevel,
            IStaking.StakingTypes previousStakingType
        ) = staking.getStakerBand(BAND_ID_0);

        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_7_PRICE - BAND_4_PRICE);
        staking.downgradeBand(BAND_ID_0, BAND_LEVEL_1);
        vm.stopPrank();

        (
            uint256 stakingStartDate,
            ,
            address owner,
            uint16 bandLevel,
            IStaking.StakingTypes stakingType
        ) = staking.getStakerBand(BAND_ID_0);

        assertEq(
            uint8(previousStakingType),
            uint8(stakingType),
            "Staking type reset"
        );
        assertEq(owner, previousOwner, "Owner reset");
        assertEq(bandLevel, BAND_LEVEL_1, "BandLevel Level not set");
        assertEq(
            stakingStartDate,
            previousStakingStartTimestamp,
            "Timestamp reset"
        );

        assertEq(
            staking.getStakerBandIds(alice),
            STAKER_BAND_IDS,
            "Added other band id"
        );
    }

    function test_downgradeBand_TransferTokens()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        uint256 aliceBalanceBeforeUpgrade = wowToken.balanceOf(alice);
        uint256 contractBalanceBeforeUpgrade = wowToken.balanceOf(
            address(staking)
        );
        uint256 bandPriceDifference = BAND_4_PRICE - BAND_1_PRICE;
        vm.startPrank(alice);
        wowToken.approve(address(staking), bandPriceDifference);
        staking.downgradeBand(BAND_ID_0, BAND_LEVEL_1);
        vm.stopPrank();

        uint256 aliceBalanceAfterUpgrade = wowToken.balanceOf(alice);
        uint256 contractBalanceAfterUpgrade = wowToken.balanceOf(
            address(staking)
        );

        assertEq(
            aliceBalanceBeforeUpgrade + bandPriceDifference,
            aliceBalanceAfterUpgrade,
            "Tokens not transfered to contract"
        );
        assertEq(
            contractBalanceBeforeUpgrade - bandPriceDifference,
            contractBalanceAfterUpgrade,
            "Contract did not receive tokens"
        );
    }

    function test_downgradeBand_EmitsBandUpgaded()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        uint256 bandPriceDifference = BAND_4_PRICE - BAND_1_PRICE;
        vm.startPrank(alice);
        wowToken.approve(address(staking), bandPriceDifference);

        vm.expectEmit(address(staking));
        emit BandDowngraded(alice, BAND_ID_0, BAND_LEVEL_4, BAND_LEVEL_1);
        staking.downgradeBand(BAND_ID_0, BAND_LEVEL_1);
        vm.stopPrank();
    }
}
