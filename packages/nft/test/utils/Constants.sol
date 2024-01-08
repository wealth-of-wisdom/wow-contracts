// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

abstract contract Constants {
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address internal constant ZERO_ADDRESS = address(0x0);
    uint256 internal constant INIT_ETH_BALANCE = type(uint128).max;
    uint256 internal constant INIT_TOKEN_BALANCE = type(uint128).max;

    uint16 internal constant DEFAULT_LEVEL = 1;
    uint256 internal constant TOTAL_TOKEN_AMOUNT = 100_000 ether;
    uint256 internal constant STARTER_TOKEN_ID = 1;
}