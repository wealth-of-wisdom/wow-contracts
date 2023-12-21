// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library Errors {
    error Vesting__ArraySizeMismatch();
    error Vesting__CanNotWithdrawVestedTokens();
    error Vesting__ListingDateCanOnlyBeSetInFuture();
    error Vesting__ListingAndCliffPercentageOverflow();
    error Vesting__NotEnoughVestedTokensForStaking();
    error Vesting__NotInBeneficiaryList();
    error Vesting__NoClaimableTokens();
    error Vesting__NotEnoughTokenBalance();
    error Vesting__PercentageDivisorZero();
    error Vesting__PoolDoesNotExist();
    error Vesting__PoolWithThisNameExists();
    error Vesting__StakedTokensCanNotBeClaimed();
    error Vesting__TokenAmountExeedsTotalPoolAmount();
    error Vesting__TokenAmountZero();
    error Vesting__VestingDurationZero();
    error Vesting__ZeroAddress();
    error Vesting__EmptyName();
}
