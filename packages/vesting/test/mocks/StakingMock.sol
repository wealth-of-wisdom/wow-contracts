// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IStaking} from "@wealth-of-wisdom/staking/contracts/interfaces/IStaking.sol";

contract StakingMock is IStaking {
    bool public wasUnstakesVestedTokensCalled;

    /*//////////////////////////////////////////////////////////////////////////
                                        FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function unstakeVestedTokens(
        address /*beneficiary*/,
        uint256 /*stakedAmount*/
    ) external {
        wasUnstakesVestedTokensCalled = true;
    }
}
