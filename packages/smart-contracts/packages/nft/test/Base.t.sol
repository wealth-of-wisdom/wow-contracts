// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
import {StakingMock} from "@wealth-of-wisdom/vesting/test/mocks/StakingMock.sol";
import {INft} from "../contracts/interfaces/INft.sol";
import {Constants} from "./utils/Constants.sol";
import {Events} from "./utils/Events.sol";
import {TokenMock} from "./mocks/TokenMock.sol";
import {NftMock} from "./mocks/NftMock.sol";
import {NftSaleMock} from "./mocks/NftSaleMock.sol";
import {VestingMock} from "./mocks/VestingMock.sol";

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

    TokenMock internal tokenUSDT;
    TokenMock internal tokenUSDC;
    NftMock internal nft;
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
        vm.startPrank(admin);

        // STAKING
        staking = new StakingMock();

        // USDT TOKEN
        tokenUSDT = new TokenMock();
        tokenUSDT.initialize("USDT token", "USDT", INITIAL_TOKEN_AMOUNT);

        // USDC TOKEN
        tokenUSDC = new TokenMock();
        tokenUSDC.initialize("USDC token", "USDTC", INITIAL_TOKEN_AMOUNT);

        // MINT TOKENS TO TEST ACCOUNTS
        uint8 accountsNum = uint8(TEST_ACCOUNTS.length);
        for (uint8 i = 0; i < accountsNum; ++i) {
            deal(TEST_ACCOUNTS[i], INIT_ETH_BALANCE);
            tokenUSDT.mint(TEST_ACCOUNTS[i], INIT_TOKEN_BALANCE);
            tokenUSDC.mint(TEST_ACCOUNTS[i], INIT_TOKEN_BALANCE);
        }

        // VESTING
        vesting = new VestingMock();
        vesting.initialize(tokenUSDT, staking, LISTING_DATE);
        tokenUSDT.approve(address(vesting), TOTAL_POOL_TOKEN_AMOUNT);
        vesting.addVestingPool(
            POOL_NAME,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_IN_DAYS,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR,
            VESTING_DURATION_IN_MONTHS,
            VESTING_UNLOCK_TYPE,
            TOTAL_POOL_TOKEN_AMOUNT
        );

        // NFT
        nft = new NftMock();
        nft.initialize(
            "Wealth of Wisdom",
            "WOW",
            vesting,
            DEFAULT_VESTING_PID,
            MAX_LEVEL,
            TOTAL_PROJECT_TYPES
        );

        // NFT SALE
        sale = new NftSaleMock();
        sale.initialize(tokenUSDT, tokenUSDC, INft(address(nft)));

        // SET UP ROLES
        nft.grantRole(MINTER_ROLE, address(sale));
        nft.grantRole(NFT_DATA_MANAGER_ROLE, address(sale));
        vesting.grantRole(BENEFICIARIES_MANAGER_ROLE, address(nft));

        vm.stopPrank();

        _setNftLevels();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    HELPER MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier mintEachLevelNft() {
        _mintEachLevelNft();
        _;
    }

    modifier setNftLevels() {
        _setNftLevels();
        _;
    }

    modifier mintLevel2NftForAlice() {
        _mintLevel2NftForAlice();
        _;
    }

    function _mintEachLevelNft() internal {
        vm.startPrank(admin);
        nft.mintAndSetNftData(alice, LEVEL_1, false);
        nft.mintAndSetNftData(bob, LEVEL_2, false);
        nft.mintAndSetNftData(carol, LEVEL_3, false);
        nft.mintAndSetNftData(dan, LEVEL_4, false);
        nft.mintAndSetNftData(eve, LEVEL_5, false);
        nft.mintAndSetNftData(eve, LEVEL_1, true);
        nft.mintAndSetNftData(dan, LEVEL_2, true);
        nft.mintAndSetNftData(carol, LEVEL_3, true);
        nft.mintAndSetNftData(bob, LEVEL_4, true);
        nft.mintAndSetNftData(alice, LEVEL_5, true);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _setNftLevels() internal {
        vm.startPrank(admin);

        // MAIN NFT LEVELS

        nft.setLevelData(
            LEVEL_1,
            false,
            LEVEL_1_PRICE,
            LEVEL_1_VESTING_REWARD,
            LEVEL_1_LIFECYCLE_DURATION,
            LEVEL_1_EXTENSION_DURATION,
            LEVEL_1_ALLOCATION_PER_PROJECT,
            LEVEL_1_SUPPLY_CAP,
            LEVEL_1_BASE_URI
        );

        nft.setLevelData(
            LEVEL_2,
            false,
            LEVEL_2_PRICE,
            LEVEL_2_VESTING_REWARD,
            LEVEL_2_LIFECYCLE_DURATION,
            LEVEL_2_EXTENSION_DURATION,
            LEVEL_2_ALLOCATION_PER_PROJECT,
            LEVEL_2_SUPPLY_CAP,
            LEVEL_2_BASE_URI
        );

        nft.setLevelData(
            LEVEL_3,
            false,
            LEVEL_3_PRICE,
            LEVEL_3_VESTING_REWARD,
            LEVEL_3_LIFECYCLE_DURATION,
            LEVEL_3_EXTENSION_DURATION,
            LEVEL_3_ALLOCATION_PER_PROJECT,
            LEVEL_3_SUPPLY_CAP,
            LEVEL_3_BASE_URI
        );

        nft.setLevelData(
            LEVEL_4,
            false,
            LEVEL_4_PRICE,
            LEVEL_4_VESTING_REWARD,
            LEVEL_4_LIFECYCLE_DURATION,
            LEVEL_4_EXTENSION_DURATION,
            LEVEL_4_ALLOCATION_PER_PROJECT,
            LEVEL_4_SUPPLY_CAP,
            LEVEL_4_BASE_URI
        );

        nft.setLevelData(
            LEVEL_5,
            false,
            LEVEL_5_PRICE,
            LEVEL_5_VESTING_REWARD,
            LEVEL_5_LIFECYCLE_DURATION,
            LEVEL_5_EXTENSION_DURATION,
            LEVEL_5_ALLOCATION_PER_PROJECT,
            LEVEL_5_SUPPLY_CAP,
            LEVEL_5_BASE_URI
        );

        // GENESIS NFT LEVELS
        // FOR SIMPLICITY, WE USE THE SAME DATA AS THE MAIN NFT LEVELS

        nft.setLevelData(
            LEVEL_1,
            true,
            LEVEL_1_PRICE,
            LEVEL_1_VESTING_REWARD,
            LEVEL_1_LIFECYCLE_DURATION,
            LEVEL_1_EXTENSION_DURATION,
            LEVEL_1_ALLOCATION_PER_PROJECT,
            type(uint256).max, // supply cap is ignored for genesis NFTs
            LEVEL_1_GENESIS_BASE_URI
        );

        nft.setLevelData(
            LEVEL_2,
            true,
            LEVEL_2_PRICE,
            LEVEL_2_VESTING_REWARD,
            LEVEL_2_LIFECYCLE_DURATION,
            LEVEL_2_EXTENSION_DURATION,
            LEVEL_2_ALLOCATION_PER_PROJECT,
            type(uint256).max, // supply cap is ignored for genesis NFTs
            LEVEL_2_GENESIS_BASE_URI
        );

        nft.setLevelData(
            LEVEL_3,
            true,
            LEVEL_3_PRICE,
            LEVEL_3_VESTING_REWARD,
            LEVEL_3_LIFECYCLE_DURATION,
            LEVEL_3_EXTENSION_DURATION,
            LEVEL_3_ALLOCATION_PER_PROJECT,
            type(uint256).max, // supply cap is ignored for genesis NFTs
            LEVEL_3_GENESIS_BASE_URI
        );

        nft.setLevelData(
            LEVEL_4,
            true,
            LEVEL_4_PRICE,
            LEVEL_4_VESTING_REWARD,
            LEVEL_4_LIFECYCLE_DURATION,
            LEVEL_4_EXTENSION_DURATION,
            LEVEL_4_ALLOCATION_PER_PROJECT,
            type(uint256).max, // supply cap is ignored for genesis NFTs
            LEVEL_4_GENESIS_BASE_URI
        );

        nft.setLevelData(
            LEVEL_5,
            true,
            LEVEL_5_PRICE,
            LEVEL_5_VESTING_REWARD,
            LEVEL_5_LIFECYCLE_DURATION,
            LEVEL_5_EXTENSION_DURATION,
            LEVEL_5_ALLOCATION_PER_PROJECT,
            type(uint256).max, // supply cap is ignored for genesis NFTs
            LEVEL_5_GENESIS_BASE_URI
        );

        vm.stopPrank();
    }

    function _mintLevel2NftForAlice() internal {
        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), type(uint256).max);
        sale.mintNft(LEVEL_2, tokenUSDT);
        vm.stopPrank();
    }
}
