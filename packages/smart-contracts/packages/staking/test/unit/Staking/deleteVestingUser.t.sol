// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IStaking} from "../../../contracts/interfaces/IStaking.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_DeleteVestingUser_Unit_Test is Unit_Test {
    function test_deleteVestingUser_RevertIf_CallerNotVestingContract()
        external
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                VESTING_ROLE
            )
        );
        vm.prank(alice);
        staking.deleteVestingUser(alice);
    }

    function test_deleteVestingUser_RevertIf_UserIsZeroAddress() external {
        vm.expectRevert(Errors.Staking__ZeroAddress.selector);
        vm.prank(address(vesting));
        staking.deleteVestingUser(ZERO_ADDRESS);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    FLEXI STAKING
    //////////////////////////////////////////////////////////////////////////*/

    function test_deleteVestingUser_FixType_Deletes1StakerBandData()
        external
        setBandLevelData
        setSharesInMonth
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1)
    {
        vm.prank(address(vesting));
        staking.deleteVestingUser(alice);

        (
            address owner,
            uint32 stakingStartDate,
            uint16 bandLevel,
            uint8 fixedMonths,
            IStaking.StakingTypes stakingType,
            bool areTokensVested
        ) = staking.getStakerBand(BAND_ID_0);

        assertEq(owner, ZERO_ADDRESS, "Owner not removed");
        assertEq(stakingStartDate, 0, "Timestamp not removed");
        assertEq(uint8(stakingType), 0, "Staking type not removed");
        assertEq(bandLevel, 0, "BandLevel Level not removed");
        assertEq(fixedMonths, 0, "Fixed months not removed");
        assertEq(areTokensVested, false, "Vesting status not removed");
    }

    function test_deleteVestingUser_FixType_Deletes3StakerBandsData()
        external
        setBandLevelData
        setSharesInMonth
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_1)
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_5, MONTH_1)
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_9, MONTH_1)
    {
        vm.prank(address(vesting));
        staking.deleteVestingUser(alice);

        (
            address owner,
            uint32 stakingStartDate,
            uint16 bandLevel,
            uint8 fixedMonths,
            IStaking.StakingTypes stakingType,
            bool areTokensVested
        ) = staking.getStakerBand(BAND_ID_0);

        assertEq(owner, ZERO_ADDRESS, "Owner not removed");
        assertEq(stakingStartDate, 0, "Timestamp not removed");
        assertEq(uint8(stakingType), 0, "Staking type not removed");
        assertEq(bandLevel, 0, "BandLevel Level not removed");
        assertEq(fixedMonths, 0, "Fixed months not removed");
        assertEq(areTokensVested, false, "Vesting status not removed");

        (
            owner,
            stakingStartDate,
            bandLevel,
            fixedMonths,
            stakingType,
            areTokensVested
        ) = staking.getStakerBand(BAND_ID_1);

        assertEq(owner, ZERO_ADDRESS, "Owner not removed");
        assertEq(stakingStartDate, 0, "Timestamp not removed");
        assertEq(uint8(stakingType), 0, "Staking type not removed");
        assertEq(bandLevel, 0, "BandLevel Level not removed");
        assertEq(fixedMonths, 0, "Fixed months not removed");
        assertEq(areTokensVested, false, "Vesting status not removed");

        (
            owner,
            stakingStartDate,
            bandLevel,
            fixedMonths,
            stakingType,
            areTokensVested
        ) = staking.getStakerBand(BAND_ID_2);

        assertEq(owner, ZERO_ADDRESS, "Owner not removed");
        assertEq(stakingStartDate, 0, "Timestamp not removed");
        assertEq(uint8(stakingType), 0, "Staking type not removed");
        assertEq(bandLevel, 0, "BandLevel Level not removed");
        assertEq(fixedMonths, 0, "Fixed months not removed");
        assertEq(areTokensVested, false, "Vesting status not removed");
    }

    function test_deleteVestingUser_FixType_DeletesStakerBandIdsArrayHolding1Id()
        external
        setBandLevelData
        setSharesInMonth
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1)
    {
        vm.prank(address(vesting));
        staking.deleteVestingUser(alice);

        uint256[] memory bandIds = staking.getStakerBandIds(alice);
        assertEq(bandIds.length, 0, "BandIds not removed");
    }

    function test_deleteVestingUser_FixType_DeletesStakerBandIdsArrayHolding3Id()
        external
        setBandLevelData
        setSharesInMonth
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_1)
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_5, MONTH_1)
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_9, MONTH_1)
    {
        vm.prank(address(vesting));
        staking.deleteVestingUser(alice);

        uint256[] memory bandIds = staking.getStakerBandIds(alice);
        assertEq(bandIds.length, 0, "BandIds not removed");
    }

    function test_deleteVestingUser_FixType_DeletesStakerRewardsForUSDT()
        external
        setBandLevelData
        setSharesInMonth
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1)
    {
        vm.prank(address(vesting));
        staking.deleteVestingUser(alice);

        (uint256 unclaimed, uint256 claimed) = staking.getStakerReward(
            alice,
            usdtToken
        );

        assertEq(unclaimed, 0, "Rewards not removed");
        assertEq(claimed, 0, "Rewards not removed");
    }

    function test_deleteVestingUser_FixType_DeletesStakerRewardsForUSDC()
        external
        setBandLevelData
        setSharesInMonth
        createDistribution(usdcToken)
        distributeRewards(usdcToken)
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1)
    {
        vm.prank(address(vesting));
        staking.deleteVestingUser(alice);

        (uint256 unclaimed, uint256 claimed) = staking.getStakerReward(
            alice,
            usdcToken
        );

        assertEq(unclaimed, 0, "Rewards not removed");
        assertEq(claimed, 0, "Rewards not removed");
    }

    function test_deleteVestingUser_FixType_RemovesUserFromAllUsers()
        external
        setBandLevelData
        setSharesInMonth
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1)
    {
        vm.prank(address(vesting));
        staking.deleteVestingUser(alice);

        assertEq(staking.getTotalUsers(), 0, "User not removed");
    }

    function test_deleteVestingUser_FixType_EmitsVestingUserDeletedEvent()
        external
        setBandLevelData
        setSharesInMonth
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1)
    {
        vm.expectEmit(address(staking));
        emit VestingUserDeleted(alice);

        vm.prank(address(vesting));
        staking.deleteVestingUser(alice);
    }

    // NOTE: FIX type staking removed
    // /*//////////////////////////////////////////////////////////////////////////
    //                                 FIX STAKING
    // //////////////////////////////////////////////////////////////////////////*/

    // function test_deleteVestingUser_FixType_Deletes1StakerBandData()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    // {
    //     vm.prank(address(vesting));
    //     staking.deleteVestingUser(alice);

    //     (
    //         address owner,
    //         uint32 stakingStartDate,
    //         uint16 bandLevel,
    //         uint8 fixedMonths,
    //         IStaking.StakingTypes stakingType,
    //         bool areTokensVested
    //     ) = staking.getStakerBand(BAND_ID_0);

    //     assertEq(owner, ZERO_ADDRESS, "Owner not removed");
    //     assertEq(stakingStartDate, 0, "Timestamp not removed");
    //     assertEq(uint8(stakingType), 0, "Staking type not removed");
    //     assertEq(bandLevel, 0, "BandLevel Level not removed");
    //     assertEq(fixedMonths, 0, "Fixed months not removed");
    //     assertEq(areTokensVested, false, "Vesting status not removed");
    // }

    // function test_deleteVestingUser_FixType_Deletes3StakerBandsData()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_12)
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_5, MONTH_12)
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_9, MONTH_12)
    // {
    //     vm.prank(address(vesting));
    //     staking.deleteVestingUser(alice);

    //     (
    //         address owner,
    //         uint32 stakingStartDate,
    //         uint16 bandLevel,
    //         uint8 fixedMonths,
    //         IStaking.StakingTypes stakingType,
    //         bool areTokensVested
    //     ) = staking.getStakerBand(BAND_ID_0);

    //     assertEq(owner, ZERO_ADDRESS, "Owner not removed");
    //     assertEq(stakingStartDate, 0, "Timestamp not removed");
    //     assertEq(uint8(stakingType), 0, "Staking type not removed");
    //     assertEq(bandLevel, 0, "BandLevel Level not removed");
    //     assertEq(fixedMonths, 0, "Fixed months not removed");
    //     assertEq(areTokensVested, false, "Vesting status not removed");

    //     (
    //         owner,
    //         stakingStartDate,
    //         bandLevel,
    //         fixedMonths,
    //         stakingType,
    //         areTokensVested
    //     ) = staking.getStakerBand(BAND_ID_1);

    //     assertEq(owner, ZERO_ADDRESS, "Owner not removed");
    //     assertEq(stakingStartDate, 0, "Timestamp not removed");
    //     assertEq(uint8(stakingType), 0, "Staking type not removed");
    //     assertEq(bandLevel, 0, "BandLevel Level not removed");
    //     assertEq(fixedMonths, 0, "Fixed months not removed");
    //     assertEq(areTokensVested, false, "Vesting status not removed");

    //     (
    //         owner,
    //         stakingStartDate,
    //         bandLevel,
    //         fixedMonths,
    //         stakingType,
    //         areTokensVested
    //     ) = staking.getStakerBand(BAND_ID_2);

    //     assertEq(owner, ZERO_ADDRESS, "Owner not removed");
    //     assertEq(stakingStartDate, 0, "Timestamp not removed");
    //     assertEq(uint8(stakingType), 0, "Staking type not removed");
    //     assertEq(bandLevel, 0, "BandLevel Level not removed");
    //     assertEq(fixedMonths, 0, "Fixed months not removed");
    //     assertEq(areTokensVested, false, "Vesting status not removed");
    // }

    // function test_deleteVestingUser_FixType_DeletesStakerBandIdsArrayHolding1Id()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    // {
    //     vm.prank(address(vesting));
    //     staking.deleteVestingUser(alice);

    //     uint256[] memory bandIds = staking.getStakerBandIds(alice);
    //     assertEq(bandIds.length, 0, "BandIds not removed");
    // }

    // function test_deleteVestingUser_FixType_DeletesStakerBandIdsArrayHolding3Id()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_12)
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_5, MONTH_12)
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_9, MONTH_12)
    // {
    //     vm.prank(address(vesting));
    //     staking.deleteVestingUser(alice);

    //     uint256[] memory bandIds = staking.getStakerBandIds(alice);
    //     assertEq(bandIds.length, 0, "BandIds not removed");
    // }

    // function test_deleteVestingUser_FixType_DeletesStakerRewardsForUSDT()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     createDistribution(usdtToken)
    //     distributeRewards(usdtToken)
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    // {
    //     vm.prank(address(vesting));
    //     staking.deleteVestingUser(alice);

    //     (uint256 unclaimed, uint256 claimed) = staking.getStakerReward(
    //         alice,
    //         usdtToken
    //     );

    //     assertEq(unclaimed, 0, "Rewards not removed");
    //     assertEq(claimed, 0, "Rewards not removed");
    // }

    // function test_deleteVestingUser_FixType_DeletesStakerRewardsForUSDC()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     createDistribution(usdcToken)
    //     distributeRewards(usdcToken)
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    // {
    //     vm.prank(address(vesting));
    //     staking.deleteVestingUser(alice);

    //     (uint256 unclaimed, uint256 claimed) = staking.getStakerReward(
    //         alice,
    //         usdcToken
    //     );

    //     assertEq(unclaimed, 0, "Rewards not removed");
    //     assertEq(claimed, 0, "Rewards not removed");
    // }

    // function test_deleteVestingUser_FixType_RemovesUserFromAllUsers()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    // {
    //     vm.prank(address(vesting));
    //     staking.deleteVestingUser(alice);

    //     assertEq(staking.getTotalUsers(), 0, "User not removed");
    // }

    // function test_deleteVestingUser_FixType_EmitsVestingUserDeletedEvent()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    // {
    //     vm.expectEmit(address(staking));
    //     emit VestingUserDeleted(alice);

    //     vm.prank(address(vesting));
    //     staking.deleteVestingUser(alice);
    // }
}
