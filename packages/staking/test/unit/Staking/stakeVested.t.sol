// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.20;

// import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
// import {Errors} from "../../../contracts/libraries/Errors.sol";
// import {Unit_Test} from "../Unit.t.sol";
// import {IStaking} from "../../../contracts/interfaces/IStaking.sol";

// contract Staking_StakeVested_Unit_Test is Unit_Test {
//     uint256[] stakerBandIds = [0];

//     modifier mGrantVestingRole() {
//         vm.prank(admin);
//         staking.grantRole(DEFAULT_VESTING_ROLE, alice);
//         _;
//     }

//     function test_stakeVested_RevertIf_NotVestingContract() external {
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 IAccessControl.AccessControlUnauthorizedAccount.selector,
//                 alice,
//                 DEFAULT_VESTING_ROLE
//             )
//         );
//         vm.prank(alice);
//         staking.stakeVested(STAKING_TYPE_FLEXI, BAND_ID_2, alice);
//     }

//     function test_stakeVested_RevertIf_InvalidBandLevel()
//         external
//         mGrantVestingRole
//         setBandLevelData
//     {
//         uint16 fauxLevel = 100;
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 Errors.Staking__InvalidBandLevel.selector,
//                 fauxLevel
//             )
//         );
//         vm.prank(alice);
//         staking.stakeVested(STAKING_TYPE_FLEXI, fauxLevel, alice);
//     }

//     function test_stakeVested_StakesTokensSetsData()
//         external
//         mGrantVestingRole
//         setBandLevelData
//     {
//         uint256 currentTimestamp = 100;
//         vm.warp(currentTimestamp);

//         vm.startPrank(alice);
//         wowToken.approve(address(staking), BAND_2_PRICE);
//         staking.stakeVested(STAKING_TYPE_FLEXI, BAND_ID_2, alice);

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

//     function test_stakeVested_StakesTokensTransfersTokens()
//         external
//         mGrantVestingRole
//         setBandLevelData
//     {
//         vm.startPrank(alice);
//         uint256 preStakingBalance = wowToken.balanceOf(alice);

//         wowToken.approve(address(staking), BAND_2_PRICE);
//         staking.stakeVested(STAKING_TYPE_FLEXI, BAND_ID_2, alice);
//         assertEq(
//             wowToken.balanceOf(address(staking)),
//             0,
//             "Tokens should not have been transfered to contract"
//         );
//         assertEq(
//             wowToken.balanceOf(address(alice)),
//             preStakingBalance,
//             "Tokens should not have been transfered from user"
//         );
//         vm.stopPrank();
//     }

//     function test_stakeVested_MultipleTokenStake()
//         external
//         mGrantVestingRole
//         setBandLevelData
//     {
//         uint256 currentTimestamp = 100;
//         vm.warp(currentTimestamp);

//         vm.startPrank(alice);
//         wowToken.approve(address(staking), BAND_2_PRICE);
//         staking.stakeVested(STAKING_TYPE_FLEXI, BAND_ID_2, alice);

//         uint256 secondStakeBandId = staking.getNextBandId();
//         wowToken.approve(address(staking), BAND_5_PRICE);
//         staking.stakeVested(STAKING_TYPE_FLEXI, BAND_ID_5, alice);

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

//     function test_stakeVested_EmitsStaked()
//         external
//         mGrantVestingRole
//         setBandLevelData
//     {
//         vm.startPrank(alice);
//         wowToken.approve(address(staking), BAND_2_PRICE);
//         vm.expectEmit(true, true, true, true);
//         emit Staked(alice, BAND_ID_2, STAKING_TYPE_FLEXI, true);
//         staking.stakeVested(STAKING_TYPE_FLEXI, BAND_ID_2, alice);
//         vm.stopPrank();
//     }
// }
