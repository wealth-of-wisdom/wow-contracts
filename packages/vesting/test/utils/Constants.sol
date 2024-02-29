// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IStaking} from "@wealth-of-wisdom/staking/contracts/interfaces/IStaking.sol";
import {IVesting} from "../../contracts/interfaces/IVesting.sol";

abstract contract Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                    ADDRESSES
    //////////////////////////////////////////////////////////////////////////*/

    address internal constant ZERO_ADDRESS = address(0x0);

    /*//////////////////////////////////////////////////////////////////////////
                                    ROLES   
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 internal constant BENEFICIARIES_MANAGER_ROLE =
        keccak256("BENEFICIARIES_MANAGER_ROLE");
    bytes32 internal constant VESTING_ROLE = keccak256("VESTING_ROLE");

    /*//////////////////////////////////////////////////////////////////////////
                                    DECIMALS
    //////////////////////////////////////////////////////////////////////////*/

    uint8 internal constant USD_DECIMALS = 6;
    uint8 internal constant WOW_DECIMALS = 18;
    uint128 internal constant WOW_DECIMALS_FOR_MULTIPLICATION =
        uint128(10 ** WOW_DECIMALS);
    uint48 internal constant PERCENTAGE_PRECISION = 1e8;

    /*//////////////////////////////////////////////////////////////////////////
                                    AMOUNTS   
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant INIT_ETH_BALANCE = 100_000 ether;
    uint256 internal constant INIT_TOKEN_BALANCE = 100_000 ether;
    uint256 internal constant INIT_TOKEN_SUPPLY = 100_000 ether;
    /*//////////////////////////////////////////////////////////////////////////
                                VESTING DETAILS   
    //////////////////////////////////////////////////////////////////////////*/

    uint32 internal constant DAY = 1 days;
    uint32 internal constant MONTH = 30 days;
    uint8 internal constant DEFAULT_STAKING_MONTH_AMOUNT = 23;

    uint16 internal constant LISTING_PERCENTAGE_DIVIDEND = 1;
    uint16 internal constant LISTING_PERCENTAGE_DIVISOR = 20;

    uint16 internal constant CLIFF_IN_DAYS = 1;
    uint32 internal constant CLIFF_IN_SECONDS = CLIFF_IN_DAYS * DAY;

    uint16 internal constant CLIFF_PERCENTAGE_DIVIDEND = 1;
    uint16 internal constant CLIFF_PERCENTAGE_DIVISOR = 10;

    uint16 internal constant VESTING_DURATION_IN_MONTHS = 3;
    uint16 internal constant VESTING_DURATION_IN_DAYS = 3 * 30;
    uint32 internal constant VESTING_DURATION_IN_SECONDS =
        VESTING_DURATION_IN_DAYS * DAY;

    /*//////////////////////////////////////////////////////////////////////////
                                VESTING AMOUNTS   
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant BENEFICIARY_TOKEN_AMOUNT = 1 ether;
    uint256 internal constant LISTING_TOKEN_AMOUNT =
        (BENEFICIARY_TOKEN_AMOUNT * LISTING_PERCENTAGE_DIVIDEND) /
            LISTING_PERCENTAGE_DIVISOR;
    uint256 internal constant CLIFF_TOKEN_AMOUNT =
        (BENEFICIARY_TOKEN_AMOUNT * CLIFF_PERCENTAGE_DIVIDEND) /
            CLIFF_PERCENTAGE_DIVISOR;
    uint256 internal constant LISTING_AND_CLIFF_TOKEN_AMOUNT =
        LISTING_TOKEN_AMOUNT + CLIFF_TOKEN_AMOUNT;
    uint256 internal constant VESTING_TOKEN_AMOUNT =
        BENEFICIARY_TOKEN_AMOUNT - LISTING_AND_CLIFF_TOKEN_AMOUNT;

    /*//////////////////////////////////////////////////////////////////////////
                                UNLOCK TYPES
    //////////////////////////////////////////////////////////////////////////*/

    IVesting.UnlockTypes internal constant MONTHLY_UNLOCK_TYPE =
        IVesting.UnlockTypes.MONTHLY;
    IVesting.UnlockTypes internal constant DAILY_UNLOCK_TYPE =
        IVesting.UnlockTypes.DAILY;

    /*//////////////////////////////////////////////////////////////////////////
                                STAKIN TYPES
    //////////////////////////////////////////////////////////////////////////*/

    IStaking.StakingTypes internal constant STAKING_TYPE_FIX =
        IStaking.StakingTypes.FIX;
    IStaking.StakingTypes internal constant STAKING_TYPE_FLEXI =
        IStaking.StakingTypes.FLEXI;

    /*//////////////////////////////////////////////////////////////////////////
                                VESTING POOL DATA   
    //////////////////////////////////////////////////////////////////////////*/

    uint16 internal constant TOTAL_STAKING_POOLS = 9;
    uint256 internal constant TOTAL_POOL_TOKEN_AMOUNT = 100_000 ether;

    uint16 internal constant PRIMARY_POOL = 0;
    uint16 internal constant SECONDARY_POOL = 1;
    uint32 internal constant PRIMARY_POOL_DISTRIBUTION_PERCENTAGE = 1300000;
    uint32 internal constant SECONDARY_POOL_DISTRIBUTION_PERCENTAGE = 1700000;
    string internal constant POOL_NAME = "Test1";
    string internal constant POOL_NAME_2 = "Test2";

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
                              VESTING BAND LEVEL DATA
    //////////////////////////////////////////////////////////////////////////*/

    uint16 internal constant TOTAL_BAND_LEVELS = 9;

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

    uint16 internal constant BAND_ID_0 = 0;
    uint16 internal constant BAND_ID_1 = 1;
    uint16 internal constant BAND_ID_2 = 2;
    uint16 internal constant BAND_ID_3 = 3;
    uint16 internal constant BAND_ID_4 = 4;

    /*//////////////////////////////////////////////////////////////////////////
                              SHARES DATA
    //////////////////////////////////////////////////////////////////////////*/

    uint48 internal constant SHARE = 1e6;
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
}
