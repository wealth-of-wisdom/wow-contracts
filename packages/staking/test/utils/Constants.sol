// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

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
    bytes32 internal constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /*//////////////////////////////////////////////////////////////////////////
                                    DECIMALS
    //////////////////////////////////////////////////////////////////////////*/

    uint8 internal constant USD_DECIMALS = 6;
    uint8 internal constant WOW_DECIMALS = 18;

    /*//////////////////////////////////////////////////////////////////////////
                                    AMOUNTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant INIT_ETH_BALANCE = type(uint128).max;
    uint256 internal constant INIT_TOKEN_BALANCE = type(uint128).max;
    uint256 internal constant INIT_TOKEN_SUPPLY = 100_000 ether;

    /*//////////////////////////////////////////////////////////////////////////
                                STAKING DATA
    //////////////////////////////////////////////////////////////////////////*/

    uint16 internal constant TOTAL_POOLS = 9;
    uint16 internal constant TOTAL_BANDS = 9;
    uint48 internal constant PERCENTAGE_PRECISION = 10 ** 6; // 100% = 10**6
    uint128 internal constant MONTH = 30 days;

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

    uint48 internal constant POOL_1_PERCENTAGE =
        (13 * PERCENTAGE_PRECISION) / 100; // 1.3%
    uint48 internal constant POOL_2_PERCENTAGE =
        (17 * PERCENTAGE_PRECISION) / 100; // 1.7%
    uint48 internal constant POOL_3_PERCENTAGE =
        (34 * PERCENTAGE_PRECISION) / 100; // 3.4%
    uint48 internal constant POOL_4_PERCENTAGE =
        (64 * PERCENTAGE_PRECISION) / 100; // 6.4%
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

    uint48[] internal POOL_1_BAND_ALLOCATION_PERCENTAGE = [
        (16 * PERCENTAGE_PRECISION) / 100, // 16%
        (14 * PERCENTAGE_PRECISION) / 100, // 14%
        (13 * PERCENTAGE_PRECISION) / 100, // 13%
        (12 * PERCENTAGE_PRECISION) / 100, // 12%
        (11 * PERCENTAGE_PRECISION) / 100, // 11%
        (10 * PERCENTAGE_PRECISION) / 100, // 10%
        (9 * PERCENTAGE_PRECISION) / 100, // 9%
        (8 * PERCENTAGE_PRECISION) / 100, // 8%
        (7 * PERCENTAGE_PRECISION) / 100 // 7%
    ];
    uint48[] internal POOL_2_BAND_ALLOCATION_PERCENTAGE = [
        (23 * PERCENTAGE_PRECISION) / 100, // 23%
        (14 * PERCENTAGE_PRECISION) / 100, // 14%
        (13 * PERCENTAGE_PRECISION) / 100, // 13%
        (12 * PERCENTAGE_PRECISION) / 100, // 12%
        (11 * PERCENTAGE_PRECISION) / 100, // 11%
        (10 * PERCENTAGE_PRECISION) / 100, // 10%
        (9 * PERCENTAGE_PRECISION) / 100, // 9%
        (8 * PERCENTAGE_PRECISION) / 100 // 8%
    ];

    uint48[] internal POOL_3_BAND_ALLOCATION_PERCENTAGE = [
        (31 * PERCENTAGE_PRECISION) / 100, // 31%
        (14 * PERCENTAGE_PRECISION) / 100, // 14%
        (13 * PERCENTAGE_PRECISION) / 100, // 13%
        (12 * PERCENTAGE_PRECISION) / 100, // 12%
        (11 * PERCENTAGE_PRECISION) / 100, // 11%
        (10 * PERCENTAGE_PRECISION) / 100, // 10%
        (9 * PERCENTAGE_PRECISION) / 100 // 9%
    ];

    uint48[] internal POOL_4_BAND_ALLOCATION_PERCENTAGE = [
        (40 * PERCENTAGE_PRECISION) / 100, // 40%
        (14 * PERCENTAGE_PRECISION) / 100, // 14%
        (13 * PERCENTAGE_PRECISION) / 100, // 13%
        (12 * PERCENTAGE_PRECISION) / 100, // 12%
        (11 * PERCENTAGE_PRECISION) / 100, // 11%
        (10 * PERCENTAGE_PRECISION) / 100 // 10%
    ];

    uint48[] internal POOL_5_BAND_ALLOCATION_PERCENTAGE = [
        (50 * PERCENTAGE_PRECISION) / 100, // 50%
        (14 * PERCENTAGE_PRECISION) / 100, // 14%
        (13 * PERCENTAGE_PRECISION) / 100, // 13%
        (12 * PERCENTAGE_PRECISION) / 100, // 12%
        (11 * PERCENTAGE_PRECISION) / 100 // 11%
    ];

    uint48[] internal POOL_6_BAND_ALLOCATION_PERCENTAGE = [
        (61 * PERCENTAGE_PRECISION) / 100, // 61%
        (14 * PERCENTAGE_PRECISION) / 100, // 14%
        (13 * PERCENTAGE_PRECISION) / 100, // 13%
        (12 * PERCENTAGE_PRECISION) / 100 // 12%
    ];

    uint48[] internal POOL_7_BAND_ALLOCATION_PERCENTAGE = [
        (73 * PERCENTAGE_PRECISION) / 100, // 73%
        (14 * PERCENTAGE_PRECISION) / 100, // 14%
        (13 * PERCENTAGE_PRECISION) / 100 // 13%
    ];

    uint48[] internal POOL_8_BAND_ALLOCATION_PERCENTAGE = [
        (86 * PERCENTAGE_PRECISION) / 100, // 86%
        (14 * PERCENTAGE_PRECISION) / 100 // 14%
    ];

    uint48[] internal POOL_9_BAND_ALLOCATION_PERCENTAGE = [
        PERCENTAGE_PRECISION
    ]; // 100%

    /*//////////////////////////////////////////////////////////////////////////
                                STAKING BAND DATA
    //////////////////////////////////////////////////////////////////////////*/

    uint16 internal constant BAND_ID_1 = 1;
    uint16 internal constant constantBAND_ID_2 = 2;
    uint16 internal constant BAND_ID_3 = 3;
    uint16 internal constant BAND_ID_4 = 4;
    uint16 internal constant BAND_ID_5 = 5;
    uint16 internal constant BAND_ID_6 = 6;
    uint16 internal constant BAND_ID_7 = 7;
    uint16 internal constant BAND_ID_8 = 8;
    uint16 internal constant BAND_ID_9 = 9;

    uint256 internal constant BAND_1_PRICE = 1_000 * WOW_DECIMALS;
    uint256 internal constant BAND_2_PRICE = 3_000 * WOW_DECIMALS;
    uint256 internal constant BAND_3_PRICE = 10_000 * WOW_DECIMALS;
    uint256 internal constant BAND_4_PRICE = 30_000 * WOW_DECIMALS;
    uint256 internal constant BAND_5_PRICE = 100_000 * WOW_DECIMALS;
    uint256 internal constant BAND_6_PRICE = 200_000 * WOW_DECIMALS;
    uint256 internal constant BAND_7_PRICE = 500_000 * WOW_DECIMALS;
    uint256 internal constant BAND_8_PRICE = 1_000_000 * WOW_DECIMALS;
    uint256 internal constant BAND_9_PRICE = 2_000_000 * WOW_DECIMALS;

    uint16[] internal BAND_1_ACCESSIBLE_POOLS = [1];
    uint16[] internal BAND_2_ACCESSIBLE_POOLS = [1, 2];
    uint16[] internal BAND_3_ACCESSIBLE_POOLS = [1, 2, 3];
    uint16[] internal BAND_4_ACCESSIBLE_POOLS = [1, 2, 3, 4];
    uint16[] internal BAND_5_ACCESSIBLE_POOLS = [1, 2, 3, 4, 5];
    uint16[] internal BAND_6_ACCESSIBLE_POOLS = [1, 2, 3, 4, 5, 6];
    uint16[] internal BAND_7_ACCESSIBLE_POOLS = [1, 2, 3, 4, 5, 6, 7];
    uint16[] internal BAND_8_ACCESSIBLE_POOLS = [1, 2, 3, 4, 5, 6, 7, 8];
    uint16[] internal BAND_9_ACCESSIBLE_POOLS = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    uint256 internal constant BAND_1_STAKING_TIMESPAN = 24 * MONTH;
    uint256 internal constant BAND_2_STAKING_TIMESPAN = 24 * MONTH;
    uint256 internal constant BAND_3_STAKING_TIMESPAN = 24 * MONTH;
    uint256 internal constant BAND_4_STAKING_TIMESPAN = 24 * MONTH;
    uint256 internal constant BAND_5_STAKING_TIMESPAN = 24 * MONTH;
    uint256 internal constant BAND_6_STAKING_TIMESPAN = 24 * MONTH;
    uint256 internal constant BAND_7_STAKING_TIMESPAN = 24 * MONTH;
    uint256 internal constant BAND_8_STAKING_TIMESPAN = 24 * MONTH;
    uint256 internal constant BAND_9_STAKING_TIMESPAN = 24 * MONTH;
}
