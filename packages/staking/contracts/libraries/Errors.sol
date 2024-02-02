// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                    STAKING
    //////////////////////////////////////////////////////////////////////////*/

    error Staking__InvalidBandId(uint16 bandId);
    error Staking__MaximumLevelExceeded();
    error Staking__InvalidStaingTimespan(uint256 stakingTimespan);
    error Staking__InvalidPoolId(uint16 poolId);
    error Staking__InsufficientContractBalance(
        uint256 contractBalance,
        uint256 requiredAmount
    );
    error Staking__InvalidDistributionPercentage(uint24 percentage);
    error Staking__BandAllocationExceedsMaximum(uint24 percentage);
    error Staking__TotalAllocationExceedsMaximum(uint24 percentage);
    error Staking__InvalidBandsAmount();
    error Staking__ZeroAmount();
    error Staking__ZeroAddress();
}
