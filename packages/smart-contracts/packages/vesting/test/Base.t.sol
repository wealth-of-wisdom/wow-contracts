// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {VestingMock} from "./mocks/VestingMock.sol";
import {StakingMock} from "./mocks/StakingMock.sol";
import {TokenMock} from "./mocks/TokenMock.sol";
import {Assertions} from "./utils/Assertions.sol";
import {Events} from "./utils/Events.sol";

contract Base_Test is
    Test,
    Assertions, // Inherits Constants
    Events
{
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

    uint32 internal immutable LISTING_DATE;
    uint32 internal immutable CLIFF_END_DATE;
    uint32 internal immutable VESTING_END_DATE;

    TokenMock internal usdtToken;
    TokenMock internal usdcToken;
    TokenMock internal wowToken;
    VestingMock internal vesting;
    StakingMock internal staking;

    /*//////////////////////////////////////////////////////////////////////////
                                  CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        LISTING_DATE = uint32(block.timestamp) + DAY;
        CLIFF_END_DATE = LISTING_DATE + CLIFF_IN_SECONDS;
        VESTING_END_DATE = CLIFF_END_DATE + VESTING_DURATION_IN_SECONDS;
    }

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

        // VESTING
        vesting = new VestingMock();

        // STAKING
        staking = new StakingMock();

        vesting.initialize(wowToken, staking, LISTING_DATE);
        staking.initialize(
            usdtToken,
            usdcToken,
            wowToken,
            address(vesting),
            GELATO_EXECUTOR_ADDRESS,
            TOTAL_POOLS,
            TOTAL_BAND_LEVELS
        );

        // SET POOLS
        _setPools();
        // SET BAND LEVEL DATA
        _setBandLevelData();
        // // SET SHARES IN MONTH
        _setSharesInMonth(SHARES_IN_MONTH);

        vm.startPrank(admin);

        uint8 accountsNum = uint8(TEST_ACCOUNTS.length);
        for (uint8 i = 0; i < accountsNum; ++i) {
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

    modifier approveAndAddPool() {
        _approveAndAddPool();
        _;
    }

    modifier approveAndAddPoolWithName(string memory name) {
        _approveAndAddPool(name);
        _;
    }

    modifier addBeneficiary(address beneficiary) {
        _addBeneficiary(beneficiary);
        _;
    }

    modifier stakeVestedTokens(address beneficiary) {
        _stakeVestedTokens(beneficiary);
        _;
    }

    modifier updateGeneralPoolData() {
        _updateGeneralPoolData();
        _;
    }

    modifier updatePoolListingData() {
        _updatePoolListingData();
        _;
    }

    modifier updatePoolCliffData() {
        _updatePoolCliffData();
        _;
    }

    modifier updatePoolVestingData() {
        _updatePoolVestingData();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _approveAndAddPool() internal {
        _approveAndAddPool(POOL_NAME);
    }

    function _approveAndAddPool(string memory name) internal {
        vm.startPrank(admin);
        wowToken.approve(address(vesting), TOTAL_POOL_TOKEN_AMOUNT);
        _addDefaultVestingPool(name);
        vm.stopPrank();
    }

    function _addDefaultVestingPool() internal {
        _addDefaultVestingPool(POOL_NAME);
    }

    function _addDefaultVestingPool(string memory name) internal {
        vesting.addVestingPool(
            name,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_IN_DAYS,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR,
            VESTING_DURATION_IN_MONTHS,
            MONTHLY_UNLOCK_TYPE,
            TOTAL_POOL_TOKEN_AMOUNT
        );
    }

    function _updateGeneralPoolData() internal {
        _updateGeneralPoolData(PRIMARY_POOL);
    }

    function _updateGeneralPoolData(uint16 pid) internal {
        vm.prank(admin);
        vesting.updateGeneralPoolData(
            pid,
            POOL_NAME_2,
            DAILY_UNLOCK_TYPE,
            TOTAL_POOL_TOKEN_AMOUNT_2
        );
    }

    function _updatePoolListingData() internal {
        _updatePoolListingData(PRIMARY_POOL);
    }

    function _updatePoolListingData(uint16 pid) internal {
        vm.prank(admin);
        vesting.updatePoolListingData(
            pid,
            LISTING_PERCENTAGE_DIVIDEND_2,
            LISTING_PERCENTAGE_DIVISOR_2
        );
    }

    function _updatePoolCliffData() internal {
        _updatePoolCliffData(PRIMARY_POOL);
    }

    function _updatePoolCliffData(uint16 pid) internal {
        vm.prank(admin);
        vesting.updatePoolCliffData(
            pid,
            CLIFF_IN_DAYS_2,
            CLIFF_PERCENTAGE_DIVIDEND_2,
            CLIFF_PERCENTAGE_DIVISOR_2
        );
    }

    function _updatePoolVestingData() internal {
        _updatePoolVestingData(PRIMARY_POOL);
    }

    function _updatePoolVestingData(uint16 pid) internal {
        vm.prank(admin);
        vesting.updatePoolVestingData(
            PRIMARY_POOL,
            VESTING_DURATION_IN_MONTHS_2
        );
    }

    function _addBeneficiary(address beneficiary) internal {
        vm.prank(admin);
        vesting.addBeneficiary(
            PRIMARY_POOL,
            beneficiary,
            BENEFICIARY_TOKEN_AMOUNT
        );
    }

    function _stakeVestedTokens(address beneficiary) internal {
        vm.startPrank(beneficiary);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FIX,
            BAND_LEVEL_1,
            MONTH_1,
            PRIMARY_POOL
        );
        vm.stopPrank();
    }

    function _setBandLevelData() internal {
        vm.startPrank(admin);

        for (uint16 i; i < TOTAL_BAND_LEVELS; i++) {
            staking.setBandLevel(
                BAND_LEVELS[i],
                BAND_PRICES[i],
                BAND_ACCESSIBLE_POOLS[i]
            );
        }

        vm.stopPrank();
    }

    function _setPools() internal {
        vm.startPrank(admin);

        for (uint16 i; i < TOTAL_POOLS; i++) {
            staking.setPoolDistributionPercentage(
                POOL_IDS[i],
                POOL_PERCENTAGES[i]
            );
        }

        vm.stopPrank();
    }

    function _setSharesInMonth(uint48[] memory _sharesInMonth) internal {
        vm.prank(admin);
        staking.setSharesInMonth(_sharesInMonth);
    }
}
