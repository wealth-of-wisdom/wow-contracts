// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_DowngradeBand_Unit_Test is Unit_Test {
    function test_downgradeBand_RevertIf_NotBandOwner()
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
        staking.downgradeBand(FIRST_STAKED_BAND_ID, BAND_ID_1);
    }

    function test_downgradeBand_RevertIf_InvalidBandLevel()
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
        staking.downgradeBand(FIRST_STAKED_BAND_ID, fauxBand);
    }

    function test_downgradeBand_RevertIf_CantModifyFixTypeBand()
        external
        setBandLevelData
    {
        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_4_PRICE);
        staking.stake(STAKING_TYPE_FIX, BAND_ID_4);
        vm.expectRevert(Errors.Staking__CantModifyFixTypeBand.selector);
        staking.downgradeBand(FIRST_STAKED_BAND_ID, BAND_ID_1);
        vm.stopPrank();
    }

    function test_downgradeBand_SetsBandData()
        external
        setBandLevelData
        stakeTokens
    {
        (
            ,
            ,
            address previousOwner,
            uint16 previousBandLevel,
            uint256 previousStakingStartTimestamp,
            uint256 previousUsdtRewardsClaimed,
            uint256 previousUsdcRewardsClaimed
        ) = staking.getStakerBandData(FIRST_STAKED_BAND_ID);

        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_7_PRICE - BAND_4_PRICE);
        staking.downgradeBand(FIRST_STAKED_BAND_ID, BAND_ID_1);
        vm.stopPrank();

        (
            ,
            ,
            address owner,
            uint16 bandLevel,
            uint256 stakingStartTimestamp,
            uint256 usdtRewardsClaimed,
            uint256 usdcRewardsClaimed
        ) = staking.getStakerBandData(FIRST_STAKED_BAND_ID);

        assertEq(owner, previousOwner, "Owner reset");
        assertEq(bandLevel, BAND_ID_1, "Band Level not set");
        assertEq(
            stakingStartTimestamp,
            previousStakingStartTimestamp,
            "Timestamp reset"
        );
        assertEq(
            usdtRewardsClaimed,
            previousUsdtRewardsClaimed,
            "USDT rewards claimed reset"
        );
        assertEq(
            usdcRewardsClaimed,
            previousUsdcRewardsClaimed,
            "USDC rewards claimed reset"
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
        stakeTokens
    {
        uint256 aliceBalanceBeforeUpgrade = wowToken.balanceOf(alice);
        uint256 contractBalanceBeforeUpgrade = wowToken.balanceOf(
            address(staking)
        );
        uint256 bandPriceDifference = BAND_4_PRICE - BAND_1_PRICE;
        vm.startPrank(alice);
        wowToken.approve(address(staking), bandPriceDifference);
        staking.downgradeBand(FIRST_STAKED_BAND_ID, BAND_ID_1);
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
        stakeTokens
    {
        uint256 bandPriceDifference = BAND_4_PRICE - BAND_1_PRICE;
        vm.startPrank(alice);
        wowToken.approve(address(staking), bandPriceDifference);

        vm.expectEmit(address(staking));
        emit BandDowngraded(alice, FIRST_STAKED_BAND_ID, BAND_ID_4, BAND_ID_1);
        staking.downgradeBand(FIRST_STAKED_BAND_ID, BAND_ID_1);
        vm.stopPrank();
    }
}
