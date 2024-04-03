// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Vesting} from "../../contracts/Vesting.sol";
import {IVesting} from "../../contracts/interfaces/IVesting.sol";

contract VestingMock is Vesting {
    /*//////////////////////////////////////////////////////////////////////////////
                              EXPOSED INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////////*/

    function exposed_getTokensByPercentage(
        uint256 totalAmount,
        uint16 dividend,
        uint16 divisor
    ) external pure returns (uint256) {
        return _getTokensByPercentage(totalAmount, dividend, divisor);
    }

    /*//////////////////////////////////////////////////////////////////////////////
                                    MOCK FUNCTIONS
    //////////////////////////////////////////////////////////////////////////////*/

    function mock_setClaimedAmount(
        uint16 pid,
        address beneficiary,
        uint256 claimedAmount
    ) external {
        s_vestingPools[pid]
            .beneficiaries[beneficiary]
            .claimedTokenAmount = claimedAmount;
    }

    function mock_setStakedAmount(
        uint16 pid,
        address beneficiary,
        uint256 stakedAmount
    ) external {
        s_vestingPools[pid]
            .beneficiaries[beneficiary]
            .stakedTokenAmount = stakedAmount;
    }

    function mock_setPoolUnlockType(
        uint16 pid,
        IVesting.UnlockTypes unlockType
    ) external {
        s_vestingPools[pid].unlockType = unlockType;
    }
}
