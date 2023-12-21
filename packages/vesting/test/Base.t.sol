// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {WOW_Vesting} from "../contracts/WOW_Vesting.sol";
import {IVesting} from "../contracts/interfaces/IVesting.sol";
import {MockToken} from "./mocks/MockToken.sol";
import {Constants} from "./utils/Constants.sol";

contract Base_Test is Test, Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    address constant ZERO_ADDRESS = address(0x0);
    address internal constant alice = address(0x421);
    address internal constant bob = address(0x422);
    address internal constant carol = address(0x423);

    address[] internal TEST_ACCOUNTS = [alice, bob, carol];
    uint256 internal immutable N_TESTERS;
    uint32 internal immutable LISTING_DATE;

    MockToken internal token;
    WOW_Vesting internal vesting;

    /*//////////////////////////////////////////////////////////////////////////
                                  CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(uint8 nTesters) {
        // Assign the test accounts
        require(nTesters <= TEST_ACCOUNTS.length, "Too many testers");
        N_TESTERS = nTesters;

        LISTING_DATE = uint32(block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                SET UP FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        token = new MockToken();
        token.initialize("MOCK", "MCK", 1000);

        for (uint256 i = 0; i < N_TESTERS; ++i) {
            deal(TEST_ACCOUNTS[i], INIT_ETH_BALANCE);
            token.mint(TEST_ACCOUNTS[i], INIT_SUPER_TOKEN_BALANCE);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function addOneNormalVestingPool() public {
        vesting.addVestingPool(
            POOL_NAME,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_IN_DAYS,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR,
            VESTING_DURATION_IN_MONTHS,
            IVesting.UnlockTypes.MONTHLY,
            TOTAL_POOL_TOKEN_AMONUT
        );
    }

    function checkPoolState(uint16 poolIndex) public {
        (
            string memory name,
            uint16 listingPercentageDividend,
            uint16 listingPercentageDivisor,
            uint16 cliffPercentageDividend,
            uint16 cliffPercentageDivisor,
            IVesting.UnlockTypes unlockType,
            uint256 totalPoolTokenAmount
        ) = vesting.getPoolData(poolIndex);

        (
            uint16 cliffInDays,
            uint32 cliffEndDate,
            uint16 vestingDurationInDays,
            uint16 vestingDurationInMonths,
            uint32 vestingEndDate
        ) = vesting.getPoolDates(poolIndex);

        uint32 listingDate = vesting.getListingDate();
        uint256 unlockedPoolTokens = vesting.getTotalUnlockedPoolTokens(
            poolIndex
        );

        assertEq(POOL_NAME, name, "POOL_NAME is incorrect");
        assertEq(
            LISTING_PERCENTAGE_DIVIDEND,
            listingPercentageDividend,
            "LISTING_PERCENTAGE_DIVIDEND is incorrect"
        );
        assertEq(
            LISTING_PERCENTAGE_DIVISOR,
            listingPercentageDivisor,
            "LISTING_PERCENTAGE_DIVISOR is incorrect"
        );
        assertEq(
            CLIFF_PERCENTAGE_DIVIDEND,
            cliffPercentageDividend,
            "CLIFF_PERCENTAGE_DIVIDEND is incorrect"
        );
        assertEq(
            CLIFF_PERCENTAGE_DIVISOR,
            cliffPercentageDivisor,
            "CLIFF_PERCENTAGE_DIVISOR is incorrect"
        );
        assertEq(
            TOTAL_POOL_TOKEN_AMONUT,
            totalPoolTokenAmount,
            "TOTAL_POOL_TOKEN_AMONUT is incorrect"
        );
        assertEq(
            VESTING_DURATION_IN_MONTHS,
            vestingDurationInMonths,
            "vestingDurationInMonths is incorrect"
        );
        assertEq(
            vestingDurationInDays,
            30 * vestingDurationInMonths,
            "vestingDurationInDays is incorrect"
        );
        assertEq(
            vestingEndDate,
            cliffEndDate + 24 * 3600 * 30 * vestingDurationInMonths,
            "vestingEndDate is incorrect"
        );
        assertEq(
            TOTAL_POOL_TOKEN_AMONUT,
            unlockedPoolTokens,
            "unlockedPoolTokens is incorrect"
        );
        assertEq(
            cliffEndDate,
            listingDate + 24 * 3600 * cliffInDays,
            "cliffEndDate is incorrect"
        );
    }

    function checkBeneficiaryState(
        uint16 poolIndex,
        address beneficiary,
        uint256 amount,
        uint256 calculatedClaimedAmount
    ) public {
        (
            uint256 totalTokens,
            uint256 listingTokenAmount,
            uint256 cliffTokenAmount,
            uint256 vestedTokenAmount,
            uint256 claimedTotalTokenAmount
        ) = vesting.getBeneficiaryInformation(poolIndex, beneficiary);

        uint256 calculatedListingTokenAmount = (amount *
            LISTING_PERCENTAGE_DIVIDEND) / LISTING_PERCENTAGE_DIVISOR;
        uint256 calculateCliffTokenAmount = (amount *
            CLIFF_PERCENTAGE_DIVIDEND) / CLIFF_PERCENTAGE_DIVISOR;
        uint256 calculatedVestedTokenAmount = amount -
            listingTokenAmount -
            cliffTokenAmount;

        assertEq(amount, totalTokens, "totalTokens is incorrect.");
        assertEq(
            calculatedListingTokenAmount,
            listingTokenAmount,
            "listingTokenAmount is incorrect"
        );
        assertEq(
            calculateCliffTokenAmount,
            cliffTokenAmount,
            "cliffTokenAmount is incorrect"
        );
        assertEq(
            calculatedVestedTokenAmount,
            vestedTokenAmount,
            "vestedTokenAmount is incorrect"
        );
        assertEq(
            calculatedClaimedAmount,
            claimedTotalTokenAmount,
            "claimedTotalTokenAmount is incorrect"
        );
    }
}
