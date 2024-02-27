// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.20;

// import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
// import {IStaking} from "@wealth-of-wisdom/staking/contracts/interfaces/IStaking.sol";
// import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
// import {Errors} from "../../../contracts/libraries/Errors.sol";
// import {VestingMock} from "../../mocks/VestingMock.sol";
// import {Vesting_Unit_Test} from "../VestingUnit.t.sol";

// contract Vesting_Initialize_Unit_Test is Vesting_Unit_Test {
//     function setUp() public virtual override {
//         Vesting_Unit_Test.setUp();

//         vesting = new VestingMock();
//     }

//     /*//////////////////////////////////////////////////////////////////////////////
//                                         TESTS
//     //////////////////////////////////////////////////////////////////////////////*/

//     function test_initialize_RevertIf_TokenIsZeroAddress() external {
//         vm.expectRevert(Errors.Vesting__ZeroAddress.selector);
//         vesting.initialize(IERC20(ZERO_ADDRESS), staking, LISTING_DATE);
//     }

//     function test_initialize_RevertIf_StakingContractIsZeroAddress() external {
//         vm.expectRevert(Errors.Vesting__ZeroAddress.selector);
//         vesting.initialize(wowToken, IStaking(ZERO_ADDRESS), LISTING_DATE);
//     }

//     function test_initialize_RevertIf_ListingDateNotInFuture() external {
//         vm.warp(LISTING_DATE + 1 seconds);
//         vm.expectRevert(Errors.Vesting__ListingDateNotInFuture.selector);
//         vesting.initialize(wowToken, staking, LISTING_DATE);
//     }

//     function test_initialize_GrantsDefaultAdminRoleToAdmin() external {
//         vm.warp(LISTING_DATE - 1 seconds);
//         vm.prank(admin);
//         vesting.initialize(wowToken, staking, LISTING_DATE);

//         assertTrue(
//             vesting.hasRole(DEFAULT_ADMIN_ROLE, admin),
//             "Admin should have default admin role"
//         );
//     }

//     function test_initialize_SetsVestingTokenCorrectly() external {
//         vm.warp(LISTING_DATE - 1 seconds);
//         vesting.initialize(wowToken, staking, LISTING_DATE);

//         assertEq(
//             address(vesting.getToken()),
//             address(wowToken),
//             "Token should be set correctly"
//         );
//     }

//     function test_initialize_SetsStakingContractCorrectly() external {
//         vm.warp(LISTING_DATE - 1 seconds);
//         vesting.initialize(wowToken, staking, LISTING_DATE);

//         assertEq(
//             address(vesting.getStakingContract()),
//             address(staking),
//             "Staking contract should be set correctly"
//         );
//     }

//     function test_initialize_SetsListingDateCorrectly() external {
//         vm.warp(LISTING_DATE - 1 seconds);
//         vesting.initialize(wowToken, staking, LISTING_DATE);

//         assertEq(
//             vesting.getListingDate(),
//             LISTING_DATE,
//             "Listing date should be set correctly"
//         );
//     }

//     function test_initialize_LeavesPoolCountAtZero() external {
//         vm.warp(LISTING_DATE - 1 seconds);
//         vesting.initialize(wowToken, staking, LISTING_DATE);

//         assertEq(vesting.getPoolCount(), 0, "Pool count should be zero");
//     }

//     function test_initialize_EmitsInitializedEvent() external {
//         vm.warp(LISTING_DATE - 1 seconds);
//         vm.expectEmit(true, true, true, true);
//         emit Initialized(1);

//         vesting.initialize(wowToken, staking, LISTING_DATE);
//     }
// }
