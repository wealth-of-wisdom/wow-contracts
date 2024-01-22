// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {StakingMock} from "@wealth-of-wisdom/vesting/test/mocks/StakingMock.sol";
import {VestingMock} from "@wealth-of-wisdom/vesting/test/mocks/VestingMock.sol";
import {Constants} from "./utils/Constants.sol";
import {Events} from "./utils/Events.sol";
import {TokenMock} from "./mocks/TokenMock.sol";
import {NftSaleMock} from "./mocks/NftSaleMock.sol";
import {Nft} from "../contracts/Nft.sol";

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

    // // Pools
    // modifier mintLevel2NftDataForAlice() {
    //     _mintLevel2NftDataForAlice();
    //     _;
    // }

    // modifier setNftDataForContract() {
    //     _setNftDataForContract();
    //     _;
    // }

    // function _mintLevel2NftDataForAlice() internal {
    //     vm.startPrank(alice);
    //     uint256 price = nftContract.getLevelData(LEVEL_2).price;
    //     tokenUSDT.approve(address(sale), price);
    //     sale.mintNft(LEVEL_2, tokenUSDT);
    //     vm.stopPrank();
    // }

    // function _setNftDataForContract() internal {
    //     vm.startPrank(admin);
    //     nftContract.setLevelData(
    //         LEVEL_1,
    //         LEVEL_1_PRICE,
    //         LEVEL_1_VESTING_REWARD,
    //         LEVEL_1_LIFECYCLE_TIMESTAMP,
    //         LEVEL_1_EXTENDED_LIFECYCLE_TIMESTAMP,
    //         LEVEL_1_ALLOCATION_PER_PROJECT,
    //         MAIN_BASE_URI,
    //         GENESIS_BASE_URI
    //     );
    //     nftContract.setLevelData(
    //         LEVEL_2,
    //         LEVEL_2_PRICE,
    //         LEVEL_2_VESTING_REWARD,
    //         LEVEL_2_LIFECYCLE_TIMESTAMP,
    //         LEVEL_2_EXTENDED_LIFECYCLE_TIMESTAMP,
    //         LEVEL_2_ALLOCATION_PER_PROJECT,
    //         MAIN_BASE_URI,
    //         GENESIS_BASE_URI
    //     );
    //     nftContract.setLevelData(
    //         LEVEL_3,
    //         LEVEL_3_PRICE,
    //         LEVEL_3_VESTING_REWARD,
    //         LEVEL_3_LIFECYCLE_TIMESTAMP,
    //         LEVEL_3_EXTENDED_LIFECYCLE_TIMESTAMP,
    //         LEVEL_3_ALLOCATION_PER_PROJECT,
    //         MAIN_BASE_URI,
    //         GENESIS_BASE_URI
    //     );
    //     nftContract.setLevelData(
    //         LEVEL_4,
    //         LEVEL_4_PRICE,
    //         LEVEL_4_VESTING_REWARD,
    //         LEVEL_4_LIFECYCLE_TIMESTAMP,
    //         LEVEL_4_EXTENDED_LIFECYCLE_TIMESTAMP,
    //         LEVEL_4_ALLOCATION_PER_PROJECT,
    //         MAIN_BASE_URI,
    //         GENESIS_BASE_URI
    //     );
    //     vm.stopPrank();
    // }
}
