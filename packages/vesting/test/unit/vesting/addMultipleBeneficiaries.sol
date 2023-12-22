// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.20;

// import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
// import {Errors} from "../../../contracts/libraries/Errors.sol";
// import {Vesting_Unit_Test} from "./VestingUnit.t.sol";

// contract Vesting_AddMultipleBeneficiaries_Unit_Test is Vesting_Unit_Test {
//     event Initialized(uint8 version);

//     /* ========== INITIALIZE TESTS ========== */

//     function test_addMultipleBeneficiaries_RevertIf_NotAdmin() external {
//         vm.prank(alice);
//         vm.expectRevert();
//         vesting.addMultipleBeneficiaries(
//             PRIMARY_POOL,
//             beneficiaries,
//             tokenAmounts
//         );
//     }

//     function test_addMultipleBeneficiaries_RevertIf_ArraySizeMismatch()
//         external
//     {
//         tokenAmounts = [BENEFICIARY_TOKEN_AMOUNT];
//         vm.expectRevert(Errors.Vesting__ArraySizeMismatch.selector);
//         vesting.addMultipleBeneficiaries(
//             PRIMARY_POOL,
//             beneficiaries,
//             tokenAmounts
//         );
//     }

//     function test_addMultipleBeneficiaries_RevertIf_TokenAmountExeedsTotalPoolAmount()
//         external
//     {
//         vesting.addVestingPool(
//             POOL_NAME,
//             LISTING_PERCENTAGE_DIVIDEND,
//             LISTING_PERCENTAGE_DIVISOR,
//             CLIFF_IN_DAYS,
//             CLIFF_PERCENTAGE_DIVIDEND,
//             CLIFF_PERCENTAGE_DIVISOR,
//             VESTING_DURATION_IN_MONTHS,
//             IVesting.UnlockTypes.MONTHLY,
//             100
//         );
//         vm.expectRevert(
//             Errors.Vesting__TokenAmountExeedsTotalPoolAmount.selector
//         );
//         vesting.addMultipleBeneficiaries(
//             PRIMARY_POOL,
//             beneficiaries,
//             tokenAmounts
//         );
//     }

//     function test_addMultipleBeneficiaries_AddsMultipleBeneficiaries()
//         external
//     {
//         _addDefaultVestingPool();
//         checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
//         vesting.addMultipleBeneficiaries(
//             PRIMARY_POOL,
//             beneficiaries,
//             tokenAmounts
//         );
//         _checkBeneficiaryState(
//             PRIMARY_POOL,
//             alice,
//             BENEFICIARY_TOKEN_AMOUNT,
//             0
//         );

//         _checkBeneficiaryState(
//             PRIMARY_POOL,
//             bob,
//             BENEFICIARY_TOKEN_AMOUNT,
//             0
//         );
//     }
// }
