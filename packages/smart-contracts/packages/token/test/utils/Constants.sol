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

    uint8 internal constant WOW_DECIMALS = 18;

    /*//////////////////////////////////////////////////////////////////////////
                                    TOKEN
    //////////////////////////////////////////////////////////////////////////*/

    string internal constant TOKEN_SYMBOL = "WOW";
    string internal constant TOKEN_NAME = "WOW token";

    /*//////////////////////////////////////////////////////////////////////////
                                    AMOUNTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant INIT_ETH_BALANCE = type(uint128).max;
    uint256 internal constant INIT_TOKEN_BALANCE = type(uint128).max;
    uint256 internal constant INIT_TOKEN_SUPPLY = 100_000 ether;
    uint256 internal constant BENEFICIARY_TOKEN_AMOUNT = 1_000 ether;
    uint256 internal constant DEFAULT_AMOUNT = 1_000 * WOW_DECIMALS;
}
