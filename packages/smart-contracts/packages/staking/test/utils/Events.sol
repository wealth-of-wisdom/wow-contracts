// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IStakingEvents} from "../../contracts/interfaces/IStaking.sol";

abstract contract Events is IStakingEvents {
    event Initialized(uint64 version);
}
