// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.20;

// import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
// import {Errors} from "../../../contracts/libraries/Errors.sol";
// import {Unit_Test} from "../Unit.t.sol";

// contract Staking_SetSharesInMonth_Unit_Test is Unit_Test {
//     function test_setSharesInMonth_RevertIf_NotDefaultAdmin() external {
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 IAccessControl.AccessControlUnauthorizedAccount.selector,
//                 alice,
//                 DEFAULT_ADMIN_ROLE
//             )
//         );
//         vm.prank(alice);
//         staking.setSharesInMonth(SHARES_IN_MONTH);
//     }

//     function test_setSharesInMonth_SetsSharesInMonth() external {
//         vm.prank(admin);
//         staking.setSharesInMonth(SHARES_IN_MONTH);

//         for (uint256 i = 0; i < SHARES_IN_MONTH.length; i++) {
//             uint48 shares = staking.getSharesInMonth(i);
//             assertEq(shares, SHARES_IN_MONTH[i], "Shares in month not set");
//         }
//     }

//     function test_setSharesInMonth_EmitsSharesInMonthSetEvent() external {
//         vm.expectEmit(address(staking));
//         emit SharesInMonthSet(SHARES_IN_MONTH);

//         vm.prank(admin);
//         staking.setSharesInMonth(SHARES_IN_MONTH);
//     }
// }
