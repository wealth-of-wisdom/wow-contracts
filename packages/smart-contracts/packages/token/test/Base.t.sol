// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {TokenMock} from "./mocks/TokenMock.sol";
import {Events} from "./utils/Events.sol";
import {Constants} from "./utils/Constants.sol";

contract Base_Test is Test, Constants, Events {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    address internal constant admin = address(0x1);
    address internal constant alice = address(0x2);
    address internal constant bob = address(0x3);
    address internal constant carol = address(0x4);

    address[] internal TEST_ACCOUNTS = [admin, alice, bob, carol];
    address[] internal beneficiaries = [alice, bob, carol];
    uint256[] internal tokenAmounts = [
        BENEFICIARY_TOKEN_AMOUNT,
        BENEFICIARY_TOKEN_AMOUNT,
        BENEFICIARY_TOKEN_AMOUNT
    ];

    TokenMock internal wowToken;
    TokenMock internal newWowToken;

    /*//////////////////////////////////////////////////////////////////////////
                                  CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {}

    /*//////////////////////////////////////////////////////////////////////////
                                SET UP FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        vm.startPrank(admin);

        // WOW TOKEN
        wowToken = new TokenMock();
        wowToken.initialize(TOKEN_NAME, TOKEN_SYMBOL, INIT_TOKEN_SUPPLY);

        // DISTRIBUTE AMOUNTS
        uint8 accountsNum = uint8(TEST_ACCOUNTS.length);
        for (uint8 i = 0; i < accountsNum; ++i) {
            deal(TEST_ACCOUNTS[i], INIT_ETH_BALANCE);
        }
        vm.stopPrank();
    }
}
