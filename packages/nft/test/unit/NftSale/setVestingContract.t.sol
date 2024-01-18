// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.20;

// import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
// import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
// import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
// import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
// import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
// import {Nft_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftUnit.t.sol";

// contract NftSale_SetVestingContract_Unit_Test is Nft_Unit_Test {
//     IVesting internal constant newVesting = IVesting(address(100));

//     function test_setVestingContract_RevertIf_NotDefaultAdmin() external {
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 IAccessControl.AccessControlUnauthorizedAccount.selector,
//                 alice,
//                 DEFAULT_ADMIN_ROLE
//             )
//         );
//         vm.prank(alice);
//         sale.setVestingContract(newVesting);
//     }

//     function test_setVestingContract_RevertIf_ZeroAddress() external {
//         vm.expectRevert(Errors.Nft__ZeroAddress.selector);
//         vm.prank(admin);
//         sale.setVestingContract(IVesting(ZERO_ADDRESS));
//     }

//     function test_setVestingContract_SetsVestingContract() external {
//         vm.prank(admin);
//         sale.setVestingContract(newVesting);
//         assertEq(
//             address(sale.getVestingContract()),
//             address(newVesting),
//             "New vesting contract incorrect"
//         );
//     }

//     function test_setVestingContract_EmitsVestingContractSetEvent() external {
//         vm.expectEmit(true, true, true, true);
//         emit VestingContractSet(newVesting);

//         vm.prank(admin);
//         sale.setVestingContract(newVesting);
//     }
// }
