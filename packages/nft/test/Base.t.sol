// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {Constants} from "@wealth-of-wisdom/nft/test/utils/Constants.sol";
import {Events} from "@wealth-of-wisdom/nft/test/utils/Events.sol";
import {TokenMock} from "@wealth-of-wisdom/nft/test/mocks/TokenMock.sol";
import {StakingMock} from "@wealth-of-wisdom/vesting/test/mocks/StakingMock.sol";
import {VestingMock} from "@wealth-of-wisdom/vesting/test/mocks/VestingMock.sol";
import {NftSaleMock} from "@wealth-of-wisdom/nft/test/mocks/NftSaleMock.sol";
import {Nft} from "@wealth-of-wisdom/nft/contracts/Nft.sol";

contract Base_Test is Test, Constants, Events {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    address internal constant admin = address(0x1);
    address internal constant alice = address(0x2);
    address internal constant bob = address(0x3);
    address internal constant carol = address(0x4);
    address internal constant dan = address(0x5);

    address[] internal TEST_ACCOUNTS = [admin, alice, bob, carol, dan];
    address[] internal beneficiaries = [alice, bob, carol, dan];

    TokenMock internal tokenUSDT;
    TokenMock internal tokenUSDC;
    Nft internal nftContract;
    NftSaleMock internal sale;
    StakingMock internal staking;
    VestingMock internal vesting;

    uint32 internal immutable LISTING_DATE;

    /*//////////////////////////////////////////////////////////////////////////
                                  CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        LISTING_DATE = uint32(block.timestamp) + 1 days;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                SET UP FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        uint8 accountsNum = uint8(TEST_ACCOUNTS.length);

        vm.startPrank(admin);
        staking = new StakingMock();

        tokenUSDT = new TokenMock();
        tokenUSDT.initialize("USDT token", "USDT", INITIAL_TOKEN_AMOUNT);

        tokenUSDC = new TokenMock();
        tokenUSDC.initialize("USDC token", "USDTC", INITIAL_TOKEN_AMOUNT);

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
    modifier mintLevel2BandForAlice() {
        _mintLevel2BandForAlice();
        _;
    }

    function _mintLevel2BandForAlice() internal {
        vm.startPrank(alice);
        uint256 price = sale.getLevelPriceInUSD(DEFAULT_LEVEL_2);
        tokenUSDT.approve(address(sale), price);
        sale.mintBand(DEFAULT_LEVEL_2, tokenUSDT);
        vm.stopPrank();
    }
}
