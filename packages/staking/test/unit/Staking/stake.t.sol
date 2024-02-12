// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.20;

// import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
// import {Errors} from "../../../contracts/libraries/Errors.sol";
// import {Unit_Test} from "../Unit.t.sol";
// import {IStaking} from "../../../contracts/interfaces/IStaking.sol";

// contract Staking_Stake_Unit_Test is Unit_Test {
//     uint256[] stakerBandIds = [0];

//     // enum TestStakingTypes {
//     //     FIX,
//     //     FLEXI,
//     //     FAUX
//     // }

//     function test_stake_RevertIf_InvalidBandLevel() external setBandLevelData {
//         uint16 fauxLevel = 100;
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 Errors.Staking__InvalidBandLevel.selector,
//                 fauxLevel
//             )
//         );
//         vm.prank(alice);
//         staking.stake(STAKING_TYPE_FLEXI, fauxLevel);
//     }

//     //NOTE: won't pass due to enum restrictions
//     // function test_stake_RevertIf_InvalidStakingType()
//     //     external
//     //     setBandLevelData
//     // {
//     //     vm.expectRevert(Errors.Staking__InvalidStakingType.selector);
//     //     vm.prank(alice);
//     //     staking.stake(TestStakingTypes.FAUX, BAND_ID_1);
//     // }

//     function test_stake_StakesTokensSetsData() external setBandLevelData {
//         uint256 currentTimestamp = 100;
//         vm.warp(currentTimestamp);

//         vm.startPrank(alice);
//         wowToken.approve(address(staking), BAND_2_PRICE);
//         staking.stake(STAKING_TYPE_FLEXI, BAND_ID_2);

//         (
//             ,
//             uint256 startingSharesAmount,
//             address owner,
//             uint16 bandLevel,
//             uint256 stakingStartTimestamp,
//             uint256 usdtRewardsClaimed,
//             uint256 usdcRewardsClaimed
//         ) = staking.getStakerBandData(FIRST_STAKED_BAND_ID);

//         assertEq(owner, alice, "Owner not set");
//         assertEq(bandLevel, BAND_ID_2, "Band Level not set");
//         assertEq(stakingStartTimestamp, currentTimestamp, "Timestamp not set");
//         assertEq(usdtRewardsClaimed, 0, "USDT rewards claimed changed");
//         assertEq(usdcRewardsClaimed, 0, "USDC rewards claimed changed");

//         assertEq(
//             staking.getStakerBandIds(alice),
//             stakerBandIds,
//             "Incorrect band Id's set"
//         );

//         vm.stopPrank();
//     }

//     function test_stake_StakesTokensTransfersTokens()
//         external
//         setBandLevelData
//     {
//         vm.startPrank(alice);
//         uint256 preStakingBalance = wowToken.balanceOf(alice);
//         wowToken.approve(address(staking), BAND_2_PRICE);
//         staking.stake(STAKING_TYPE_FLEXI, BAND_ID_2);
//         assertEq(
//             wowToken.balanceOf(address(staking)),
//             BAND_2_PRICE,
//             "Tokens not transfered to contract"
//         );
//         assertEq(
//             wowToken.balanceOf(address(alice)),
//             preStakingBalance - BAND_2_PRICE,
//             "Tokens not transfered from staker"
//         );
//         vm.stopPrank();
//     }

//     function test_stake_MultipleTokenStake() external setBandLevelData {
//         uint256 currentTimestamp = 100;
//         vm.warp(currentTimestamp);

//         vm.startPrank(alice);
//         wowToken.approve(address(staking), BAND_2_PRICE);
//         staking.stake(STAKING_TYPE_FLEXI, BAND_ID_2);

//         uint256 secondStakeBandId = staking.getNextBandId();
//         wowToken.approve(address(staking), BAND_5_PRICE);
//         staking.stake(STAKING_TYPE_FIX, BAND_ID_5);

//         (
//             ,
//             uint256 startingSharesAmount,
//             address owner,
//             uint16 bandLevel,
//             uint256 stakingStartTimestamp,
//             uint256 usdtRewardsClaimed,
//             uint256 usdcRewardsClaimed
//         ) = staking.getStakerBandData(FIRST_STAKED_BAND_ID);

//         assertEq(owner, alice, "Owner not set");
//         assertEq(bandLevel, BAND_ID_2, "Band Level not set");
//         assertEq(stakingStartTimestamp, currentTimestamp, "Timestamp not set");
//         assertEq(usdtRewardsClaimed, 0, "USDT rewards claimed changed");
//         assertEq(usdcRewardsClaimed, 0, "USDC rewards claimed changed");

//         (
//             ,
//             startingSharesAmount,
//             owner,
//             bandLevel,
//             stakingStartTimestamp,
//             usdtRewardsClaimed,
//             usdcRewardsClaimed
//         ) = staking.getStakerBandData(secondStakeBandId);

//         assertEq(owner, alice, "Owner not set");
//         assertEq(bandLevel, BAND_ID_5, "Band Level not set");
//         assertEq(stakingStartTimestamp, currentTimestamp, "Timestamp not set");
//         assertEq(usdtRewardsClaimed, 0, "USDT rewards claimed changed");
//         assertEq(usdcRewardsClaimed, 0, "USDC rewards claimed changed");
//         vm.stopPrank();
//     }

//     function test_stake_EmitsStaked() external setBandLevelData {
//         vm.startPrank(alice);
//         wowToken.approve(address(staking), BAND_2_PRICE);
//         vm.expectEmit(true, true, true, true);
//         emit Staked(alice, BAND_ID_2, STAKING_TYPE_FLEXI, false);
//         staking.stake(STAKING_TYPE_FLEXI, BAND_ID_2);
//         vm.stopPrank();
//     }
// }
