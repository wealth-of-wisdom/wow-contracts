// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IStaking} from "../../contracts/interfaces/IStaking.sol";

abstract contract StakingConstants {
    /*//////////////////////////////////////////////////////////////////////////
                                    ADDRESSES
    //////////////////////////////////////////////////////////////////////////*/

    address internal constant ZERO_ADDRESS = address(0x0);
    address internal constant GELATO_EXECUTOR_ADDRESS = address(0x129);

    /*//////////////////////////////////////////////////////////////////////////
                                    ROLES
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 internal constant VESTING_ROLE = keccak256("VESTING_ROLE");
    bytes32 internal constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 internal constant GELATO_EXECUTOR_ROLE =
        keccak256("GELATO_EXECUTOR_ROLE");

    /*//////////////////////////////////////////////////////////////////////////
                                    DECIMALS
    //////////////////////////////////////////////////////////////////////////*/

    uint8 internal constant USD_DECIMALS = 6;
    uint8 internal constant WOW_DECIMALS = 18;
    uint128 internal constant USD_DECIMALS_FOR_MULTIPLICATION =
        uint128(10 ** USD_DECIMALS);
    uint128 internal constant WOW_DECIMALS_FOR_MULTIPLICATION =
        uint128(10 ** WOW_DECIMALS);

    /*//////////////////////////////////////////////////////////////////////////
                                    AMOUNTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant INIT_ETH_BALANCE = type(uint128).max;
    uint256 internal constant INIT_TOKEN_BALANCE = type(uint128).max;
    uint256 internal constant INIT_TOKEN_SUPPLY = 100_000 ether;

    uint256 internal constant DISTRIBUTION_AMOUNT =
        1_000_000 * USD_DECIMALS_FOR_MULTIPLICATION;

    uint256 internal constant ALICE_REWARDS = DISTRIBUTION_AMOUNT / 10; // 10%
    uint256 internal constant BOB_REWARDS = (DISTRIBUTION_AMOUNT * 15) / 100; // 15%
    uint256 internal constant CAROL_REWARDS = DISTRIBUTION_AMOUNT / 5; // 20%
    uint256 internal constant DAN_REWARDS = DISTRIBUTION_AMOUNT / 4; // 25%
    uint256 internal constant EVE_REWARDS = (DISTRIBUTION_AMOUNT * 3) / 10; // 30%
    uint256[] internal DISTRIBUTION_REWARDS = [
        ALICE_REWARDS,
        BOB_REWARDS,
        CAROL_REWARDS,
        DAN_REWARDS,
        EVE_REWARDS
    ];

    /*//////////////////////////////////////////////////////////////////////////
                                    TESTING VARS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant ALICE_REWARDS_2 =
        ((DISTRIBUTION_AMOUNT * 13) /
            1000 +
            (DISTRIBUTION_AMOUNT * 17) /
            1000) / 2;
    uint256 internal constant BOB_REWARDS_2 =
        ((DISTRIBUTION_AMOUNT * 13) /
            1000 +
            (DISTRIBUTION_AMOUNT * 17) /
            1000) /
            2 +
            (DISTRIBUTION_AMOUNT * 34) /
            1000 +
            (DISTRIBUTION_AMOUNT * 64) /
            1000;

    uint256 internal constant BOB_REWARDS_3 =
        ((DISTRIBUTION_AMOUNT * 13) / 1000) / 3;
    uint256 internal constant CAROL_REWARDS_3 =
        ((DISTRIBUTION_AMOUNT * 13) / 1000) /
            3 +
            ((DISTRIBUTION_AMOUNT * 17) / 1000) /
            2 +
            (DISTRIBUTION_AMOUNT * 34) /
            1000;

    uint256[] STAKER_BAND_IDS = [0];
    uint256[] EMPTY_STAKER_BAND_IDS;
    uint256[] MINIMAL_REWARDS_2 = [ALICE_REWARDS_2, BOB_REWARDS_2];
    uint256[] MINIMAL_REWARDS_3 = [
        ALICE_REWARDS_2,
        BOB_REWARDS_3,
        CAROL_REWARDS_3
    ];
    uint256[] ALICE_BAND_IDS = [BAND_ID_0];
    uint256[] BOB_BAND_IDS = [BAND_ID_1];
    uint256[] CAROL_BAND_IDS = [BAND_ID_2];

    /*//////////////////////////////////////////////////////////////////////////
                                    ENUMS
    //////////////////////////////////////////////////////////////////////////*/

    IStaking.StakingTypes internal constant STAKING_TYPE_FIX =
        IStaking.StakingTypes.FIX;
    IStaking.StakingTypes internal constant STAKING_TYPE_FLEXI =
        IStaking.StakingTypes.FLEXI;

    /*//////////////////////////////////////////////////////////////////////////
                                STAKING DATA
    //////////////////////////////////////////////////////////////////////////*/

    uint16 internal constant TOTAL_POOLS = 9;
    uint16 internal constant TOTAL_BAND_LEVELS = 9;
    uint48 internal constant PERCENTAGE_PRECISION = 1e8;

    uint48 internal constant MONTH = 30 days;
    uint8 internal constant MONTH_0 = 0;
    uint8 internal constant MONTH_1 = 1;
    uint8 internal constant MONTH_12 = 12;
    uint8 internal constant MONTH_24 = 24;
    uint8 internal constant MONTH_25 = 25;

    uint48 internal constant SHARE = 1e6;
    uint48[] internal SHARES_IN_MONTH = [
        SHARE,
        SHARE * 2,
        (SHARE * 25) / 10,
        SHARE * 3,
        (SHARE * 35) / 10,
        SHARE * 4,
        (SHARE * 45) / 10,
        SHARE * 5,
        (SHARE * 55) / 10,
        SHARE * 6,
        (SHARE * 6125) / 1000,
        (SHARE * 825) / 100,
        (SHARE * 8375) / 1000,
        (SHARE * 85) / 10,
        (SHARE * 8625) / 1000,
        (SHARE * 875) / 100,
        (SHARE * 8875) / 1000,
        SHARE * 9,
        (SHARE * 9125) / 1000,
        (SHARE * 925) / 100,
        (SHARE * 9375) / 1000,
        (SHARE * 95) / 10,
        (SHARE * 9625) / 1000,
        SHARE * 12
    ];

    /*//////////////////////////////////////////////////////////////////////////
                                STAKING POOL DATA
    //////////////////////////////////////////////////////////////////////////*/

    uint16 internal constant POOL_ID_1 = 1;
    uint16 internal constant POOL_ID_2 = 2;
    uint16 internal constant POOL_ID_3 = 3;
    uint16 internal constant POOL_ID_4 = 4;
    uint16 internal constant POOL_ID_5 = 5;
    uint16 internal constant POOL_ID_6 = 6;
    uint16 internal constant POOL_ID_7 = 7;
    uint16 internal constant POOL_ID_8 = 8;
    uint16 internal constant POOL_ID_9 = 9;

    uint16[] internal POOL_IDS = [
        POOL_ID_1,
        POOL_ID_2,
        POOL_ID_3,
        POOL_ID_4,
        POOL_ID_5,
        POOL_ID_6,
        POOL_ID_7,
        POOL_ID_8,
        POOL_ID_9
    ];

    uint48 internal constant POOL_1_PERCENTAGE =
        (13 * PERCENTAGE_PRECISION) / 1000; // 1.3%
    uint48 internal constant POOL_2_PERCENTAGE =
        (17 * PERCENTAGE_PRECISION) / 1000; // 1.7%
    uint48 internal constant POOL_3_PERCENTAGE =
        (34 * PERCENTAGE_PRECISION) / 1000; // 3.4%
    uint48 internal constant POOL_4_PERCENTAGE =
        (64 * PERCENTAGE_PRECISION) / 1000; // 6.4%
    uint48 internal constant POOL_5_PERCENTAGE =
        (156 * PERCENTAGE_PRECISION) / 1000; // 15.6%
    uint48 internal constant POOL_6_PERCENTAGE =
        (146 * PERCENTAGE_PRECISION) / 1000; // 14.6%
    uint48 internal constant POOL_7_PERCENTAGE =
        (24 * PERCENTAGE_PRECISION) / 100; // 24%
    uint48 internal constant POOL_8_PERCENTAGE =
        (19 * PERCENTAGE_PRECISION) / 100; // 19%
    uint48 internal constant POOL_9_PERCENTAGE =
        (14 * PERCENTAGE_PRECISION) / 100; // 14%

    uint48[] internal POOL_PERCENTAGES = [
        POOL_1_PERCENTAGE,
        POOL_2_PERCENTAGE,
        POOL_3_PERCENTAGE,
        POOL_4_PERCENTAGE,
        POOL_5_PERCENTAGE,
        POOL_6_PERCENTAGE,
        POOL_7_PERCENTAGE,
        POOL_8_PERCENTAGE,
        POOL_9_PERCENTAGE
    ];

    /*//////////////////////////////////////////////////////////////////////////
                              STAKING BAND LEVEL DATA
    //////////////////////////////////////////////////////////////////////////*/

    uint16 internal constant TOTAL_4_BAND_LEVELS = 4;

    uint16 internal constant BAND_LEVEL_1 = 1;
    uint16 internal constant BAND_LEVEL_2 = 2;
    uint16 internal constant BAND_LEVEL_3 = 3;
    uint16 internal constant BAND_LEVEL_4 = 4;
    uint16 internal constant BAND_LEVEL_5 = 5;
    uint16 internal constant BAND_LEVEL_6 = 6;
    uint16 internal constant BAND_LEVEL_7 = 7;
    uint16 internal constant BAND_LEVEL_8 = 8;
    uint16 internal constant BAND_LEVEL_9 = 9;

    uint16[] internal BAND_LEVELS = [
        BAND_LEVEL_1,
        BAND_LEVEL_2,
        BAND_LEVEL_3,
        BAND_LEVEL_4,
        BAND_LEVEL_5,
        BAND_LEVEL_6,
        BAND_LEVEL_7,
        BAND_LEVEL_8,
        BAND_LEVEL_9
    ];

    uint256 internal constant BAND_1_PRICE =
        1_000 * WOW_DECIMALS_FOR_MULTIPLICATION;
    uint256 internal constant BAND_2_PRICE =
        3_000 * WOW_DECIMALS_FOR_MULTIPLICATION;
    uint256 internal constant BAND_3_PRICE =
        10_000 * WOW_DECIMALS_FOR_MULTIPLICATION;
    uint256 internal constant BAND_4_PRICE =
        30_000 * WOW_DECIMALS_FOR_MULTIPLICATION;
    uint256 internal constant BAND_5_PRICE =
        100_000 * WOW_DECIMALS_FOR_MULTIPLICATION;
    uint256 internal constant BAND_6_PRICE =
        200_000 * WOW_DECIMALS_FOR_MULTIPLICATION;
    uint256 internal constant BAND_7_PRICE =
        500_000 * WOW_DECIMALS_FOR_MULTIPLICATION;
    uint256 internal constant BAND_8_PRICE =
        1_000_000 * WOW_DECIMALS_FOR_MULTIPLICATION;
    uint256 internal constant BAND_9_PRICE =
        2_000_000 * WOW_DECIMALS_FOR_MULTIPLICATION;

    uint256[] internal BAND_PRICES = [
        BAND_1_PRICE,
        BAND_2_PRICE,
        BAND_3_PRICE,
        BAND_4_PRICE,
        BAND_5_PRICE,
        BAND_6_PRICE,
        BAND_7_PRICE,
        BAND_8_PRICE,
        BAND_9_PRICE
    ];

    uint16[] internal BAND_1_ACCESSIBLE_POOLS = [1];
    uint16[] internal BAND_2_ACCESSIBLE_POOLS = [1, 2];
    uint16[] internal BAND_3_ACCESSIBLE_POOLS = [1, 2, 3];
    uint16[] internal BAND_4_ACCESSIBLE_POOLS = [1, 2, 3, 4];
    uint16[] internal BAND_5_ACCESSIBLE_POOLS = [1, 2, 3, 4, 5];
    uint16[] internal BAND_6_ACCESSIBLE_POOLS = [1, 2, 3, 4, 5, 6];
    uint16[] internal BAND_7_ACCESSIBLE_POOLS = [1, 2, 3, 4, 5, 6, 7];
    uint16[] internal BAND_8_ACCESSIBLE_POOLS = [1, 2, 3, 4, 5, 6, 7, 8];
    uint16[] internal BAND_9_ACCESSIBLE_POOLS = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    uint16[][] internal BAND_ACCESSIBLE_POOLS = [
        BAND_1_ACCESSIBLE_POOLS,
        BAND_2_ACCESSIBLE_POOLS,
        BAND_3_ACCESSIBLE_POOLS,
        BAND_4_ACCESSIBLE_POOLS,
        BAND_5_ACCESSIBLE_POOLS,
        BAND_6_ACCESSIBLE_POOLS,
        BAND_7_ACCESSIBLE_POOLS,
        BAND_8_ACCESSIBLE_POOLS,
        BAND_9_ACCESSIBLE_POOLS
    ];

    /*//////////////////////////////////////////////////////////////////////////
                              STAKING BAND DATA
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant BAND_ID_0 = 0;
    uint256 internal constant BAND_ID_1 = 1;
    uint256 internal constant BAND_ID_2 = 2;
    uint256 internal constant BAND_ID_3 = 3;
    uint256 internal constant BAND_ID_4 = 4;
}
