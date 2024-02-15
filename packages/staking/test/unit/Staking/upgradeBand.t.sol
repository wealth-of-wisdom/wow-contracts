// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";
import {IStaking} from "../../../contracts/interfaces/IStaking.sol";

contract Staking_UpgradeBand_Unit_Test is Unit_Test {
    function test_upgradeBand_RevertIf_NotBandOwner()
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
        staking.upgradeBand(BAND_LEVEL_0, BAND_LEVEL_7);
    }

    function test_upgradeBand_RevertIf_InvalidBandLevel()
        external
        setBandLevelData
        stakeTokens
    {
        uint16 fauxBand = 100;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InvalidBandLevel.selector,
                fauxBand
            )
        );
        vm.prank(alice);
        staking.upgradeBand(BAND_LEVEL_0, fauxBand);
    }

    function test_upgradeBand_RevertIf_CantModifyFixTypeBand()
        external
        setBandLevelData
    {
        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_4_PRICE);
        staking.stake(STAKING_TYPE_FIX, BAND_LEVEL_4);

        vm.expectRevert(Errors.Staking__CantModifyFixTypeBand.selector);
        staking.upgradeBand(BAND_LEVEL_0, BAND_LEVEL_7);
        vm.stopPrank();
    }

    function test_upgradeBand_SetsBandData()
        external
        setBandLevelData
        stakeTokens
    {
        (
            uint256 previousStakingStartTimestamp,
            ,
            address previousOwner,
            uint16 previousBandLevel,
            IStaking.StakingTypes previousStakingType
        ) = staking.getStakerBand(BAND_LEVEL_0);

        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_7_PRICE - BAND_4_PRICE);
        staking.upgradeBand(BAND_LEVEL_0, BAND_LEVEL_7);
        vm.stopPrank();

        (
            uint256 stakingStartDate,
            ,
            address owner,
            uint16 bandLevel,
            IStaking.StakingTypes stakingType
        ) = staking.getStakerBand(BAND_LEVEL_0);

        assertEq(
            uint8(stakingType),
            uint8(previousStakingType),
            "StakingType reset"
        );
        assertEq(owner, previousOwner, "Owner reset");
        assertEq(bandLevel, BAND_LEVEL_7, "BandLevel Level not set");
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

    function test_upgradeBand_TransferTokens()
        external
        setBandLevelData
        stakeTokens
    {
        uint256 aliceBalanceBeforeUpgrade = wowToken.balanceOf(alice);
        uint256 contractBalanceBeforeUpgrade = wowToken.balanceOf(
            address(staking)
        );
        uint256 bandPriceDifference = BAND_7_PRICE - BAND_4_PRICE;

        vm.startPrank(alice);
        wowToken.approve(address(staking), bandPriceDifference);
        staking.upgradeBand(BAND_LEVEL_0, BAND_LEVEL_7);
        vm.stopPrank();

        uint256 aliceBalanceAfterUpgrade = wowToken.balanceOf(alice);
        uint256 contractBalanceAfterUpgrade = wowToken.balanceOf(
            address(staking)
        );

        assertEq(
            aliceBalanceBeforeUpgrade - bandPriceDifference,
            aliceBalanceAfterUpgrade,
            "Tokens not transfered to contract"
        );
        assertEq(
            contractBalanceBeforeUpgrade + bandPriceDifference,
            contractBalanceAfterUpgrade,
            "Contract did not receive tokens"
        );
    }

    function test_upgradeBand_EmitsBandUpgaded()
        external
        setBandLevelData
        stakeTokens
    {
        uint256 bandPriceDifference = BAND_7_PRICE - BAND_4_PRICE;
        vm.startPrank(alice);
        wowToken.approve(address(staking), bandPriceDifference);

        vm.expectEmit(address(staking));
        emit BandUpgaded(alice, BAND_LEVEL_0, BAND_LEVEL_4, BAND_LEVEL_7);
        staking.upgradeBand(BAND_LEVEL_0, BAND_LEVEL_7);
        vm.stopPrank();
    }
}
