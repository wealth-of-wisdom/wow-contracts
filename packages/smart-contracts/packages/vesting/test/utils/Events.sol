// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IVestingEvents} from "../../contracts/interfaces/IVesting.sol";

interface Events is IVestingEvents {
    event Initialized(uint64 version);
}
