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

    TokenMock internal token;
    VestingMock internal vesting;
    StakingMock internal staking;

    /*//////////////////////////////////////////////////////////////////////////
                                  CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        LISTING_DATE = uint32(block.timestamp) + 1 days;
        CLIFF_END_DATE = LISTING_DATE + CLIFF_IN_DAYS * 1 days;
        VESTING_END_DATE =
            CLIFF_END_DATE +
            VESTING_DURATION_IN_MONTHS *
            30 days;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                SET UP FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        uint8 accountsNum = uint8(TEST_ACCOUNTS.length);

        vm.startPrank(admin);
        token = new TokenMock();
        token.initialize("MOCK", "MCK", TOTAL_POOL_TOKEN_AMOUNT * 10);

        staking = new StakingMock();

        for (uint8 i = 0; i < accountsNum; ++i) {
            deal(TEST_ACCOUNTS[i], INIT_ETH_BALANCE);
            token.mint(TEST_ACCOUNTS[i], INIT_TOKEN_BALANCE);
        }
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////////////////
                          HELPER MODIFIERS / FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    // Pools
    modifier approveAndAddPool() {
        _approveAndAddPool();
        _;
    }

    function _approveAndAddPool() internal {
        _approveAndAddPool(POOL_NAME);
    }

    function _approveAndAddPool(string memory name) internal {
        vm.startPrank(admin);
        token.approve(address(vesting), TOTAL_POOL_TOKEN_AMOUNT);
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
            VESTING_UNLOCK_TYPE,
            TOTAL_POOL_TOKEN_AMOUNT
        );
    }

    // Beneficiaries
    modifier addBeneficiary(address beneficiary) {
        _addBeneficiary(beneficiary);
        _;
    }

    function _addBeneficiary(address beneficiary) internal {
        vm.prank(admin);
        vesting.addBeneficiary(
            PRIMARY_POOL,
            beneficiary,
            BENEFICIARY_TOKEN_AMOUNT
        );
    }
}
