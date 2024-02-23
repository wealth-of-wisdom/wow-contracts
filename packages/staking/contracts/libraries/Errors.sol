// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                    STAKING
    //////////////////////////////////////////////////////////////////////////*/

    error Staking__InvalidBandLevel(uint16 bandLevel);
    error Staking__InvalidBandId(uint256 bandId);
    error Staking__CantModifyFixTypeBand();
    error Staking__NotBandOwner(uint256 bandId, address owner);
    error Staking__InvalidStakingType();
    error Staking__MaximumLevelExceeded();
    error Staking__NonExistantToken();
    error Staking__InvalidStakingTimespan(uint256 stakingTimespan);
    error Staking__InvalidPoolId(uint16 poolId);
    error Staking__InsufficientContractBalance(
        uint256 contractBalance,
        uint256 requiredAmount
    );
    error Staking__InvalidDistributionPercentage(uint48 percentage);
    error Staking__BandAllocationExceedsMaximum(uint48 percentage);
    error Staking__TotalAllocationExceedsMaximum(uint48 percentage);
    error Staking__InvalidBandsAmount();
    error Staking__ZeroAmount();
    error Staking__ZeroAddress();
    error Staking__ZeroPoolShares();
    error Staking__MismatchedArrayLengths(
        uint256 stakersLength,
        uint256 rewardsLength
    );
    error Staking__NoRewardsToClaim();
    error Staking__InvalidMonth(uint8 month);
    error Staking__DifferentVestingStatus();
    error Staking__UnlockDateNotReached();
}
