// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IStaking} from "../../../contracts/interfaces/IStaking.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_DowngradeBand_Unit_Test is Unit_Test {
    function test_downgradeBand_RevertIf_CallerNotBandOwner()
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
        uint16 invalidLevel = 10;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InvalidBandLevel.selector,
                invalidLevel
            )
        );
        vm.prank(alice);
        staking.downgradeBand(BAND_ID_0, invalidLevel);
    }

    function test_downgradeBand_RevertIf_FixTypeBand()
        external
        setBandLevelData
        setSharesInMonth
        stakeTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    {
        vm.expectRevert(Errors.Staking__NotFlexiTypeBand.selector);
        vm.prank(alice);
        staking.downgradeBand(BAND_ID_0, BAND_LEVEL_1);
    }

    function test_downgradeBand_RevertIf_TokensAreVested()
        external
        setBandLevelData
        stakeVestedTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__BandFromVestedTokens.selector,
                true
            )
        );
        vm.prank(alice);
        staking.downgradeBand(BAND_ID_0, BAND_LEVEL_1);
    }

    function test_downgradeBand_RevertIf_NewBandLevelIsSameAsPrevious()
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
        staking.downgradeBand(BAND_ID_0, BAND_LEVEL_4);
    }

    function test_downgradeBand_RevertIf_NewBandLevelIsHigherThanPrevious()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InvalidBandLevel.selector,
                BAND_LEVEL_7
            )
        );
        vm.prank(alice);
        staking.downgradeBand(BAND_ID_0, BAND_LEVEL_7);
    }

    function test_downgradeBand_UpdatesBandLevel()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        uint32 startDate = uint32(block.timestamp);
        skip(1 hours);

        vm.prank(alice);
        staking.downgradeBand(BAND_ID_0, BAND_LEVEL_2);

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
        assertEq(bandLevel, BAND_LEVEL_2, "BandLevel Level not set");
        assertEq(fixedMonths, 0, "Fixed months incorrect");
        assertEqStakingType(stakingType, STAKING_TYPE_FLEXI);
        assertFalse(areTokensVested, "Tokens vested incorrect");
    }

    function test_downgradeBand_DoesNotUpdateStakerBandIdsArray()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        vm.prank(alice);
        staking.downgradeBand(BAND_ID_0, BAND_LEVEL_2);

        uint256[] memory bandIds = staking.getStakerBandIds(alice);
        assertEq(bandIds.length, 1, "BandIds array length incorrect");
        assertEq(bandIds[0], BAND_ID_0, "BandId not in array");
    }

    function test_downgradeBand_TransferTokensFromStaking()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        uint256 bandPriceDifference = BAND_4_PRICE - BAND_2_PRICE;
        uint256 contractBalanceBefore = wowToken.balanceOf(address(staking));

        vm.prank(alice);
        staking.downgradeBand(BAND_ID_0, BAND_LEVEL_2);

        uint256 contractBalanceAfter = wowToken.balanceOf(address(staking));

        assertEq(
            contractBalanceBefore - bandPriceDifference,
            contractBalanceAfter,
            "Tokens not transfered from staking"
        );
    }

    function test_downgradeBand_TransferTokensToStaker()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        uint256 bandPriceDifference = BAND_4_PRICE - BAND_2_PRICE;
        uint256 aliceBalanceBefore = wowToken.balanceOf(alice);

        vm.prank(alice);
        staking.downgradeBand(BAND_ID_0, BAND_LEVEL_2);

        uint256 aliceBalanceAfter = wowToken.balanceOf(alice);

        assertEq(
            aliceBalanceBefore + bandPriceDifference,
            aliceBalanceAfter,
            "Tokens not transfered to staker"
        );
    }

    function test_downgradeBand_EmitsBandUpgaded()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        vm.expectEmit(address(staking));
        emit BandDowngraded(alice, BAND_ID_0, BAND_LEVEL_4, BAND_LEVEL_2);

        vm.prank(alice);
        staking.downgradeBand(BAND_ID_0, BAND_LEVEL_2);
    }
}
