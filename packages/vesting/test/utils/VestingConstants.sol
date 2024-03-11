// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IStaking} from "@wealth-of-wisdom/staking/contracts/interfaces/IStaking.sol";
import {StakingConstants} from "@wealth-of-wisdom/staking/test/utils/StakingConstants.sol";
import {IVesting} from "../../contracts/interfaces/IVesting.sol";

abstract contract VestingConstants is StakingConstants {
    /*//////////////////////////////////////////////////////////////////////////
                                    ROLES   
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 internal constant BENEFICIARIES_MANAGER_ROLE =
        keccak256("BENEFICIARIES_MANAGER_ROLE");

    /*//////////////////////////////////////////////////////////////////////////
                                VESTING DETAILS   
    //////////////////////////////////////////////////////////////////////////*/

    uint32 internal constant DAY = 1 days;
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

    uint256 internal constant TOTAL_POOL_TOKEN_AMOUNT = 100_000_000 ether;
    uint256 internal constant BENEFICIARY_TOKEN_AMOUNT = 1_000 ether;
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
                                    TESTING VARS
    //////////////////////////////////////////////////////////////////////////*/

    uint16 internal constant PRIMARY_POOL = 0;
    uint16 internal constant SECONDARY_POOL = 1;
    string internal constant POOL_NAME = "Test1";
    string internal constant POOL_NAME_2 = "Test2";

    uint256 internal constant TOTAL_POOL_TOKEN_AMOUNT_2 = 50_000 ether;
    uint16 internal constant LISTING_PERCENTAGE_DIVIDEND_2 = 3;
    uint16 internal constant LISTING_PERCENTAGE_DIVISOR_2 = 40;

    uint16 internal constant CLIFF_IN_DAYS_2 = 4;

    uint16 internal constant CLIFF_PERCENTAGE_DIVIDEND_2 = 2;
    uint16 internal constant CLIFF_PERCENTAGE_DIVISOR_2 = 15;

    uint16 internal constant VESTING_DURATION_IN_MONTHS_2 = 5;
}
