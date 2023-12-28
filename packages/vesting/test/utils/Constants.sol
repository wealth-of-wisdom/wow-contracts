// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IVesting} from "../../contracts/interfaces/IVesting.sol";

abstract contract Constants {
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 internal constant STAKING_ROLE = keccak256("STAKING_ROLE");

    address internal constant ZERO_ADDRESS = address(0x0);
    uint256 internal constant INIT_ETH_BALANCE = type(uint128).max;
    uint256 internal constant INIT_TOKEN_BALANCE = type(uint128).max;

    uint16 internal constant PRIMARY_POOL = 0;
    uint16 internal constant SECONDARY_POOL = 1;
    string internal constant POOL_NAME = "Test1";
    string internal constant POOL_NAME_2 = "Test2";
    uint16 internal constant LISTING_PERCENTAGE_DIVIDEND = 1;
    uint16 internal constant LISTING_PERCENTAGE_DIVISOR = 20;
    uint16 internal constant CLIFF_IN_DAYS = 1;
    uint16 internal constant CLIFF_PERCENTAGE_DIVIDEND = 1;
    uint16 internal constant CLIFF_PERCENTAGE_DIVISOR = 10;
    uint16 internal constant VESTING_DURATION_IN_MONTHS = 3;
    IVesting.UnlockTypes internal constant VESTING_UNLOCK_TYPE =
        IVesting.UnlockTypes.MONTHLY;
    uint256 internal constant TOTAL_POOL_TOKEN_AMOUNT = 10_000 ether;
    uint256 internal constant BENEFICIARY_TOKEN_AMOUNT = 1 ether;
}
