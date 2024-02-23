// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";
import {IStaking} from "../../../contracts/interfaces/IStaking.sol";

contract Staking_StakeVested_Unit_Test is Unit_Test {
    function test_stakeVested_RevertIf_CallerNotVestingContract()
        external
        setBandLevelData
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                VESTING_ROLE
            )
        );
        vm.prank(alice);
        staking.stakeVested(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_2, MONTH_0);
    }

    function test_stakeVested_RevertIf_UserIsZeroAddress()
        external
        setBandLevelData
    {
        vm.expectRevert(Errors.Staking__ZeroAddress.selector);
        vm.prank(address(vesting));
        staking.stakeVested(
            ZERO_ADDRESS,
            STAKING_TYPE_FLEXI,
            BAND_LEVEL_4,
            MONTH_0
        );
    }

    function test_stakeVested_RevertIf_InvalidBandLevel()
        external
        setBandLevelData
    {
        uint16 invalidLevel = 10;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InvalidBandLevel.selector,
                invalidLevel
            )
        );
        vm.prank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FLEXI, invalidLevel, MONTH_0);
    }

    function test_stakeVested_RevertIf_InvalidMonthForFlexiType()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InvalidMonth.selector,
                MONTH_1
            )
        );
        vm.prank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_1, MONTH_1);
    }

    function test_stakeVested_RevertIf_MonthForFixTypeIsZero()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InvalidMonth.selector,
                MONTH_0
            )
        );
        vm.prank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_0);
    }

    function test_stakeVested_RevertIf_MonthForFixTypeIsTooHigh()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InvalidMonth.selector,
                MONTH_25
            )
        );
        vm.prank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_25);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    FLEXI STAKING
    //////////////////////////////////////////////////////////////////////////*/

    function test_stakeVested_FlexiType_SetsBandData()
        external
        setBandLevelData
        setSharesInMonth
    {
        uint256 currentTimestamp = 100;
        vm.warp(currentTimestamp);

        vm.prank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_2, MONTH_0);

        (
            address owner,
            uint32 stakingStartDate,
            uint16 bandLevel,
            uint8 fixedMonths,
            IStaking.StakingTypes stakingType,
            bool areTokensVested
        ) = staking.getStakerBand(BAND_ID_0);

        assertEq(owner, alice, "Owner not set");
        assertEq(stakingStartDate, currentTimestamp, "Timestamp not set");
        assertEq(bandLevel, BAND_LEVEL_2, "BandLevel Level not set");
        assertEqStakingType(stakingType, STAKING_TYPE_FLEXI);
        assertEq(fixedMonths, MONTH_0, "Fixed months not set");
        assertTrue(areTokensVested, "Tokens not vested");
    }

    function test_stakeVested_FlexiType_Adds1BandToAllStakerBands()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.prank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_2, MONTH_0);

        uint256[] memory allStakerBands = staking.getStakerBandIds(alice);
        assertEq(allStakerBands.length, 1, "Band not added to allStakerBands");
        assertEq(
            allStakerBands[0],
            BAND_ID_0,
            "Band not added to allStakerBands"
        );
    }

    function test_stakeVested_FlexiType_Adds3BandsToAllStakerBands()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.startPrank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_1, MONTH_0);
        staking.stakeVested(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_5, MONTH_0);
        staking.stakeVested(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_9, MONTH_0);
        vm.stopPrank();

        uint256[] memory allStakerBands = staking.getStakerBandIds(alice);
        assertEq(allStakerBands.length, 3, "Band not added to allStakerBands");
        assertEq(
            allStakerBands[0],
            BAND_ID_0,
            "Band not added to allStakerBands"
        );
        assertEq(
            allStakerBands[1],
            BAND_ID_1,
            "Band not added to allStakerBands"
        );
        assertEq(
            allStakerBands[2],
            BAND_ID_2,
            "Band not added to allStakerBands"
        );
    }

    function test_stakeVested_FlexiType_Adds4BandsForDifferentUsers()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.startPrank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_1, MONTH_0);
        staking.stakeVested(bob, STAKING_TYPE_FLEXI, BAND_LEVEL_1, MONTH_0);
        staking.stakeVested(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_9, MONTH_0);
        staking.stakeVested(bob, STAKING_TYPE_FLEXI, BAND_LEVEL_9, MONTH_0);
        vm.stopPrank();

        uint256[] memory aliceBands = staking.getStakerBandIds(alice);
        uint256[] memory bobBands = staking.getStakerBandIds(bob);

        assertEq(aliceBands.length, 2, "Incorrect amount of bands for alice");
        assertEq(bobBands.length, 2, "Incorrect amount of bands for bob");
        assertEq(aliceBands[0], BAND_ID_0, "Band not added to array");
        assertEq(aliceBands[1], BAND_ID_2, "Band not added to array");
        assertEq(
            bobBands[0],
            BAND_ID_1,
            "Band not added to allSarraytakerBands"
        );
        assertEq(bobBands[1], BAND_ID_3, "Band not added to array");
    }

    function test_stakeVested_FlexiType_Adds1UserToEnumerableMap()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.prank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_1, MONTH_0);

        address staker1 = staking.getUser(0);
        assertEq(staker1, alice, "Staker not added to enumerable map");

        vm.expectRevert();
        staking.getUser(1);
    }

    function test_stakeVested_FlexiType_Adds3UsersToEnumerableMap()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.startPrank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_1, MONTH_0);
        staking.stakeVested(bob, STAKING_TYPE_FLEXI, BAND_LEVEL_1, MONTH_0);
        staking.stakeVested(carol, STAKING_TYPE_FLEXI, BAND_LEVEL_1, MONTH_0);
        vm.stopPrank();

        address staker1 = staking.getUser(0);
        address staker2 = staking.getUser(1);
        address staker3 = staking.getUser(2);

        assertEq(staker1, alice, "Staker not added to enumerable map");
        assertEq(staker2, bob, "Staker not added to enumerable map");
        assertEq(staker3, carol, "Staker not added to enumerable map");

        vm.expectRevert();
        staking.getUser(3);
    }

    function test_stakeVested_FlexiType_Adds2UsersWithMultipleBandsToEnumerableMap()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.startPrank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_1, MONTH_0);
        staking.stakeVested(bob, STAKING_TYPE_FLEXI, BAND_LEVEL_1, MONTH_0);
        staking.stakeVested(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_9, MONTH_0);
        staking.stakeVested(bob, STAKING_TYPE_FLEXI, BAND_LEVEL_9, MONTH_0);
        vm.stopPrank();

        address staker1 = staking.getUser(0);
        address staker2 = staking.getUser(1);

        assertEq(staker1, alice, "Staker not added to enumerable map");
        assertEq(staker2, bob, "Staker not added to enumerable map");

        vm.expectRevert();
        staking.getUser(2);
    }

    function test_stakeVested_FlexiType_EmitsStakedEvent()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.expectEmit(address(staking));
        emit Staked(alice, BAND_LEVEL_2, BAND_ID_0, STAKING_TYPE_FLEXI, true);

        vm.prank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_2, MONTH_0);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    FIX STAKING
    //////////////////////////////////////////////////////////////////////////*/

    function test_stakeVested_FixType_SetsBandData()
        external
        setBandLevelData
        setSharesInMonth
    {
        uint256 currentTimestamp = 100;
        vm.warp(currentTimestamp);

        vm.prank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FIX, BAND_LEVEL_2, MONTH_12);

        (
            address owner,
            uint32 stakingStartDate,
            uint16 bandLevel,
            uint8 fixedMonths,
            IStaking.StakingTypes stakingType,
            bool areTokensVested
        ) = staking.getStakerBand(BAND_ID_0);

        assertEq(owner, alice, "Owner not set");
        assertEq(stakingStartDate, currentTimestamp, "Timestamp not set");
        assertEq(bandLevel, BAND_LEVEL_2, "BandLevel Level not set");
        assertEqStakingType(stakingType, STAKING_TYPE_FIX);
        assertEq(fixedMonths, MONTH_12, "Fixed months not set");
        assertTrue(areTokensVested, "Tokens not vested");
    }

    function test_stakeVested_FixType_Adds1BandToAllStakerBands()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.prank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FIX, BAND_LEVEL_2, MONTH_12);

        uint256[] memory allStakerBands = staking.getStakerBandIds(alice);
        assertEq(allStakerBands.length, 1, "Band not added to allStakerBands");
        assertEq(
            allStakerBands[0],
            BAND_ID_0,
            "Band not added to allStakerBands"
        );
    }

    function test_stakeVested_FixType_Adds3BandsToAllStakerBands()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.startPrank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_1);
        staking.stakeVested(alice, STAKING_TYPE_FIX, BAND_LEVEL_5, MONTH_12);
        staking.stakeVested(alice, STAKING_TYPE_FIX, BAND_LEVEL_9, MONTH_24);
        vm.stopPrank();

        uint256[] memory allStakerBands = staking.getStakerBandIds(alice);
        assertEq(allStakerBands.length, 3, "Band not added to allStakerBands");
        assertEq(
            allStakerBands[0],
            BAND_ID_0,
            "Band not added to allStakerBands"
        );
        assertEq(
            allStakerBands[1],
            BAND_ID_1,
            "Band not added to allStakerBands"
        );
        assertEq(
            allStakerBands[2],
            BAND_ID_2,
            "Band not added to allStakerBands"
        );
    }

    function test_stakeVested_FixType_Adds4BandsForDifferentUsers()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.startPrank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_12);
        staking.stakeVested(bob, STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_12);
        staking.stakeVested(alice, STAKING_TYPE_FIX, BAND_LEVEL_9, MONTH_12);
        staking.stakeVested(bob, STAKING_TYPE_FIX, BAND_LEVEL_9, MONTH_12);
        vm.stopPrank();

        uint256[] memory aliceBands = staking.getStakerBandIds(alice);
        uint256[] memory bobBands = staking.getStakerBandIds(bob);

        assertEq(aliceBands.length, 2, "Incorrect amount of bands for alice");
        assertEq(bobBands.length, 2, "Incorrect amount of bands for bob");
        assertEq(aliceBands[0], BAND_ID_0, "Band not added to array");
        assertEq(aliceBands[1], BAND_ID_2, "Band not added to array");
        assertEq(
            bobBands[0],
            BAND_ID_1,
            "Band not added to allSarraytakerBands"
        );
        assertEq(bobBands[1], BAND_ID_3, "Band not added to array");
    }

    function test_stakeVested_FixType_Adds1UserToEnumerableMap()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.prank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_12);

        address staker1 = staking.getUser(0);
        assertEq(staker1, alice, "Staker not added to enumerable map");

        vm.expectRevert();
        staking.getUser(1);
    }

    function test_stakeVested_FixType_Adds3UsersToEnumerableMap()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.startPrank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_12);
        staking.stakeVested(bob, STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_12);
        staking.stakeVested(carol, STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_12);
        vm.stopPrank();

        address staker1 = staking.getUser(0);
        address staker2 = staking.getUser(1);
        address staker3 = staking.getUser(2);

        assertEq(staker1, alice, "Staker not added to enumerable map");
        assertEq(staker2, bob, "Staker not added to enumerable map");
        assertEq(staker3, carol, "Staker not added to enumerable map");

        vm.expectRevert();
        staking.getUser(3);
    }

    function test_stakeVested_FixType_Adds2UsersWithMultipleBandsToEnumerableMap()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.startPrank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_12);
        staking.stakeVested(bob, STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_12);
        staking.stakeVested(alice, STAKING_TYPE_FIX, BAND_LEVEL_9, MONTH_12);
        staking.stakeVested(bob, STAKING_TYPE_FIX, BAND_LEVEL_9, MONTH_12);
        vm.stopPrank();

        address staker1 = staking.getUser(0);
        address staker2 = staking.getUser(1);

        assertEq(staker1, alice, "Staker not added to enumerable map");
        assertEq(staker2, bob, "Staker not added to enumerable map");

        vm.expectRevert();
        staking.getUser(2);
    }

    function test_stakeVested_FixType_EmitsStakedEvent()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.expectEmit(address(staking));
        emit Staked(alice, BAND_LEVEL_2, BAND_ID_0, STAKING_TYPE_FIX, true);

        vm.prank(address(vesting));
        staking.stakeVested(alice, STAKING_TYPE_FIX, BAND_LEVEL_2, MONTH_12);
    }
}
