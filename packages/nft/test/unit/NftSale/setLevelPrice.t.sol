// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.20;

// import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
// import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
// import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
// import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
// import {Nft_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftUnit.t.sol";

// contract NftSale_SetLevelPrice_Unit_Test is Nft_Unit_Test {
//     uint256 internal constant NEW_USD_PRICE = 50 * USD_DECIMALS;

//     function test_setLevelPrice_RevertIf_NotDefaultAdmin() external {
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 IAccessControl.AccessControlUnauthorizedAccount.selector,
//                 alice,
//                 DEFAULT_ADMIN_ROLE
//             )
//         );
//         vm.prank(alice);
//         sale.setLevelPrice(LEVEL_2, NEW_USD_PRICE);
//     }

//     function test_setLevelPrice_RevertIf_InvalidLevel() external {
//         vm.expectRevert(
//             abi.encodeWithSelector(Errors.NftSale__InvalidLevel.selector, 0)
//         );
//         vm.prank(admin);
//         sale.setLevelPrice(0, NEW_USD_PRICE);
//     }

//     function test_setLevelPrice_RevertIf_PassedZeroAmount() external {
//         vm.expectRevert(Errors.Nft__PassedZeroAmount.selector);
//         vm.prank(admin);
//         sale.setLevelPrice(LEVEL_2, 0);
//     }

//     function test_setLevelPrice_SetsNewLevelPrice() external {
//         vm.prank(admin);
//         sale.setLevelPrice(LEVEL_2, NEW_USD_PRICE);
//         assertEq(
//             sale.getLevelPriceInUSD(LEVEL_2),
//             NEW_USD_PRICE,
//             "New price not set"
//         );
//     }

//     function test_setLevelPrice_EmitsLevelPriceSetEvent() external {
//         vm.expectEmit(true, true, true, true);
//         emit LevelPriceSet(LEVEL_2, NEW_USD_PRICE);

//         vm.prank(admin);
//         sale.setLevelPrice(LEVEL_2, NEW_USD_PRICE);
//     }
// }
