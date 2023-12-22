// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.20;

// import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
// import {Errors} from "../../../contracts/libraries/Errors.sol";
// import {Vesting_Unit_Test} from "./VestingUnit.t.sol";

// contract Vesting_AddBeneficiary_Unit_Test is Vesting_Unit_Test {
//     /* ========== INITIALIZE TESTS ========== */

//     function test_addBeneficiary_AddsBeneficiaryToPool() external {
//         _addDefaultVestingPool();
//         checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);

//         vesting.addBeneficiary(
//             PRIMARY_POOL,
//             alice,
//             BENEFICIARY_TOKEN_AMOUNT
//         );
//         _checkBeneficiaryState(
//             PRIMARY_POOL,
//             alice,
//             BENEFICIARY_TOKEN_AMOUNT,
//             0
//         );
//     }

//     function test_addBeneficiary_RevertIf_NotAdmin() external {
//         vm.prank(alice);
//         vm.expectRevert();
//         vesting.addBeneficiary(
//             PRIMARY_POOL,
//             alice,
//             BENEFICIARY_TOKEN_AMOUNT
//         );
//     }

//     function test_addBeneficiary_RevertIf_TokenAmonutZero() external {
//         _addDefaultVestingPool();
//         checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
//         vm.expectRevert(Errors.Vesting__TokenAmountZero.selector);
//         vesting.addBeneficiary(PRIMARY_POOL, alice, 0);
//     }

//     function test_addBeneficiary_RevertIf_PoolDoesNotExist() external {
//         vm.expectRevert(Errors.Vesting__PoolDoesNotExist.selector);
//         vesting.addBeneficiary(
//             PRIMARY_POOL,
//             alice,
//             BENEFICIARY_TOKEN_AMOUNT
//         );
//     }

//     function test_addBeneficiary_RevertIf_TokenAmountExeedsTotalPoolAmount()
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
//         vesting.addBeneficiary(
//             PRIMARY_POOL,
//             alice,
//             BENEFICIARY_TOKEN_AMOUNT
//         );
//     }

//     function test_addBeneficiary_CanaddBeneficiaryTwice() external {
//         uint newAmount = 100;
//         _addDefaultVestingPool();
//         checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
//         vesting.addBeneficiary(
//             PRIMARY_POOL,
//             alice,
//             BENEFICIARY_TOKEN_AMOUNT
//         );
//         vesting.addBeneficiary(PRIMARY_POOL, alice, newAmount);
//         _checkBeneficiaryState(
//             PRIMARY_POOL,
//             alice,
//             BENEFICIARY_TOKEN_AMOUNT + newAmount,
//             0
//         );
//     }
// }
