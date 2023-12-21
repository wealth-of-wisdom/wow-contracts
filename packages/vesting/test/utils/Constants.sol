// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

abstract contract Constants {
    uint256 internal constant INIT_ETH_BALANCE = type(uint128).max;
    uint256 internal constant INIT_SUPER_TOKEN_BALANCE = type(uint128).max;

    uint16 internal constant PRIMARY_POOL = 0;
    string internal constant POOL_NAME = "Test1";
    uint16 internal constant LISTING_PERCENTAGE_DIVIDEND = 1;
    uint16 internal constant LISTING_PERCENTAGE_DIVISOR = 20;
    uint16 internal constant CLIFF_IN_DAYS = 1;
    uint16 internal constant CLIFF_PERCENTAGE_DIVIDEND = 1;
    uint16 internal constant CLIFF_PERCENTAGE_DIVISOR = 10;
    uint16 internal constant VESTING_DURATION_IN_MONTHS = 3;
    uint256 internal constant TOTAL_POOL_TOKEN_AMONUT = 1 * 10 ** 22;
    uint256 internal constant BENEFICIARY_DEFAULT_TOKEN_AMOUNT = 200;
}
