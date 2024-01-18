// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {INft} from "@wealth-of-wisdom/nft/contracts/interfaces/INft.sol";
import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";

abstract contract Constants {
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant NFT_DATA_MANAGER = keccak256("NFT_DATA_MANAGER");
    bytes32 internal constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant WHITELISTED_SENDER_ROLE =
        keccak256("WHITELISTED_SENDER_ROLE");
    bytes32 internal constant BENEFICIARIES_MANAGER_ROLE =
        keccak256("BENEFICIARIES_MANAGER_ROLE");

    uint64 internal constant USD_DECIMALS = 10 ** 6;
    uint256 internal constant WOW_DECIMALS = 10 ** 18;

    address internal constant ZERO_ADDRESS = address(0x0);
    uint256 internal constant INIT_ETH_BALANCE = type(uint128).max;
    uint256 internal constant INIT_TOKEN_BALANCE = type(uint128).max;
    uint256 internal constant INITIAL_TOKEN_AMOUNT = 100_000 ether;

    uint256 internal constant GENESIS_TOKEN_DIVISOR = 1_000 * 10 ** 6;

    uint16 internal constant DEFAULT_GENESIS_AMOUNT = 5;
    uint256 internal constant NFT_TOKEN_ID_0 = 0;
    uint256 internal constant NFT_TOKEN_ID_1 = 1;
    uint256 internal constant NFT_TOKEN_ID_2 = 2;

    uint16 internal constant DEFAULT_VESTING_PID = 0;
    string internal constant POOL_NAME = "Test1";
    uint16 internal constant LISTING_PERCENTAGE_DIVIDEND = 1;
    uint16 internal constant LISTING_PERCENTAGE_DIVISOR = 20;
    uint16 internal constant CLIFF_IN_DAYS = 1;
    uint16 internal constant CLIFF_PERCENTAGE_DIVIDEND = 1;
    uint16 internal constant CLIFF_PERCENTAGE_DIVISOR = 10;
    uint16 internal constant VESTING_DURATION_IN_MONTHS = 3;
    IVesting.UnlockTypes internal constant VESTING_UNLOCK_TYPE =
        IVesting.UnlockTypes.MONTHLY;
    uint256 internal constant TOTAL_POOL_TOKEN_AMOUNT = 100_000 ether;

    INft.ActivityType internal constant NFT_ACTIVITY_TYPE_ACTIVATION_TRIGGERED =
        INft.ActivityType.ACTIVATION_TRIGGERED;
    INft.ActivityType internal constant NFT_ACTIVITY_TYPE_NOT_ACTIVATED =
        INft.ActivityType.NOT_ACTIVATED;
    INft.ActivityType internal constant NFT_ACTIVITY_TYPE_DEACTIVATED =
        INft.ActivityType.DEACTIVATED;

    uint16 internal constant MAXIMUM_LEVEL_AMOUNT = 5;
    uint256 internal constant SECONDS_IN_MONTH = 2592000;

    uint16 internal constant LEVEL_1 = 1;
    uint256 internal constant LEVEL_1_PRICE = 1_000 * USD_DECIMALS;
    uint256 internal constant LEVEL_1_VESTING_REWARD = 1_000 * WOW_DECIMALS;
    uint256 internal constant LEVEL_1_LIFECYCLE_TIMESTAMP =
        12 * SECONDS_IN_MONTH;
    uint256 internal constant LEVEL_1_EXTENDED_LIFECYCLE_TIMESTAMP =
        15 * SECONDS_IN_MONTH;
    uint256 internal constant LEVEL_1_ALLOCATION_PER_PROJECT =
        10 * USD_DECIMALS;

    uint16 internal constant LEVEL_2 = 2;
    uint256 internal constant LEVEL_2_PRICE = 5_000 * USD_DECIMALS;
    uint256 internal constant LEVEL_2_VESTING_REWARD = 5_000 * WOW_DECIMALS;
    uint256 internal constant LEVEL_2_LIFECYCLE_TIMESTAMP =
        15 * SECONDS_IN_MONTH;
    uint256 internal constant LEVEL_2_EXTENDED_LIFECYCLE_TIMESTAMP =
        18 * SECONDS_IN_MONTH;
    uint256 internal constant LEVEL_2_ALLOCATION_PER_PROJECT =
        15 * USD_DECIMALS;

    uint16 internal constant LEVEL_3 = 3;
    uint256 internal constant LEVEL_3_PRICE = 10_000 * USD_DECIMALS;
    uint256 internal constant LEVEL_3_VESTING_REWARD = 10_000 * WOW_DECIMALS;
    uint256 internal constant LEVEL_3_LIFECYCLE_TIMESTAMP =
        24 * SECONDS_IN_MONTH;
    uint256 internal constant LEVEL_3_EXTENDED_LIFECYCLE_TIMESTAMP =
        20 * SECONDS_IN_MONTH;
    uint256 internal constant LEVEL_3_ALLOCATION_PER_PROJECT =
        20 * USD_DECIMALS;

    uint16 internal constant LEVEL_4 = 0;
    uint256 internal constant LEVEL_4_PRICE = 50 * USD_DECIMALS;
    uint256 internal constant LEVEL_4_VESTING_REWARD = 50 * WOW_DECIMALS;
    uint256 internal constant LEVEL_4_LIFECYCLE_TIMESTAMP = type(uint256).max;
    uint256 internal constant LEVEL_4_EXTENDED_LIFECYCLE_TIMESTAMP =
        type(uint256).max;
    uint256 internal constant LEVEL_4_ALLOCATION_PER_PROJECT = 5 * USD_DECIMALS;
}
