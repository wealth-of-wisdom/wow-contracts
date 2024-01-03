// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IStakingEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/
}

interface IStaking is IStakingEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Stops staking of vested tokens for a beneficiary in a pool
     * @notice Beneficiary needs to claim staking rewards with an external call
     * @notice This function can only be called by the vesting contract
     * @param beneficiary Address of the beneficiary
     * @param stakedAmount Amount of tokens to unstake
     */
    function unstakeVestedTokens(
        address beneficiary,
        uint256 stakedAmount
    ) external;
}
