// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IStaking} from "../../../contracts/interfaces/IStaking.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_UpgradeBand_Unit_Test is Unit_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                        SETUP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        Unit_Test.setUp();

        vm.prank(admin);
        staking.setBandUpgradesEnabled(true);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_upgradeBand_RevertIf_BandUpgradesDisabled() external {
        vm.prank(admin);
        staking.setBandUpgradesEnabled(false);

        vm.expectRevert(Errors.Staking__UpgradesDisabled.selector);
        vm.prank(alice);
        staking.upgradeBand(BAND_ID_0, BAND_LEVEL_7);
    }

    function test_upgradeBand_RevertIf_CallerNotBandOwner()
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
        staking.upgradeBand(BAND_ID_0, BAND_LEVEL_7);
    }

    function test_upgradeBand_RevertIf_InvalidBandLevel()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        uint16 invalidLevel = 10;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InvalidBandLevel.selector,
                invalidLevel
            )
        );
        vm.prank(alice);
        staking.upgradeBand(BAND_ID_0, invalidLevel);
    }

    function test_upgradeBand_RevertIf_FlexiTypeBand()
        external
        setBandLevelData
        setSharesInMonth
        stakeTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    {
        vm.expectRevert(Errors.Staking__NotFlexiTypeBand.selector);
        vm.prank(alice);
        staking.upgradeBand(BAND_ID_0, BAND_LEVEL_7);
    }

    function test_upgradeBand_RevertIf_DistributionInProgress()
        external
        setBandLevelData
        setSharesInMonth
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
        setDistributionInProgress(true)
    {
        vm.expectRevert(Errors.Staking__DistributionInProgress.selector);
        vm.prank(alice);
        staking.upgradeBand(BAND_ID_0, BAND_LEVEL_7);
    }

    function test_upgradeBand_RevertIf_NewBandLevelIsSameAsPrevious()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InvalidBandLevel.selector,
                BAND_LEVEL_4
            )
        );
        vm.prank(alice);
        staking.upgradeBand(BAND_ID_0, BAND_LEVEL_4);
    }

    function test_upgradeBand_RevertIf_NewBandLevelIsLowerPrevious()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InvalidBandLevel.selector,
                BAND_LEVEL_2
            )
        );
        vm.prank(alice);
        staking.upgradeBand(BAND_ID_0, BAND_LEVEL_2);
    }

    function test_stakeVested_RevertIf_BandLevelAlreadyDeprecated()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        vm.prank(admin);
        staking.updateBandLevelDeprecationStatus(BAND_LEVEL_7, true);

        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_7_PRICE - BAND_4_PRICE);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__BandLevelDeprecated.selector,
                BAND_LEVEL_7
            )
        );
        staking.upgradeBand(BAND_ID_0, BAND_LEVEL_7);
        vm.stopPrank();
    }

    function test_upgradeBand_UpdatesBandLevel()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        uint32 startDate = uint32(block.timestamp);
        skip(1 hours);

        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_7_PRICE - BAND_4_PRICE);
        staking.upgradeBand(BAND_ID_0, BAND_LEVEL_7);
        vm.stopPrank();

        (
            address owner,
            uint32 stakingStartDate,
            uint16 bandLevel,
            uint8 fixedMonths,
            IStaking.StakingTypes stakingType,
            bool areTokensVested
        ) = staking.getStakerBand(BAND_ID_0);

        assertEq(owner, alice, "Owner incorrect");
        assertEq(stakingStartDate, startDate, "Timestamp incorrect");
        assertEq(bandLevel, BAND_LEVEL_7, "BandLevel Level not set");
        assertEq(fixedMonths, 0, "Fixed months incorrect");
        assertEqStakingType(stakingType, STAKING_TYPE_FLEXI);
        assertFalse(areTokensVested, "Tokens vested incorrect");
    }

    function test_upgradeBand_DoesNotUpdateStakerBandIdsArray()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_7_PRICE - BAND_4_PRICE);
        staking.upgradeBand(BAND_ID_0, BAND_LEVEL_7);
        vm.stopPrank();

        uint256[] memory bandIds = staking.getStakerBandIds(alice);
        assertEq(bandIds.length, 1, "BandIds array length incorrect");
        assertEq(bandIds[0], BAND_ID_0, "BandId not in array");
    }

    function test_upgradeBand_TransferTokensFromStaker()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        uint256 bandPriceDifference = BAND_7_PRICE - BAND_4_PRICE;
        uint256 aliceBalanceBefore = wowToken.balanceOf(alice);

        vm.startPrank(alice);
        wowToken.approve(address(staking), bandPriceDifference);
        staking.upgradeBand(BAND_ID_0, BAND_LEVEL_7);
        vm.stopPrank();

        uint256 aliceBalanceAfter = wowToken.balanceOf(alice);

        assertEq(
            aliceBalanceBefore - bandPriceDifference,
            aliceBalanceAfter,
            "Tokens not transfered from staker"
        );
    }

    function test_upgradeBand_TransferTokensToStaking()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        uint256 bandPriceDifference = BAND_7_PRICE - BAND_4_PRICE;
        uint256 contractBalanceBefore = wowToken.balanceOf(address(staking));

        vm.startPrank(alice);
        wowToken.approve(address(staking), bandPriceDifference);
        staking.upgradeBand(BAND_ID_0, BAND_LEVEL_7);
        vm.stopPrank();

        uint256 contractBalanceAfter = wowToken.balanceOf(address(staking));

        assertEq(
            contractBalanceBefore + bandPriceDifference,
            contractBalanceAfter,
            "Tokens not transfered to staking"
        );
    }

    function test_upgradeBand_EmitsBandUpgradedEvent()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        uint256 bandPriceDifference = BAND_7_PRICE - BAND_4_PRICE;
        vm.startPrank(alice);
        wowToken.approve(address(staking), bandPriceDifference);

        vm.expectEmit(address(staking));
        emit BandUpgraded(alice, BAND_ID_0, BAND_LEVEL_4, BAND_LEVEL_7);

        staking.upgradeBand(BAND_ID_0, BAND_LEVEL_7);
        vm.stopPrank();
    }
}
