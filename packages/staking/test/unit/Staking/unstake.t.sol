// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.20;

// import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
// import {Errors} from "../../../contracts/libraries/Errors.sol";
// import {Unit_Test} from "../Unit.t.sol";
// import {IStaking} from "../../../contracts/interfaces/IStaking.sol";

// contract Staking_Unstake_Unit_Test is Unit_Test {
//     uint256[] stakerBandIds;

//     function test_unstake_RevertIf_NotBandOwner() external setBandLevelData {
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 Errors.Staking__NotBandOwner.selector,
//                 0,
//                 alice
//             )
//         );
//         vm.prank(alice);
//         staking.unstake(0);
//     }

//     function test_unstake_UnstakesTokensAndSetsData()
//         external
//         setBandLevelData
//         stakeTokens
//     {
//         vm.startPrank(alice);
//         staking.unstake(FIRST_STAKED_BAND_ID);

//         (
//             ,
//             uint256 startingSharesAmount,
//             address owner,
//             uint16 bandLevel,
//             uint256 stakingStartTimestamp,
//             uint256 usdtRewardsClaimed,
//             uint256 usdcRewardsClaimed
//         ) = staking.getStakerBandData(FIRST_STAKED_BAND_ID);

//         assertEq(owner, address(0), "Owner not removed");
//         assertEq(bandLevel, 0, "Band Level not removed");
//         assertEq(stakingStartTimestamp, 0, "Timestamp not removed");
//         assertEq(usdtRewardsClaimed, 0, "USDT rewards claimed changed");
//         assertEq(usdcRewardsClaimed, 0, "USDC rewards claimed changed");

//         assertEq(
//             staking.getStakerBandIds(alice),
//             stakerBandIds,
//             "Band Id's not removed"
//         );

//         vm.stopPrank();
//     }

//     function test_unstake_UnstakesAndTransfersTokens()
//         external
//         setBandLevelData
//         stakeTokens
//         distributeFunds
//     {
//         vm.warp(MONTH);
//         vm.startPrank(admin);
//         usdcToken.approve(address(staking), DEFAULT_DISTRIBUTION_AMOUNT);
//         staking.distributeFunds(usdcToken, DEFAULT_DISTRIBUTION_AMOUNT);
//         vm.stopPrank();

//         vm.startPrank(alice);
//         uint256 preStakingBalance = wowToken.balanceOf(alice);
//         staking.unstake(FIRST_STAKED_BAND_ID);
//         assertEq(
//             wowToken.balanceOf(address(staking)),
//             0,
//             "Tokens not transfered from contract"
//         );
//         assertEq(
//             wowToken.balanceOf(address(alice)),
//             preStakingBalance + BAND_4_PRICE,
//             "Tokens and rewards not transfered to staker"
//         );
//         vm.stopPrank();
//     }

//     // function test_unstake_MultipleTokenStake() external setBandLevelData {
//     //     uint256 currentTimestamp = 100;
//     //     vm.warp(currentTimestamp);

//     //     vm.startPrank(alice);
//     //     wowToken.approve(address(staking), BAND_2_PRICE);
//     //     staking.stake(STAKING_TYPE_FLEXI, BAND_ID_2);

//     //     uint256 secondStakeBandId = staking.getNextBandId();
//     //     wowToken.approve(address(staking), BAND_5_PRICE);
//     //     staking.stake(STAKING_TYPE_FIX, BAND_ID_5);

//     //     (
//     //         ,
//     //         uint256 startingSharesAmount,
//     //         address owner,
//     //         uint16 bandLevel,
//     //         uint256 stakingStartTimestamp,
//     //         uint256 usdtRewardsClaimed,
//     //         uint256 usdcRewardsClaimed
//     //     ) = staking.getStakerBandData(FIRST_STAKED_BAND_ID);

//     //     assertEq(owner, alice, "Owner not set");
//     //     assertEq(bandLevel, BAND_ID_2, "Band Level not set");
//     //     assertEq(stakingStartTimestamp, currentTimestamp, "Timestamp not set");
//     //     assertEq(usdtRewardsClaimed, 0, "USDT rewards claimed changed");
//     //     assertEq(usdcRewardsClaimed, 0, "USDC rewards claimed changed");

//     //     (
//     //         ,
//     //         startingSharesAmount,
//     //         owner,
//     //         bandLevel,
//     //         stakingStartTimestamp,
//     //         usdtRewardsClaimed,
//     //         usdcRewardsClaimed
//     //     ) = staking.getStakerBandData(secondStakeBandId);

//     //     assertEq(owner, alice, "Owner not set");
//     //     assertEq(bandLevel, BAND_ID_5, "Band Level not set");
//     //     assertEq(stakingStartTimestamp, currentTimestamp, "Timestamp not set");
//     //     assertEq(usdtRewardsClaimed, 0, "USDT rewards claimed changed");
//     //     assertEq(usdcRewardsClaimed, 0, "USDC rewards claimed changed");
//     //     vm.stopPrank();
//     // }

//     // function test_unstake_EmitsStaked() external setBandLevelData {
//     //     vm.startPrank(alice);
//     //     wowToken.approve(address(staking), BAND_2_PRICE);
//     //     vm.expectEmit(true, true, true, true);
//     //     emit Staked(alice, BAND_ID_2, STAKING_TYPE_FLEXI, false);
//     //     staking.stake(STAKING_TYPE_FLEXI, BAND_ID_2);
//     //     vm.stopPrank();
//     // }
// }
