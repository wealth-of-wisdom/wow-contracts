// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

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
    bytes32 internal constant STAKING_ROLE = keccak256("STAKING_ROLE");
    bytes32 internal constant BENEFICIARIES_MANAGER_ROLE =
        keccak256("BENEFICIARIES_MANAGER_ROLE");

    /*//////////////////////////////////////////////////////////////////////////
                                    DECIMALS
    //////////////////////////////////////////////////////////////////////////*/

    uint8 internal constant USD_DECIMALS = 6;
    uint8 internal constant WOW_DECIMALS = 18;

    /*//////////////////////////////////////////////////////////////////////////
                                    AMOUNTS   
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant INIT_ETH_BALANCE = 100_000 ether;
    uint256 internal constant INIT_TOKEN_BALANCE = 100_000 ether;
    uint256 internal constant INIT_TOKEN_SUPPLY = 100_000 ether;

    /*//////////////////////////////////////////////////////////////////////////
                                STAKING DETAILS   
    //////////////////////////////////////////////////////////////////////////*/

    uint16 internal constant TOTAL_STAKING_POOLS = 9;
    uint16 internal constant TOTAL_BAND_LEVELS = 9;

    /*//////////////////////////////////////////////////////////////////////////
                                VESTING DETAILS   
    //////////////////////////////////////////////////////////////////////////*/

    uint32 internal constant DAY = 1 days;
    uint32 internal constant MONTH = 30 days;

    uint16 internal constant PRIMARY_POOL = 0;
    uint16 internal constant SECONDARY_POOL = 1;
    string internal constant POOL_NAME = "Test1";
    string internal constant POOL_NAME_2 = "Test2";

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

    uint256 internal constant TOTAL_POOL_TOKEN_AMOUNT = 100_000 ether;
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
}
