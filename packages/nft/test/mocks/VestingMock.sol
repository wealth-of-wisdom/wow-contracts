// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Vesting} from "@wealth-of-wisdom/vesting/contracts/Vesting.sol";
import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";

contract VestingMock is Vesting {
    function mock_setDedicatedAmount(
        uint16 pid,
        uint256 dedicatedAmount
    ) external {
        s_vestingPools[pid].dedicatedPoolTokenAmount = dedicatedAmount;
    }
}
