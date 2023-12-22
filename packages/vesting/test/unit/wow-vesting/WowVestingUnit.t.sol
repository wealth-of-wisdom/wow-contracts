// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {Vesting} from "../../../contracts/Vesting.sol";
import {IVestingEvents} from "../../../contracts/interfaces/IVesting.sol";
import {Unit_Test} from "../Unit.t.sol";

contract WOW_Vesting_Unit_Test is Unit_Test, IVestingEvents {
    function setUp() public virtual override {
        Unit_Test.setUp();

        vesting = new Vesting();
        vesting.initialize(token, LISTING_DATE);
    }
}
