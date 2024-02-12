// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.20;

// import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
// import {Errors} from "../../../contracts/libraries/Errors.sol";
// import {Unit_Test} from "../Unit.t.sol";

// contract Staking_SetTotalBandLevelsAmount_Unit_Test is Unit_Test {
//     modifier mSetTotalBandLevelsAmount4() {
//         vm.prank(admin);
//         staking.setTotalBandLevelsAmount(NEW_TOTAL_BAND_LEVELS);
//         _;
//     }

//     function test_setTotalBandLevelsAmount_RevertIf_NotDefaultAdmin() external {
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 IAccessControl.AccessControlUnauthorizedAccount.selector,
//                 alice,
//                 DEFAULT_ADMIN_ROLE
//             )
//         );
//         vm.prank(alice);
//         staking.setTotalBandLevelsAmount(NEW_TOTAL_BAND_LEVELS);
//     }

//     function test_setTotalBandLevelsAmount_RevertIf_LevelAmountZero() external {
//         vm.expectRevert(
//             abi.encodeWithSelector(Errors.Staking__ZeroAmount.selector)
//         );
//         vm.prank(admin);
//         staking.setTotalBandLevelsAmount(0);
//     }

//     function test_setTotalBandLevelsAmount_SetsTotalBandLevelAmount()
//         external
//         mSetTotalBandLevelsAmount4
//     {
//         assertEq(
//             staking.getTotalBands(),
//             NEW_TOTAL_BAND_LEVELS,
//             "New total band level not set"
//         );
//     }

//     function test_setTotalBandLevelsAmount_EmitsTotalBandLevelsAmountSet()
//         external
//     {
//         vm.expectEmit(address(staking));
//         emit TotalBandLevelsAmountSet(NEW_TOTAL_BAND_LEVELS);

//         vm.prank(admin);
//         staking.setTotalBandLevelsAmount(NEW_TOTAL_BAND_LEVELS);
//     }
// }
