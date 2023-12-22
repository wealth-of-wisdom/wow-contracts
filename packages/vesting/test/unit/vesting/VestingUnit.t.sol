// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {Vesting} from "../../../contracts/Vesting.sol";
import {IVestingEvents} from "../../../contracts/interfaces/IVesting.sol";
import {Base_Test} from "../../Base.t.sol";

contract Vesting_Unit_Test is Base_Test, IVestingEvents {
    function setUp() public virtual override {
        Base_Test.setUp();

        vm.startPrank(admin);
        vesting = new Vesting();
        vesting.initialize(token, LISTING_DATE);
        vm.stopPrank();
    }
}
