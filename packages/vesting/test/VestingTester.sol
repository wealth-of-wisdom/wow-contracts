// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {Test} from "forge-std/Test.sol";
import {MockToken} from "../contracts/mock/MockToken.sol";

// Helper for foundry tests of Superfluid related contracts
contract VestingTester is Test {
    /* ============ STATE VARIABLES ============ */
    uint256 internal constant INIT_ETH_BALANCE = type(uint128).max;
    uint256 internal constant INIT_SUPER_TOKEN_BALANCE = type(uint128).max;

    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant ZERO_ADDRESS = address(0x0);

    address internal constant gelato = address(0x101);
    address internal constant treasury = address(0x102);

    address internal constant admin = address(0x420);
    address internal constant alice = address(0x421);
    address internal constant bob = address(0x422);
    address internal constant carol = address(0x423);
    address internal constant dan = address(0x424);

    address[] internal TEST_ACCOUNTS = [admin, alice, bob, carol, dan];
    uint256 internal immutable N_TESTERS;
    MockToken internal token;

    function setUp() public virtual {
        token = new MockToken();
        token.initialize("MOCK", "MCK", 1000);

        for (uint256 i = 0; i < N_TESTERS; ++i) {
            deal(TEST_ACCOUNTS[i], INIT_ETH_BALANCE);
            token.mint(TEST_ACCOUNTS[i], INIT_SUPER_TOKEN_BALANCE);
        }
    }
}
