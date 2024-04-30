// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Staking} from "../../contracts/Staking.sol";

contract StakingMock is Staking {
    function mock_setBandFromVestedTokens(
        uint256 bandId,
        bool areTokensVested
    ) external {
        s_bands[bandId].areTokensVested = areTokensVested;
    }

    function mock_authorizeUpgrade(address newImplementation) external {
        _authorizeUpgrade(newImplementation);
    }
}
