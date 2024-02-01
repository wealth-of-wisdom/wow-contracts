// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                    STAKING
    //////////////////////////////////////////////////////////////////////////*/

    error Staking__InvalidBandId(uint16 bandId);
    error Staking__MaximumLevelExceeded();
    error Staking__ZeroAmount();
    error Staking__ZeroAddress();
}
