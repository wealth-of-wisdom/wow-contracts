// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";

abstract contract Constants {
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant BENEFICIARIES_MANAGER_ROLE =
        keccak256("BENEFICIARIES_MANAGER_ROLE");

    address internal constant ZERO_ADDRESS = address(0x0);
    uint256 internal constant INIT_ETH_BALANCE = type(uint128).max;
    uint256 internal constant INIT_TOKEN_BALANCE = type(uint128).max;

    uint16 internal constant DEFAULT_LEVEL = 2;
    uint16 internal constant DEFAULT_NEW_LEVEL = 3;
    uint16 internal constant DEFAULT_PRICE = 500;

    uint16 internal constant DEFAULT_GENESIS_AMOUNT = 5;
    uint256 internal constant TOTAL_TOKEN_AMOUNT = 100_000 ether;
    uint256 internal constant STARTER_TOKEN_ID = 0;
    uint256 internal constant FIRST_MINTED_TOKEN_ID = 1;

    uint16 internal constant DEFAULT_PID = 0;
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

    INftSale.ActivityType internal constant NFT_ACTIVITY_TYPE_ACTIVATED =
        INftSale.ActivityType.ACTIVATED;
    INftSale.ActivityType internal constant NFT_ACTIVITY_TYPE_INACTIVE =
        INftSale.ActivityType.INACTIVE;
    INftSale.ActivityType internal constant NFT_ACTIVITY_TYPE_DEACTIVATED =
        INftSale.ActivityType.DEACTIVATED;
}
