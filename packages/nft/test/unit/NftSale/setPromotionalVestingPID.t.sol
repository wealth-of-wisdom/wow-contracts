// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.20;

// import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
// import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
// import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
// import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
// import {NftSale_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftSaleUnit.t.sol";

// contract NftSale_SetPromotionalVestingPID_Unit_Test is NftSale_Unit_Test {
//     uint16 internal constant NEW_PROMOTIONAL_VESTING_PID = 4;

//     function test_setPromotionalVestingPID_RevertIf_NotDefaultAdmin() external {
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 IAccessControl.AccessControlUnauthorizedAccount.selector,
//                 alice,
//                 DEFAULT_ADMIN_ROLE
//             )
//         );
//         vm.prank(alice);
//         sale.setPromotionalVestingPID(NEW_PROMOTIONAL_VESTING_PID);
//     }

//     function test_setPromotionalVestingPID_SetsVestingPID() external {
//         vm.prank(admin);
//         sale.setPromotionalVestingPID(NEW_PROMOTIONAL_VESTING_PID);
//         assertEq(
//             sale.getPromotionalPID(),
//             NEW_PROMOTIONAL_VESTING_PID,
//             "New vesting pool id set incorrectly"
//         );
//     }

//     function test_setPromotionalVestingPIDdd_EmitsPromotionalVestingPIDSetEvent()
//         external
//     {
//         vm.expectEmit(true, true, true, true);
//         emit PromotionalVestingPIDSet(NEW_PROMOTIONAL_VESTING_PID);

//         vm.prank(admin);
//         sale.setPromotionalVestingPID(NEW_PROMOTIONAL_VESTING_PID);
//     }
// }
