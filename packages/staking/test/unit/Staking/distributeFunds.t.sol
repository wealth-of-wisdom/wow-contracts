// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.20;

// import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
// import {Errors} from "../../../contracts/libraries/Errors.sol";
// import {Unit_Test} from "../Unit.t.sol";

// contract Staking_DistributeFunds_Unit_Test is Unit_Test {
//     modifier mdistributeFunds() {
//         vm.prank(admin);
//         staking.distributeFunds(usdtToken, DEFAULT_DISTRIBUTION_AMOUNT);
//         _;
//     }

//     function test_distributeFunds_RevertIf_NotDefaultAdmin() external {
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 IAccessControl.AccessControlUnauthorizedAccount.selector,
//                 alice,
//                 DEFAULT_ADMIN_ROLE
//             )
//         );
//         vm.prank(alice);
//         staking.distributeFunds(usdtToken, DEFAULT_DISTRIBUTION_AMOUNT);
//     }

//     function test_distributeFunds_RevertIf_LevelAmountZero() external {
//         vm.expectRevert(
//             abi.encodeWithSelector(Errors.Staking__ZeroAmount.selector)
//         );
//         vm.prank(admin);
//         staking.distributeFunds(usdtToken, 0);
//     }

//     function test_distributeFunds_RevertIf_NonExistantToken() external {
//         vm.expectRevert(
//             abi.encodeWithSelector(Errors.Staking__NonExistantToken.selector)
//         );
//         vm.prank(admin);
//         staking.distributeFunds(wowToken, DEFAULT_DISTRIBUTION_AMOUNT);
//     }

//     function test_distributeFunds_DistributesFunds() external mdistributeFunds {
//         // assertEq(
//         //     staking.getTotalPools(),
//         //     NEW_TOTAL_POOL_AMOUNT,
//         //     "New total pool amount not set"
//         // );
//         // assertEq(
//         //     staking.getTotalPools(),
//         //     NEW_TOTAL_POOL_AMOUNT,
//         //     "New total pool amount not set"
//         // );
//         // assertEq(
//         //     staking.getTotalPools(),
//         //     NEW_TOTAL_POOL_AMOUNT,
//         //     "New total pool amount not set"
//         // );
//     }

//     function test_distributeFunds_EmisFundsDistributed() external {
//         vm.expectEmit(address(staking));
//         emit FundsDistributed(usdtToken, DEFAULT_DISTRIBUTION_AMOUNT);

//         vm.prank(admin);
//         staking.distributeFunds(usdtToken, DEFAULT_DISTRIBUTION_AMOUNT);
//     }
// }
