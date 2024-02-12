// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {StakingMock} from "./mocks/StakingMock.sol";
import {TokenMock} from "./mocks/TokenMock.sol";
import {Constants} from "./utils/Constants.sol";
import {Events} from "./utils/Events.sol";

contract Base_Test is Test, Constants, Events {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    address internal constant admin = address(0x1);
    address internal constant alice = address(0x2);
    address internal constant bob = address(0x3);
    address internal constant carol = address(0x4);
    address internal constant dan = address(0x5);
    address internal constant eve = address(0x6);

    address[] internal TEST_ACCOUNTS = [admin, alice, bob, carol, dan, eve];

    TokenMock internal usdtToken;
    TokenMock internal usdcToken;
    TokenMock internal wowToken;
    StakingMock internal staking;

    /*//////////////////////////////////////////////////////////////////////////
                                  CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {}

    /*//////////////////////////////////////////////////////////////////////////
                                SET UP FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        vm.startPrank(admin);

        // USDT TOKEN
        usdtToken = new TokenMock();
        usdtToken.initialize(
            "USDT token",
            "USDT",
            USD_DECIMALS,
            INIT_TOKEN_SUPPLY
        );

        // USDC TOKEN
        usdcToken = new TokenMock();
        usdcToken.initialize(
            "USDC token",
            "USDTC",
            USD_DECIMALS,
            INIT_TOKEN_SUPPLY
        );

        // WOW TOKEN
        wowToken = new TokenMock();
        wowToken.initialize(
            "WOW token",
            "WOW",
            WOW_DECIMALS,
            INIT_TOKEN_SUPPLY
        );

        // STAKING CONTRACT
        staking = new StakingMock();
        staking.initialize(
            usdtToken,
            usdcToken,
            wowToken,
            TOTAL_POOLS,
            TOTAL_BAND_LEVELS
        );

        // MINT TOKENS TO TEST ACCOUNTS
        uint8 accountsAmount = uint8(TEST_ACCOUNTS.length);
        for (uint8 i = 0; i < accountsAmount; ++i) {
            deal(TEST_ACCOUNTS[i], INIT_ETH_BALANCE);
            usdtToken.mint(TEST_ACCOUNTS[i], INIT_TOKEN_BALANCE);
            usdcToken.mint(TEST_ACCOUNTS[i], INIT_TOKEN_BALANCE);
            wowToken.mint(TEST_ACCOUNTS[i], INIT_TOKEN_BALANCE);
        }

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    HELPER MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/
    modifier stakeTokens() {
        _stakeTokens();
        _;
    }

    modifier setBandLevelData() {
        _setBandLevelData();
        _;
    }

    modifier distributeFunds() {
        _distributeFunds();
        _;
    }

    function _stakeTokens() internal {
        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_4_PRICE);
        staking.stake(STAKING_TYPE_FLEXI, BAND_ID_4);
        vm.stopPrank();
    }

    function _setBandLevelData() internal {
        vm.startPrank(admin);
        staking.setBandLevel(BAND_ID_1, BAND_1_PRICE, BAND_1_ACCESSIBLE_POOLS);
        staking.setBandLevel(BAND_ID_2, BAND_2_PRICE, BAND_2_ACCESSIBLE_POOLS);
        staking.setBandLevel(BAND_ID_3, BAND_3_PRICE, BAND_3_ACCESSIBLE_POOLS);
        staking.setBandLevel(BAND_ID_4, BAND_4_PRICE, BAND_4_ACCESSIBLE_POOLS);
        staking.setBandLevel(BAND_ID_5, BAND_5_PRICE, BAND_5_ACCESSIBLE_POOLS);
        staking.setBandLevel(BAND_ID_6, BAND_6_PRICE, BAND_6_ACCESSIBLE_POOLS);
        staking.setBandLevel(BAND_ID_7, BAND_7_PRICE, BAND_7_ACCESSIBLE_POOLS);
        staking.setBandLevel(BAND_ID_8, BAND_8_PRICE, BAND_8_ACCESSIBLE_POOLS);
        staking.setBandLevel(BAND_ID_9, BAND_9_PRICE, BAND_9_ACCESSIBLE_POOLS);
        vm.stopPrank();
    }

    function _distributeFunds() internal {
        vm.startPrank(admin);
        usdcToken.approve(address(staking), DEFAULT_DISTRIBUTION_AMOUNT);
        staking.distributeFunds(usdcToken, DEFAULT_DISTRIBUTION_AMOUNT);
        vm.stopPrank();
    }
    /*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
}
