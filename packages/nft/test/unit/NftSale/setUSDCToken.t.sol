// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.20;

// import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
// import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
// import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
// import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
// import {Nft_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftUnit.t.sol";

// contract NftSale_SetUSDCToken_Unit_Test is Nft_Unit_Test {
//     IERC20 internal constant NEW_USDC_TOKEN = IERC20(address(100));

//     function test_setUSDCToken_RevertIf_NotDefaultAdmin() external {
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 IAccessControl.AccessControlUnauthorizedAccount.selector,
//                 alice,
//                 DEFAULT_ADMIN_ROLE
//             )
//         );
//         vm.prank(alice);
//         sale.setUSDCToken(NEW_USDC_TOKEN);
//     }

//     function test_setUSDCToken_SetsUSDCToken() external {
//         vm.prank(admin);
//         sale.setUSDCToken(NEW_USDC_TOKEN);
//         assertEq(
//             address(sale.getTokenUSDC()),
//             address(NEW_USDC_TOKEN),
//             "New token is incorrectly"
//         );
//     }

//     function test_setUSDCTokendd_EmitsPromotionalVestingPIDSetEvent() external {
//         vm.expectEmit(true, true, true, true);
//         emit USDCTokenSet(NEW_USDC_TOKEN);

//         vm.prank(admin);
//         sale.setUSDCToken(NEW_USDC_TOKEN);
//     }
// }
