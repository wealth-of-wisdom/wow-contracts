// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IStaking} from "../../../contracts/interfaces/IStaking.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_UnstakeVested_Unit_Test is Unit_Test {
    function test_unstakeVested_RevertIf_CallerNotVestingContract()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                VESTING_ROLE
            )
        );
        vm.prank(alice);
        staking.unstakeVested(alice, BAND_ID_0);
    }

    function test_unstakeVested_RevertIf_UserNotBandOwner()
        external
        setBandLevelData
        setSharesInMonth
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__NotBandOwner.selector,
                BAND_ID_0,
                alice
            )
        );
        vm.prank(address(vesting));
        staking.unstakeVested(alice, BAND_ID_0);
    }

    function test_unstakeVested_RevertIf_BandNotFromVestedTokens()
        external
        setBandLevelData
        setSharesInMonth
        stakeTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1)
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__BandFromVestedTokens.selector,
                false
            )
        );
        vm.prank(address(vesting));
        staking.unstakeVested(alice, BAND_ID_0);
    }

    function test_stakeVested_RevertIf_DistributionInProgress()
        external
        setBandLevelData
        setSharesInMonth
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1)
        setDistributionInProgress(true)
    {
        vm.expectRevert(Errors.Staking__DistributionInProgress.selector);
        vm.prank(address(vesting));
        staking.unstakeVested(alice, BAND_ID_0);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    FLEXI STAKING
    //////////////////////////////////////////////////////////////////////////*/

    function test_unstakeVested_FixType_DeletesBandDetails()
        external
        setBandLevelData
        setSharesInMonth
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1)
    {
        vm.warp(MONTH * MONTH_2);
        vm.prank(address(vesting));
        staking.unstakeVested(alice, BAND_ID_0);

        (
            uint256 purchasePrice,
            address owner,
            uint32 stakingStartDate,
            uint16 bandLevel,
            uint8 fixedMonths,
            IStaking.StakingTypes stakingType,
            bool areTokensVested
        ) = staking.getStakerBand(BAND_ID_0);

        assertEq(purchasePrice, 0, "Purchase price not removed");
        assertEq(owner, ZERO_ADDRESS, "Owner not removed");
        assertEq(stakingStartDate, 0, "Timestamp not removed");
        assertEq(uint8(stakingType), 0, "Staking type not removed");
        assertEq(bandLevel, 0, "BandLevel Level not removed");
        assertEq(fixedMonths, 0, "Fixed months not removed");
        assertEq(areTokensVested, false, "Vesting status not removed");
    }

    function test_unstakeVested_FixType_Deletes1BandFromStakerBands()
        external
        setBandLevelData
        setSharesInMonth
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1)
    {
        vm.warp(MONTH * MONTH_2);
        vm.prank(address(vesting));
        staking.unstakeVested(alice, BAND_ID_0);

        uint256[] memory bandIds = staking.getStakerBandIds(alice);

        assertEq(bandIds.length, 0, "Band id not removed");
    }

    function test_unstakeVested_FixType_Deletes1BandFrom3StakerBands()
        external
        setBandLevelData
        setSharesInMonth
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_1)
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_5, MONTH_1)
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_9, MONTH_1)
    {
        vm.warp(MONTH * MONTH_12);
        vm.prank(address(vesting));
        staking.unstakeVested(alice, BAND_ID_0);

        uint256[] memory bandIds = staking.getStakerBandIds(alice);

        assertEq(bandIds.length, 2, "Band id not removed");
        assertEq(bandIds[0], BAND_ID_2, "Band id not removed");
        assertEq(bandIds[1], BAND_ID_1, "Band id not removed");
    }

    function test_unstakeVested_FixType_RemovesUserIfLastBandIdDeleted()
        external
        setBandLevelData
        setSharesInMonth
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1)
    {
        vm.warp(MONTH * MONTH_2);
        vm.prank(address(vesting));
        staking.unstakeVested(alice, BAND_ID_0);

        assertEq(staking.getTotalUsers(), 0, "User not removed");
    }

    function test_unstakeVested_FixType_UpdatesRewardsData()
        external
        setBandLevelData
        setSharesInMonth
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1)
    {
        vm.warp(MONTH * MONTH_2);
        vm.prank(address(vesting));
        staking.unstakeVested(alice, BAND_ID_0);

        (uint256 unclaimedAmount, uint256 claimedAmount) = staking
            .getStakerReward(alice, usdtToken);
        assertEq(unclaimedAmount, 0, "Unclaimed amount not removed");
        assertEq(claimedAmount, ALICE_REWARDS, "Claimed amount not removed");
    }

    function test_unstakeVested_FixType_TransfersRewardsFromStaking()
        external
        setBandLevelData
        setSharesInMonth
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1)
    {
        vm.warp(MONTH * MONTH_2);
        uint256 stakingBalanceBefore = usdtToken.balanceOf(address(staking));

        vm.prank(address(vesting));
        staking.unstakeVested(alice, BAND_ID_0);

        uint256 stakingBalanceAfter = usdtToken.balanceOf(address(staking));

        assertEq(
            stakingBalanceBefore - ALICE_REWARDS,
            stakingBalanceAfter,
            "Tokens not transfered from staking"
        );
    }

    function test_unstakeVested_FixType_TransfersRewardsToStaker()
        external
        setBandLevelData
        setSharesInMonth
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1)
    {
        vm.warp(MONTH * MONTH_2);
        uint256 stakerBalanceBefore = usdtToken.balanceOf(alice);

        vm.prank(address(vesting));
        staking.unstakeVested(alice, BAND_ID_0);

        uint256 stakerBalanceAfter = usdtToken.balanceOf(alice);

        assertEq(
            stakerBalanceBefore + ALICE_REWARDS,
            stakerBalanceAfter,
            "Tokens not transfered to staker"
        );
    }

    function test_unstakeVested_FixType_DoesNotTransferRewardsFromStakingIfZeroRewards()
        external
        setBandLevelData
        setSharesInMonth
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1)
    {
        vm.warp(MONTH * MONTH_2);
        uint256 stakingBalanceBefore = usdtToken.balanceOf(address(staking));

        vm.prank(address(vesting));
        staking.unstakeVested(alice, BAND_ID_0);

        uint256 stakingBalanceAfter = usdtToken.balanceOf(address(staking));

        assertEq(
            stakingBalanceBefore,
            stakingBalanceAfter,
            "Tokens not transfered from staking"
        );
    }

    function test_unstakeVested_FixType_DoesNotTransferRewardsToStakerIfZeroRewards()
        external
        setBandLevelData
        setSharesInMonth
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1)
    {
        vm.warp(MONTH * MONTH_2);
        uint256 stakerBalanceBefore = usdtToken.balanceOf(alice);

        vm.prank(address(vesting));
        staking.unstakeVested(alice, BAND_ID_0);

        uint256 stakerBalanceAfter = usdtToken.balanceOf(alice);

        assertEq(
            stakerBalanceBefore,
            stakerBalanceAfter,
            "Tokens not transfered to staker"
        );
    }

    function test_unstakeVested_FixType_EmitsRewardsClaimedEvent()
        external
        setBandLevelData
        setSharesInMonth
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1)
    {
        vm.warp(MONTH * MONTH_2);
        vm.expectEmit(address(staking));
        emit RewardsClaimed(alice, usdtToken, ALICE_REWARDS);

        vm.prank(address(vesting));
        staking.unstakeVested(alice, BAND_ID_0);
    }

    function test_unstakeVested_FixType_EmitsUnstakedEvent()
        external
        setBandLevelData
        setSharesInMonth
        stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_1)
    {
        vm.warp(MONTH * MONTH_2);
        vm.expectEmit(address(staking));
        emit Unstaked(alice, BAND_ID_0, true);

        vm.prank(address(vesting));
        staking.unstakeVested(alice, BAND_ID_0);
    }

    // NOTE: FIX type staking removed
    // /*//////////////////////////////////////////////////////////////////////////
    //                                 FIX STAKING
    // //////////////////////////////////////////////////////////////////////////*/

    // function test_unstakeVested_RevertIf_FixType_UnlockDateNotReached()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    // {
    //     vm.expectRevert(Errors.Staking__UnlockDateNotReached.selector);
    //     vm.prank(address(vesting));
    //     staking.unstakeVested(alice, BAND_ID_0);
    // }

    // function test_unstakeVested_FixType_DeletesBandDetails()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    // {
    //     skip(12 * MONTH);
    //     vm.prank(address(vesting));
    //     staking.unstakeVested(alice, BAND_ID_0);

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

    // function test_unstakeVested_FixType_Deletes1BandFromStakerBands()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    // {
    //     skip(12 * MONTH);
    //     vm.prank(address(vesting));
    //     staking.unstakeVested(alice, BAND_ID_0);

    //     uint256[] memory bandIds = staking.getStakerBandIds(alice);

    //     assertEq(bandIds.length, 0, "Band id not removed");
    // }

    // function test_unstakeVested_FixType_Deletes1BandFrom3StakerBands()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_1, MONTH_1)
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_5, MONTH_12)
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_9, MONTH_24)
    // {
    //     skip(MONTH);
    //     vm.prank(address(vesting));
    //     staking.unstakeVested(alice, BAND_ID_0);

    //     uint256[] memory bandIds = staking.getStakerBandIds(alice);

    //     assertEq(bandIds.length, 2, "Band id not removed");
    //     assertEq(bandIds[0], BAND_ID_2, "Band id not removed");
    //     assertEq(bandIds[1], BAND_ID_1, "Band id not removed");
    // }

    // function test_unstakeVested_FixType_RemovesUserIfLastBandIdDeleted()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    // {
    //     skip(12 * MONTH);
    //     vm.prank(address(vesting));
    //     staking.unstakeVested(alice, BAND_ID_0);

    //     assertEq(staking.getTotalUsers(), 0, "User not removed");
    // }

    // function test_unstakeVested_FixType_UpdatesRewardsData()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     createDistribution(usdtToken)
    //     distributeRewards(usdtToken)
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    // {
    //     skip(12 * MONTH);
    //     vm.prank(address(vesting));
    //     staking.unstakeVested(alice, BAND_ID_0);

    //     (uint256 unclaimedAmount, uint256 claimedAmount) = staking
    //         .getStakerReward(alice, usdtToken);
    //     assertEq(unclaimedAmount, 0, "Unclaimed amount not removed");
    //     assertEq(claimedAmount, ALICE_REWARDS, "Claimed amount not removed");
    // }

    // function test_unstakeVested_FixType_TransfersRewardsFromStaking()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     createDistribution(usdtToken)
    //     distributeRewards(usdtToken)
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    // {
    //     uint256 stakingBalanceBefore = usdtToken.balanceOf(address(staking));

    //     skip(12 * MONTH);
    //     vm.prank(address(vesting));
    //     staking.unstakeVested(alice, BAND_ID_0);

    //     uint256 stakingBalanceAfter = usdtToken.balanceOf(address(staking));

    //     assertEq(
    //         stakingBalanceBefore - ALICE_REWARDS,
    //         stakingBalanceAfter,
    //         "Tokens not transfered from staking"
    //     );
    // }

    // function test_unstakeVested_FixType_TransfersRewardsToStaker()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     createDistribution(usdtToken)
    //     distributeRewards(usdtToken)
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    // {
    //     uint256 stakerBalanceBefore = usdtToken.balanceOf(alice);

    //     skip(12 * MONTH);
    //     vm.prank(address(vesting));
    //     staking.unstakeVested(alice, BAND_ID_0);

    //     uint256 stakerBalanceAfter = usdtToken.balanceOf(alice);

    //     assertEq(
    //         stakerBalanceBefore + ALICE_REWARDS,
    //         stakerBalanceAfter,
    //         "Tokens not transfered to staker"
    //     );
    // }

    // function test_unstakeVested_FixType_DoesNotTransferRewardsFromStakingIfZeroRewards()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    // {
    //     uint256 stakingBalanceBefore = usdtToken.balanceOf(address(staking));

    //     skip(12 * MONTH);
    //     vm.prank(address(vesting));
    //     staking.unstakeVested(alice, BAND_ID_0);

    //     uint256 stakingBalanceAfter = usdtToken.balanceOf(address(staking));

    //     assertEq(
    //         stakingBalanceBefore,
    //         stakingBalanceAfter,
    //         "Tokens not transfered from staking"
    //     );
    // }

    // function test_unstakeVested_FixType_DoesNotTransferRewardsToStakerIfZeroRewards()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    // {
    //     uint256 stakerBalanceBefore = usdtToken.balanceOf(alice);

    //     skip(12 * MONTH);
    //     vm.prank(address(vesting));
    //     staking.unstakeVested(alice, BAND_ID_0);

    //     uint256 stakerBalanceAfter = usdtToken.balanceOf(alice);

    //     assertEq(
    //         stakerBalanceBefore,
    //         stakerBalanceAfter,
    //         "Tokens not transfered to staker"
    //     );
    // }

    // function test_unstakeVested_FixType_EmitsRewardsClaimedEvent()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     createDistribution(usdtToken)
    //     distributeRewards(usdtToken)
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    // {
    //     skip(12 * MONTH);

    //     vm.expectEmit(address(staking));
    //     emit RewardsClaimed(alice, usdtToken, ALICE_REWARDS);

    //     vm.prank(address(vesting));
    //     staking.unstakeVested(alice, BAND_ID_0);
    // }

    // function test_unstakeVested_FixType_EmitsUnstakedEvent()
    //     external
    //     setBandLevelData
    //     setSharesInMonth
    //     stakeVestedTokens(alice, STAKING_TYPE_FIX, BAND_LEVEL_4, MONTH_12)
    // {
    //     skip(12 * MONTH);

    //     vm.expectEmit(address(staking));
    //     emit Unstaked(alice, BAND_ID_0, true);

    //     vm.prank(address(vesting));
    //     staking.unstakeVested(alice, BAND_ID_0);
    // }
}
