// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.20;

// import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
// import {IStaking} from "@wealth-of-wisdom/staking/contracts/interfaces/IStaking.sol";
// import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
// import {Errors} from "../../../contracts/libraries/Errors.sol";
// import {Vesting_Unit_Test} from "../VestingUnit.t.sol";

// contract Vesting_RemoveBeneficiary_Unit_Test is Vesting_Unit_Test {
//     uint256 calculatedUnlockedPoolTokens =
//         TOTAL_POOL_TOKEN_AMOUNT -
//             (BENEFICIARY_TOKEN_AMOUNT * CLIFF_PERCENTAGE_DIVIDEND) /
//             CLIFF_PERCENTAGE_DIVISOR -
//             (BENEFICIARY_TOKEN_AMOUNT * LISTING_PERCENTAGE_DIVIDEND) /
//             LISTING_PERCENTAGE_DIVISOR;

//     function test_removeBeneficiary_RevertIf_NotAdmin() external {
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 IAccessControl.AccessControlUnauthorizedAccount.selector,
//                 alice,
//                 DEFAULT_ADMIN_ROLE
//             )
//         );
//         vm.prank(alice);
//         vesting.removeBeneficiary(PRIMARY_POOL, alice);
//     }

//     function test_removeBeneficiary_RevertIf_PoolDoesNotExist() external {
//         vm.expectRevert(Errors.Vesting__PoolDoesNotExist.selector);
//         vm.prank(admin);
//         vesting.removeBeneficiary(PRIMARY_POOL, alice);
//     }

//     function test_removeBeneficiary_RevertIf_BeneficiaryDoesNotExist()
//         external
//         approveAndAddPool
//     {
//         vm.expectRevert(Errors.Vesting__BeneficiaryDoesNotExist.selector);
//         vm.prank(admin);
//         vesting.removeBeneficiary(PRIMARY_POOL, bob);
//     }

//     function test_removeBeneficiary_RevertIf_BeneficiaryIsZeroAddress()
//         external
//         approveAndAddPool
//     {
//         vm.expectRevert(Errors.Vesting__BeneficiaryDoesNotExist.selector);
//         vm.prank(admin);
//         vesting.removeBeneficiary(PRIMARY_POOL, address(0));
//     }

//     function test_removeBeneficiary_RemovesTotalUserAmountFromDedicatedAmountWhenNoTokensWereStakedOrClaimed()
//         external
//         approveAndAddPool
//         addBeneficiary(alice)
//         addBeneficiary(bob)
//     {
//         vm.warp(LISTING_DATE + 1 minutes);
//         vm.prank(admin);
//         vesting.removeBeneficiary(PRIMARY_POOL, alice);

//         (, , , uint256 dedicatedAmount) = vesting.getGeneralPoolData(
//             PRIMARY_POOL
//         );
//         assertEq(
//             dedicatedAmount,
//             BENEFICIARY_TOKEN_AMOUNT,
//             "Dedicated amount is incorrect"
//         );
//     }

//     function test_removeBeneficiary_DoesNotChangeDedicatedAmountWhenTokensAreClaimedButNotStaked()
//         external
//         approveAndAddPool
//         addBeneficiary(alice)
//         addBeneficiary(bob)
//     {
//         vm.warp(VESTING_END_DATE + 1 minutes);
//         vm.prank(alice);
//         vesting.claimTokens(PRIMARY_POOL);

//         vm.prank(admin);
//         vesting.removeBeneficiary(PRIMARY_POOL, alice);

//         (, , , uint256 dedicatedAmount) = vesting.getGeneralPoolData(
//             PRIMARY_POOL
//         );
//         assertEq(
//             dedicatedAmount,
//             BENEFICIARY_TOKEN_AMOUNT * 2,
//             "Dedicated amount is incorrect"
//         );
//     }

//     function test_removeBeneficiary_DeletesUserWhenNoTokensWereStakedOrClaimed()
//         external
//         approveAndAddPool
//         addBeneficiary(alice)
//     {
//         vm.warp(LISTING_DATE + 1 minutes);
//         vm.prank(admin);
//         vesting.removeBeneficiary(PRIMARY_POOL, alice);

//         IVesting.Beneficiary memory aliceBeneficiary = vesting.getBeneficiary(
//             PRIMARY_POOL,
//             alice
//         );

//         assertBeneficiaryData(aliceBeneficiary, 0, 0, 0);
//     }

//     // function test_removeBeneficiary_DeletesUserWhenTokensAreStakedAndClaimed()
//     //     external
//     //     approveAndAddPool
//     //     addBeneficiary(alice)
//     // {
//     //     vm.warp(CLIFF_END_DATE);
//     //     vm.prank(alice);
//     //     vesting.claimTokens(PRIMARY_POOL);

//     //     vm.prank(address(staking));
//     //     vesting.updateVestedStakedTokens(
//     //         PRIMARY_POOL,
//     //         alice,
//     //         BENEFICIARY_TOKEN_AMOUNT - LISTING_AND_CLIFF_TOKEN_AMOUNT,
//     //         true
//     //     );

//     //     vm.prank(admin);
//     //     vesting.removeBeneficiary(PRIMARY_POOL, alice);

//     //     IVesting.Beneficiary memory aliceBeneficiary = vesting.getBeneficiary(
//     //         PRIMARY_POOL,
//     //         alice
//     //     );

//     //     assertBeneficiaryData(aliceBeneficiary, 0, 0, 0);
//     // }

//     function test_removeBeneficiary_DoesNotUnstakeVestedTokensWhenNoTokensWereStakedOrClaimed()
//         external
//         approveAndAddPool
//         addBeneficiary(alice)
//     {
//         vm.warp(LISTING_DATE + 1 minutes);
//         vm.prank(admin);
//         vesting.removeBeneficiary(PRIMARY_POOL, alice);

//         bool called = staking.wasUnstakesVestedTokensCalled();
//         assertFalse(called, "Unstake vested tokens was called");
//     }

//     // function test_removeBeneficiary_UnstakesVestedTokensWhenTokensAreStakedAndClaimed()
//     //     external
//     //     approveAndAddPool
//     //     addBeneficiary(alice)
//     // {
//     //     vm.warp(CLIFF_END_DATE);
//     //     vm.prank(alice);
//     //     vesting.claimTokens(PRIMARY_POOL);

//     //     vm.prank(address(staking));
//     //     vesting.updateVestedStakedTokens(
//     //         PRIMARY_POOL,
//     //         alice,
//     //         BENEFICIARY_TOKEN_AMOUNT - LISTING_AND_CLIFF_TOKEN_AMOUNT,
//     //         true
//     //     );

//     //     vm.expectCall(
//     //         address(staking),
//     //         abi.encodeWithSelector(
//     //             IStaking.unstakeVestedTokens.selector,
//     //             alice,
//     //             BENEFICIARY_TOKEN_AMOUNT - LISTING_AND_CLIFF_TOKEN_AMOUNT
//     //         )
//     //     );
//     //     vm.prank(admin);
//     //     vesting.removeBeneficiary(PRIMARY_POOL, alice);

//     //     bool called = staking.wasUnstakesVestedTokensCalled();
//     //     assertTrue(called, "Unstake vested tokens was not called");
//     // }

//     // function test_removeBeneficiary_UnstakesVestedTokensWhenTokensAreStakedButNotClaimed()
//     //     external
//     //     approveAndAddPool
//     //     addBeneficiary(alice)
//     // {
//     //     vm.warp(CLIFF_END_DATE);
//     //     vm.prank(address(staking));
//     //     vesting.updateVestedStakedTokens(
//     //         PRIMARY_POOL,
//     //         alice,
//     //         BENEFICIARY_TOKEN_AMOUNT,
//     //         true
//     //     );

//     //     vm.expectCall(
//     //         address(staking),
//     //         abi.encodeWithSelector(
//     //             IStaking.unstakeVestedTokens.selector,
//     //             alice,
//     //             BENEFICIARY_TOKEN_AMOUNT
//     //         )
//     //     );
//     //     vm.prank(admin);
//     //     vesting.removeBeneficiary(PRIMARY_POOL, alice);

//     //     bool called = staking.wasUnstakesVestedTokensCalled();
//     //     assertTrue(called, "Unstake vested tokens was not called");
//     // }

//     function test_removeBeneficiary_EmitsBeneficiaryRemovedEvent()
//         external
//         approveAndAddPool
//         addBeneficiary(alice)
//     {
//         vm.warp(LISTING_DATE + 1 minutes);
//         vm.expectEmit(true, true, true, true);
//         emit BeneficiaryRemoved(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);

//         vm.prank(admin);
//         vesting.removeBeneficiary(PRIMARY_POOL, alice);
//     }
// }
