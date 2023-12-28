// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Vesting} from "../../../contracts/Vesting.sol";
import {IVestingEvents} from "../../../contracts/interfaces/IVesting.sol";
import {Base_Test} from "../../Base.t.sol";

contract Vesting_Unit_Test is Base_Test, IVestingEvents {
    constructor() Base_Test() {}

    function setUp() public virtual override {
        Base_Test.setUp();

        vm.startPrank(admin);
        vesting = new Vesting();
        vesting.initialize(token, staking, LISTING_DATE);
        vm.stopPrank();
    }
}
