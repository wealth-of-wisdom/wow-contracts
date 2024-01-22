// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
import {INft} from "../../contracts/interfaces/INft.sol";

abstract contract Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                    ADDRESSES
    //////////////////////////////////////////////////////////////////////////*/

    address internal constant ZERO_ADDRESS = address(0x0);

    /*//////////////////////////////////////////////////////////////////////////
                                    ROLES
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant NFT_DATA_MANAGER_ROLE =
        keccak256("NFT_DATA_MANAGER_ROLE");
    bytes32 internal constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant WHITELISTED_SENDER_ROLE =
        keccak256("WHITELISTED_SENDER_ROLE");
    bytes32 internal constant BENEFICIARIES_MANAGER_ROLE =
        keccak256("BENEFICIARIES_MANAGER_ROLE");

    /*//////////////////////////////////////////////////////////////////////////
                                    DECIMALS
    //////////////////////////////////////////////////////////////////////////*/

    uint64 internal constant USD_DECIMALS = 10 ** 6;
    uint256 internal constant WOW_DECIMALS = 10 ** 18;

    /*//////////////////////////////////////////////////////////////////////////
                                    AMOUNTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant INIT_ETH_BALANCE = type(uint128).max;
    uint256 internal constant INIT_TOKEN_BALANCE = type(uint128).max;
    uint256 internal constant INITIAL_TOKEN_AMOUNT = 100_000 ether;

    /*//////////////////////////////////////////////////////////////////////////
                                    NFT DATA
    //////////////////////////////////////////////////////////////////////////*/

    uint16 internal constant DEFAULT_GENESIS_AMOUNT = 5;
    uint256 internal constant NFT_TOKEN_ID_0 = 0;
    uint256 internal constant NFT_TOKEN_ID_1 = 1;
    uint256 internal constant NFT_TOKEN_ID_2 = 2;
    uint256 internal constant NFT_TOKEN_ID_3 = 3;
    uint256 internal constant NFT_TOKEN_ID_4 = 4;

    INft.ActivityType internal constant NFT_ACTIVITY_TYPE_ACTIVATION_TRIGGERED =
        INft.ActivityType.ACTIVATION_TRIGGERED;
    INft.ActivityType internal constant NFT_ACTIVITY_TYPE_NOT_ACTIVATED =
        INft.ActivityType.NOT_ACTIVATED;
    INft.ActivityType internal constant NFT_ACTIVITY_TYPE_DEACTIVATED =
        INft.ActivityType.DEACTIVATED;

    /*//////////////////////////////////////////////////////////////////////////
                                PROJECTS DATA
    //////////////////////////////////////////////////////////////////////////*/

    uint8 internal constant PROJECT_TYPE_STANDARD = 0;
    uint8 internal constant PROJECT_TYPE_PREMIUM = 1;
    uint8 internal constant PROJECT_TYPE_LIMITED = 2;

    /*//////////////////////////////////////////////////////////////////////////
                                VESTING DATA
    //////////////////////////////////////////////////////////////////////////*/

    uint16 internal constant DEFAULT_VESTING_PID = 0;
    string internal constant POOL_NAME = "Test Pool";
    uint16 internal constant LISTING_PERCENTAGE_DIVIDEND = 1;
    uint16 internal constant LISTING_PERCENTAGE_DIVISOR = 20;
    uint16 internal constant CLIFF_IN_DAYS = 1;
    uint16 internal constant CLIFF_PERCENTAGE_DIVIDEND = 1;
    uint16 internal constant CLIFF_PERCENTAGE_DIVISOR = 10;
    uint16 internal constant VESTING_DURATION_IN_MONTHS = 3;
    IVesting.UnlockTypes internal constant VESTING_UNLOCK_TYPE =
        IVesting.UnlockTypes.MONTHLY;
    uint256 internal constant TOTAL_POOL_TOKEN_AMOUNT = 100_000 ether;

    /*//////////////////////////////////////////////////////////////////////////
                                NFT LEVELS DATA
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant LEVEL_5_SUPPLY_CAP = 20;
    uint256 internal constant MONTH = 30 days;
    uint16 internal constant MAX_LEVEL = 5;
    uint8 internal constant TOTAL_PROJECT_TYPES = 3;
    string internal constant NFT_URI_SUFFIX = ".json";

    uint16 internal constant LEVEL_1 = 1;
    uint16 internal constant LEVEL_2 = 2;
    uint16 internal constant LEVEL_3 = 3;
    uint16 internal constant LEVEL_4 = 4;
    uint16 internal constant LEVEL_5 = 5;

    uint256 internal constant LEVEL_1_PRICE = 1_000 * USD_DECIMALS;
    uint256 internal constant LEVEL_2_PRICE = 5_000 * USD_DECIMALS;
    uint256 internal constant LEVEL_3_PRICE = 10_000 * USD_DECIMALS;
    uint256 internal constant LEVEL_4_PRICE = 33_000 * USD_DECIMALS;
    uint256 internal constant LEVEL_5_PRICE = 100_000 * USD_DECIMALS;

    uint256 internal constant LEVEL_1_VESTING_REWARD = 1_000 * WOW_DECIMALS;
    uint256 internal constant LEVEL_2_VESTING_REWARD = 25_000 * WOW_DECIMALS;
    uint256 internal constant LEVEL_3_VESTING_REWARD = 100_000 * WOW_DECIMALS;
    uint256 internal constant LEVEL_4_VESTING_REWARD = 660_000 * WOW_DECIMALS;
    uint256 internal constant LEVEL_5_VESTING_REWARD = 3_000_000 * WOW_DECIMALS;

    uint256 internal constant LEVEL_1_LIFECYCLE_DURATION = 12 * MONTH;
    uint256 internal constant LEVEL_2_LIFECYCLE_DURATION = 15 * MONTH;
    uint256 internal constant LEVEL_3_LIFECYCLE_DURATION = 24 * MONTH;
    uint256 internal constant LEVEL_4_LIFECYCLE_DURATION = 40 * MONTH;
    uint256 internal constant LEVEL_5_LIFECYCLE_DURATION = type(uint256).max;

    uint256 internal constant LEVEL_1_EXTENSION_DURATION = 0;
    uint256 internal constant LEVEL_2_EXTENSION_DURATION = 15 * MONTH;
    uint256 internal constant LEVEL_3_EXTENSION_DURATION = 18 * MONTH;
    uint256 internal constant LEVEL_4_EXTENSION_DURATION = type(uint256).max;
    uint256 internal constant LEVEL_5_EXTENSION_DURATION = type(uint256).max;

    uint256 internal constant LEVEL_1_ALLOCATION_PER_PROJECT =
        1_000 * USD_DECIMALS;
    uint256 internal constant LEVEL_2_ALLOCATION_PER_PROJECT =
        5_000 * USD_DECIMALS;
    uint256 internal constant LEVEL_3_ALLOCATION_PER_PROJECT =
        25_000 * USD_DECIMALS;
    uint256 internal constant LEVEL_4_ALLOCATION_PER_PROJECT =
        100_000 * USD_DECIMALS;
    uint256 internal constant LEVEL_5_ALLOCATION_PER_PROJECT =
        500_000 * USD_DECIMALS;

    string internal constant LEVEL_1_BASE_URI = "ipfs://level1BaseUri/";
    string internal constant LEVEL_2_BASE_URI = "ipfs://level2BaseUri/";
    string internal constant LEVEL_3_BASE_URI = "ipfs://level3BaseUri/";
    string internal constant LEVEL_4_BASE_URI = "ipfs://level4BaseUri/";
    string internal constant LEVEL_5_BASE_URI = "ipfs://level5BaseUri/";
    string internal constant LEVEL_1_GENESIS_BASE_URI =
        "ipfs://level1GenesisUri/";
    string internal constant LEVEL_2_GENESIS_BASE_URI =
        "ipfs://level2GenesisUri/";
    string internal constant LEVEL_3_GENESIS_BASE_URI =
        "ipfs://level3GenesisUri/";
    string internal constant LEVEL_4_GENESIS_BASE_URI =
        "ipfs://level4GenesisUri/";
    string internal constant LEVEL_5_GENESIS_BASE_URI =
        "ipfs://level5GenesisUri/";
}
