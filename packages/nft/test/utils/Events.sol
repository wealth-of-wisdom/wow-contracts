// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {INftEvents} from "../../contracts/interfaces/INft.sol";
import {INftSaleEvents} from "../../contracts/interfaces/INftSale.sol";

abstract contract Events is INftEvents, INftSaleEvents {
    event Initialized(uint64 version);
}
