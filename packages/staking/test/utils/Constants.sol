// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IStaking} from "../../contracts/interfaces/IStaking.sol";

abstract contract Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                    ADDRESSES
    //////////////////////////////////////////////////////////////////////////*/

    address internal constant ZERO_ADDRESS = address(0x0);

    /*//////////////////////////////////////////////////////////////////////////
                                    ROLES
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 internal constant DEFAULT_VESTING_ROLE = keccak256("VESTING_ROLE");
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /*//////////////////////////////////////////////////////////////////////////
                                    DECIMALS
    //////////////////////////////////////////////////////////////////////////*/

    uint8 internal constant USD_DECIMALS = 6;
    uint8 internal constant WOW_DECIMALS = 18;
    uint128 internal constant WOW_DECIMALS_FOR_MULTIPLICATION = 1e18;

    /*//////////////////////////////////////////////////////////////////////////
                                    AMOUNTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant INIT_ETH_BALANCE = type(uint128).max;
    uint256 internal constant INIT_TOKEN_BALANCE = type(uint128).max;
    uint256 internal constant INIT_TOKEN_SUPPLY = 100_000 ether;
    uint256 internal constant DEFAULT_DISTRIBUTION_AMOUNT = 1_000_000 * 1e6;
    uint16 internal constant NEW_TOTAL_BAND_LEVELS = 4;

    /*//////////////////////////////////////////////////////////////////////////
                                    TESTING VARS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 FIRST_STAKED_BAND_ID = 0;

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
    uint48 internal constant SHARE = 1e6;
    uint48 internal constant MONTH = 30 days;
    uint48[] internal SHARES_IN_MONTH = [
        SHARE,
        SHARE * 2,
        SHARE * 3,
        SHARE * 4,
        SHARE * 5,
        SHARE * 6,
        SHARE * 7,
        SHARE * 8,
        SHARE * 9,
        SHARE * 10,
        SHARE * 11,
        SHARE * 12,
        SHARE * 13,
        SHARE * 14,
        SHARE * 15,
        SHARE * 16,
        SHARE * 17,
        SHARE * 18,
        SHARE * 19,
        SHARE * 20,
        SHARE * 21,
        SHARE * 22,
        SHARE * 23,
        SHARE * 24
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

    /*//////////////////////////////////////////////////////////////////////////
                                STAKING BAND DATA
    //////////////////////////////////////////////////////////////////////////*/

    uint16 internal constant BAND_ID_1 = 1;
    uint16 internal constant BAND_ID_2 = 2;
    uint16 internal constant BAND_ID_3 = 3;
    uint16 internal constant BAND_ID_4 = 4;
    uint16 internal constant BAND_ID_5 = 5;
    uint16 internal constant BAND_ID_6 = 6;
    uint16 internal constant BAND_ID_7 = 7;
    uint16 internal constant BAND_ID_8 = 8;
    uint16 internal constant BAND_ID_9 = 9;

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

    uint16[] internal BAND_1_ACCESSIBLE_POOLS = [1];
    uint16[] internal BAND_2_ACCESSIBLE_POOLS = [1, 2];
    uint16[] internal BAND_3_ACCESSIBLE_POOLS = [1, 2, 3];
    uint16[] internal BAND_4_ACCESSIBLE_POOLS = [1, 2, 3, 4];
    uint16[] internal BAND_5_ACCESSIBLE_POOLS = [1, 2, 3, 4, 5];
    uint16[] internal BAND_6_ACCESSIBLE_POOLS = [1, 2, 3, 4, 5, 6];
    uint16[] internal BAND_7_ACCESSIBLE_POOLS = [1, 2, 3, 4, 5, 6, 7];
    uint16[] internal BAND_8_ACCESSIBLE_POOLS = [1, 2, 3, 4, 5, 6, 7, 8];
    uint16[] internal BAND_9_ACCESSIBLE_POOLS = [1, 2, 3, 4, 5, 6, 7, 8, 9];
}
