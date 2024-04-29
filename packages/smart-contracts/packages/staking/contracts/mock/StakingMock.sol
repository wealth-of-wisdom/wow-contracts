//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.20;

import {Staking} from "../Staking.sol";
import {Errors} from "../libraries/Errors.sol";

contract StakingMock is Staking {
    uint32 public constant PERIOD_DURATION = 10 minutes;

    function _validateFixedPeriodPassed(
        StakerBand storage band
    ) internal view override {
        if (band.stakingType == StakingTypes.FIX) {
            uint32 monthsPassed = (uint32(block.timestamp) -
                band.stakingStartDate) / PERIOD_DURATION;

            // Checks: fixed staking can only be unstaked after the fixed period
            if (monthsPassed < band.fixedMonths) {
                revert Errors.Staking__UnlockDateNotReached();
            }
        }
    }
}
