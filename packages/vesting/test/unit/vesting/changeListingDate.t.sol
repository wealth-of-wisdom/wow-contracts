// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.20;

// import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
// import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
// import {Errors} from "../../../contracts/libraries/Errors.sol";
// import {Vesting_Unit_Test} from "../VestingUnit.t.sol";

// contract Vesting_ChangeListingDate_Unit_Test is Vesting_Unit_Test {
//     uint32 internal immutable NEW_LISTING_DATE;

//     constructor() Vesting_Unit_Test() {
//         NEW_LISTING_DATE = LISTING_DATE + 1 days;
//     }

//     function test_changeListingDate_RevertIf_CallerNotAdmin() external {
//         vm.expectRevert(
//             abi.encodeWithSelector(
//                 IAccessControl.AccessControlUnauthorizedAccount.selector,
//                 alice,
//                 DEFAULT_ADMIN_ROLE
//             )
//         );
//         vm.prank(alice);
//         vesting.changeListingDate(NEW_LISTING_DATE);
//     }

//     function test_changeListingDate_RevertIf_InvalidListingDate() external {
//         vm.warp(NEW_LISTING_DATE);
//         vm.expectRevert(Errors.Vesting__ListingDateNotInFuture.selector);
//         vm.prank(admin);
//         vesting.changeListingDate(NEW_LISTING_DATE - 1 seconds);
//     }

//     function test_changeListingDate_UpdatesListingDateVariable() external {
//         vm.prank(admin);
//         vesting.changeListingDate(NEW_LISTING_DATE);

//         assertEq(vesting.getListingDate(), NEW_LISTING_DATE);
//     }

//     function test_changeListingDate_UpdatesCliffEndDateForSinglePool()
//         external
//         approveAndAddPool
//     {
//         vm.prank(admin);
//         vesting.changeListingDate(NEW_LISTING_DATE);

//         (uint32 cliffEndDate, , , ) = vesting.getPoolCliffData(PRIMARY_POOL);
//         assertEq(cliffEndDate, NEW_LISTING_DATE + CLIFF_IN_SECONDS);
//     }

//     function test_changeListingDate_UpdatesCliffEndDateForMultiplePools()
//         external
//     {
//         _approveAndAddPool(POOL_NAME);
//         _approveAndAddPool(POOL_NAME_2);

//         vm.prank(admin);
//         vesting.changeListingDate(NEW_LISTING_DATE);

//         (uint32 cliffEndDate, , , ) = vesting.getPoolCliffData(PRIMARY_POOL);
//         assertEq(cliffEndDate, NEW_LISTING_DATE + CLIFF_IN_SECONDS);

//         (cliffEndDate, , , ) = vesting.getPoolCliffData(SECONDARY_POOL);
//         assertEq(cliffEndDate, NEW_LISTING_DATE + CLIFF_IN_SECONDS);
//     }

//     function test_changeListingDate_UpdatesVestingEndDateForSinglePool()
//         external
//         approveAndAddPool
//     {
//         vm.prank(admin);
//         vesting.changeListingDate(NEW_LISTING_DATE);

//         (uint32 vestingEndDate, , ) = vesting.getPoolVestingData(PRIMARY_POOL);
//         assertEq(
//             vestingEndDate,
//             NEW_LISTING_DATE + CLIFF_IN_SECONDS + VESTING_DURATION_IN_SECONDS
//         );
//     }

//     function test_changeListingDate_UpdatesVestingEndDateForMultiplePools()
//         external
//     {
//         _approveAndAddPool(POOL_NAME);
//         _approveAndAddPool(POOL_NAME_2);

//         vm.prank(admin);
//         vesting.changeListingDate(NEW_LISTING_DATE);

//         (uint32 vestingEndDate, , ) = vesting.getPoolVestingData(PRIMARY_POOL);
//         assertEq(
//             vestingEndDate,
//             NEW_LISTING_DATE + CLIFF_IN_SECONDS + VESTING_DURATION_IN_SECONDS
//         );

//         (vestingEndDate, , ) = vesting.getPoolVestingData(SECONDARY_POOL);
//         assertEq(
//             vestingEndDate,
//             NEW_LISTING_DATE + CLIFF_IN_SECONDS + VESTING_DURATION_IN_SECONDS
//         );
//     }

//     function test_changeListingDate_EmitsListingDateChangedEvent()
//         external
//         approveAndAddPool
//     {
//         vm.expectEmit(address(vesting));
//         emit ListingDateChanged(LISTING_DATE, NEW_LISTING_DATE);

//         vm.prank(admin);
//         vesting.changeListingDate(NEW_LISTING_DATE);
//     }
// }
