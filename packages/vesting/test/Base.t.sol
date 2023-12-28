// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {Vesting} from "../contracts/Vesting.sol";
import {IVesting} from "../contracts/interfaces/IVesting.sol";
import {MockToken} from "./mocks/MockToken.sol";
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

    address internal constant admin = address(0x420);
    address internal constant alice = address(0x421);
    address internal constant bob = address(0x422);
    address internal constant carol = address(0x423);

    address[] internal TEST_ACCOUNTS = [admin, alice, bob, carol];
    address[] internal beneficiaries = [alice, bob, carol];
    uint256[] internal tokenAmounts = [
        BENEFICIARY_TOKEN_AMOUNT,
        BENEFICIARY_TOKEN_AMOUNT,
        BENEFICIARY_TOKEN_AMOUNT
    ];

    uint32 internal immutable LISTING_DATE;
    MockToken internal token;
    Vesting internal vesting;
    address internal staking = address(0x524);

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
        token = new MockToken();
        token.initialize("MOCK", "MCK", TOTAL_POOL_TOKEN_AMOUNT * 10);

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

    // function checkPoolState(
    //     uint16 poolIndex,
    //     uint256 calculatedUnlockedPoolTokens
    // ) public {
    //     (
    //         string memory name,
    //         uint16 listingPercentageDividend,
    //         uint16 listingPercentageDivisor,
    //         uint16 cliffPercentageDividend,
    //         uint16 cliffPercentageDivisor,
    //         IVesting.UnlockTypes unlockType,
    //         uint256 totalPoolTokenAmount
    //     ) = vesting.getPoolData(poolIndex);

    //     (
    //         uint16 cliffInDays,
    //         uint32 cliffEndDate,
    //         uint16 vestingDurationInDays,
    //         uint16 vestingDurationInMonths,
    //         uint32 vestingEndDate
    //     ) = vesting.getPoolDates(poolIndex);

    //     uint32 listingDate = vesting.getListingDate();
    //     uint256 unlockedPoolTokens = vesting.getTotalUnlockedPoolTokens(
    //         poolIndex
    //     );

    //     assertEq(POOL_NAME, name, "POOL_NAME is incorrect");
    //     assertEq(
    //         LISTING_PERCENTAGE_DIVIDEND,
    //         listingPercentageDividend,
    //         "LISTING_PERCENTAGE_DIVIDEND is incorrect"
    //     );
    //     assertEq(
    //         LISTING_PERCENTAGE_DIVISOR,
    //         listingPercentageDivisor,
    //         "LISTING_PERCENTAGE_DIVISOR is incorrect"
    //     );
    //     assertEq(
    //         CLIFF_PERCENTAGE_DIVIDEND,
    //         cliffPercentageDividend,
    //         "CLIFF_PERCENTAGE_DIVIDEND is incorrect"
    //     );
    //     assertEq(
    //         CLIFF_PERCENTAGE_DIVISOR,
    //         cliffPercentageDivisor,
    //         "CLIFF_PERCENTAGE_DIVISOR is incorrect"
    //     );
    //     assertEq(
    //         TOTAL_POOL_TOKEN_AMOUNT,
    //         totalPoolTokenAmount,
    //         "TOTAL_POOL_TOKEN_AMOUNT is incorrect"
    //     );
    //     assertEq(
    //         VESTING_DURATION_IN_MONTHS,
    //         vestingDurationInMonths,
    //         "vestingDurationInMonths is incorrect"
    //     );
    //     assertEq(
    //         vestingDurationInDays,
    //         30 * vestingDurationInMonths,
    //         "vestingDurationInDays is incorrect"
    //     );
    //     assertEq(
    //         vestingEndDate,
    //         cliffEndDate + 24 * 3600 * 30 * vestingDurationInMonths,
    //         "vestingEndDate is incorrect"
    //     );
    //     assertEq(
    //         calculatedUnlockedPoolTokens,
    //         unlockedPoolTokens,
    //         "unlockedPoolTokens is incorrect"
    //     );
    //     assertEq(
    //         cliffEndDate,
    //         listingDate + 24 * 3600 * cliffInDays,
    //         "cliffEndDate is incorrect"
    //     );
    // }
}
