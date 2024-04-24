// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Unit_Test} from "../Unit.t.sol";

contract WOWToken_Nonces_Unit_Test is Unit_Test {
    function test_nonces_GetsCorrectNonces() external {
        vm.prank(admin);
        uint256 initialNonce = wowToken.nonces(admin);
        assertEq(initialNonce, 0, "Initial nonce does not lign up");

        vm.prank(admin);
        wowToken.useNonce(admin);
        uint256 PostNonce = wowToken.nonces(admin);

        assertEq(PostNonce, 1, "Post nonce use does not lign up");
    }
}
