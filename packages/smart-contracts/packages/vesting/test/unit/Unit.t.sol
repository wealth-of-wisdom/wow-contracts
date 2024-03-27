// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IVestingEvents} from "../../contracts/interfaces/IVesting.sol";
import {VestingMock} from "../mocks/VestingMock.sol";
import {Base_Test} from "../Base.t.sol";

contract Unit_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
    }
}
