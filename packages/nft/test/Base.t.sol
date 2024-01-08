// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {Constants} from "./utils/Constants.sol";
import {TokenMock} from "./mocks/TokenMock.sol";
import {NftSaleMock} from "./mocks/NftSaleMock.sol";
import {NftMock} from "./mocks/NftMock.sol";

contract Base_Test is Test, Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    address internal constant admin = address(0x1);
    address internal constant alice = address(0x2);
    address internal constant bob = address(0x3);
    address internal constant carol = address(0x4);

    address[] internal TEST_ACCOUNTS = [admin, alice, bob, carol];
    address[] internal beneficiaries = [alice, bob, carol];

    TokenMock internal tokenUSDT;
    TokenMock internal tokenUSDC;
    NftMock internal nftContract;
    NftSaleMock internal sale;

    /*//////////////////////////////////////////////////////////////////////////
                                  CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {}

    /*//////////////////////////////////////////////////////////////////////////
                                SET UP FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        uint8 accountsNum = uint8(TEST_ACCOUNTS.length);

        vm.startPrank(admin);
        tokenUSDT = new TokenMock();
        tokenUSDT.initialize("USDT token", "USDT", TOTAL_TOKEN_AMOUNT);

        tokenUSDC = new TokenMock();
        tokenUSDC.initialize("USDC token", "USDTC", TOTAL_TOKEN_AMOUNT);

        for (uint8 i = 0; i < accountsNum; ++i) {
            deal(TEST_ACCOUNTS[i], INIT_ETH_BALANCE);
            tokenUSDT.mint(TEST_ACCOUNTS[i], INIT_TOKEN_BALANCE);
            tokenUSDC.mint(TEST_ACCOUNTS[i], INIT_TOKEN_BALANCE);
        }
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////////////////
                          HELPER MODIFIERS / FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    // Pools
    modifier mintOneBandForUser() {
        _mintOneBandForUser();
        _;
    }

    function _mintOneBandForUser() internal {
        vm.startPrank(alice);
        uint256 price = sale.getLevelPriceInUSD(DEFAULT_LEVEL);
        tokenUSDT.approve(address(sale), price);
        sale.mintBand(DEFAULT_LEVEL, tokenUSDT);
        vm.stopPrank();
    }
}
