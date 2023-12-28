// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Vesting} from "../../contracts/Vesting.sol";
import {IVesting} from "../../contracts/interfaces/IVesting.sol";

contract VestingMock is Vesting {
    function mock_setClaimedAmount(
        uint16 pid,
        address beneficiary,
        uint256 claimedAmount
    ) external {
        s_vestingPools[pid]
            .beneficiaries[beneficiary]
            .claimedTokenAmount = claimedAmount;
    }

    function mock_setPoolUnlockType(
        uint16 pid,
        IVesting.UnlockTypes unlockType
    ) external {
        s_vestingPools[pid].unlockType = unlockType;
    }
}
