//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.20;

import {Staking} from "../Staking.sol";

contract StakingMock is Staking {
    function getPeriodDuration() public pure override returns (uint32) {
        return 10 minutes;
    }
}
