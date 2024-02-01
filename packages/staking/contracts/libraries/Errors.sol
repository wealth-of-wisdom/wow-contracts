// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                    STAKING
    //////////////////////////////////////////////////////////////////////////*/

    error Staking__InvalidPoolId(uint16 poolId);
    error Staking__InvalidDistributionPercentage(uint24 percentage);
    error Staking__BandAllocationExceedsMaximum(uint24 percentage);
    error Staking__TotalAllocationExceedsMaximum(uint24 percentage);
    error Staking__InvalidBandsAmount();
    error Staking__ZeroAddress();
    error Staking__ZeroAmount();
}
