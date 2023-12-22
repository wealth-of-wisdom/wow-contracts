// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Vesting_Unit_Test} from "./VestingUnit.t.sol";

contract Vesting_Initialize_Unit_Test is Vesting_Unit_Test {
    function test_initialize_RevertIf_ListingDateNotInFuture() external {
        vm.expectRevert(Errors.Vesting__ListingDateNotInFuture.selector);
        vesting.initialize(
            token,
            vestingAdmin,
            listingDate,
            vestingDurationInMonths,
            cliffInDays,
            cliffPercentageDividend,
            cliffPercentageDivisor,
            listingPercentageDividend,
            listingPercentageDivisor,
            unlockType
        );
    }
}
