// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Staking} from "@wealth-of-wisdom/staking/contracts/Staking.sol";

contract StakingMock is Staking {
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
