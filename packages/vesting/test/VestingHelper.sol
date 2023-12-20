// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.14;

// import {Test} from "forge-std/Test.sol";
// import {WOW_Vesting} from "../contracts/WOW_Vesting.sol";
// import {MockToken} from "../contracts/mock/MockToken.sol";

// // Helper for foundry tests of Superfluid related contracts
// contract VestingHelper is Test {
//     /* ============ STATE VARIABLES ============ */
//     uint256 internal constant INIT_ETH_BALANCE = type(uint128).max;
//     uint256 internal constant INIT_SUPER_TOKEN_BALANCE = type(uint128).max;
//     address constant ZERO_ADDRESS = address(0x0);

//     address internal constant alice = address(0x421);
//     address internal constant bob = address(0x422);
//     address internal constant carol = address(0x423);

//     address[] internal TEST_ACCOUNTS = [alice, bob, carol];
//     uint256 internal immutable N_TESTERS;

//     uint256 LISTING_DATE = block.timestamp;
//     uint constant PRIMARY_POOL = 0;
//     string constant POOL_NAME = "Test1";
//     uint constant LISTING_PERCENTAGE_DIVIDEND = 1;
//     uint constant LISTING_PERCENTAGE_DIVISOR = 20;
//     uint constant CLIFF_IN_DAYS = 1;
//     uint constant CLIFF_PERCENTAGE_DIVIDEND = 1;
//     uint constant CLIFF_PERCENTAGE_DIVISOR = 10;
//     uint constant VESTING_DURATION_IN_MONTHS = 3;
//     uint constant TOTAL_POOL_TOKEN_AMONUT = 1 * 10 ** 22;
//     uint constant BENEFICIARY_DEFAULT_TOKEN_AMOUNT = 200;

//     MockToken internal token;
//     WOW_Vesting internal vesting;

//     function setUp() public virtual {
//         token = new MockToken();
//         token.initialize("MOCK", "MCK", 1000);

//         for (uint256 i = 0; i < N_TESTERS; ++i) {
//             deal(TEST_ACCOUNTS[i], INIT_ETH_BALANCE);
//             token.mint(TEST_ACCOUNTS[i], INIT_SUPER_TOKEN_BALANCE);
//         }
//     }

//     /* ========== VESTING HELPER FUNCTIONS ========== */

//     function addOneNormalVestingPool() public {
//         vesting.addVestingPool(
//             POOL_NAME,
//             LISTING_PERCENTAGE_DIVIDEND,
//             LISTING_PERCENTAGE_DIVISOR,
//             CLIFF_IN_DAYS,
//             CLIFF_PERCENTAGE_DIVIDEND,
//             CLIFF_PERCENTAGE_DIVISOR,
//             VESTING_DURATION_IN_MONTHS,
//             WOW_Vesting.UnlockTypes.MONTHLY,
//             TOTAL_POOL_TOKEN_AMONUT
//         );
//     }

//     function checkPoolState(uint poolIndex) public {
//         (
//             string memory name,
//             uint listingPercentageDividend,
//             uint listingPercentageDivisor,
//             uint cliffPercentageDividend,
//             uint cliffPercentageDivisor,
//             WOW_Vesting.UnlockTypes unlockType,
//             uint totalPoolTokenAmount
//         ) = vesting.getPoolData(poolIndex);

//         (
//             uint cliffInDays,
//             uint cliffEndDate,
//             uint vestingDurationInDays,
//             uint vestingDurationInMonths,
//             uint vestingEndDate
//         ) = vesting.getPoolDates(poolIndex);

//         uint listingDate = vesting.getListingDate();
//         uint unlockedPoolTokens = vesting.getTotalUnlockedPoolTokens(poolIndex);

//         assertEq(POOL_NAME, name, "POOL_NAME is incorrect");
//         assertEq(
//             LISTING_PERCENTAGE_DIVIDEND,
//             listingPercentageDividend,
//             "LISTING_PERCENTAGE_DIVIDEND is incorrect"
//         );
//         assertEq(
//             LISTING_PERCENTAGE_DIVISOR,
//             listingPercentageDivisor,
//             "LISTING_PERCENTAGE_DIVISOR is incorrect"
//         );
//         assertEq(
//             CLIFF_PERCENTAGE_DIVIDEND,
//             cliffPercentageDividend,
//             "CLIFF_PERCENTAGE_DIVIDEND is incorrect"
//         );
//         assertEq(
//             CLIFF_PERCENTAGE_DIVISOR,
//             cliffPercentageDivisor,
//             "CLIFF_PERCENTAGE_DIVISOR is incorrect"
//         );
//         assertEq(
//             TOTAL_POOL_TOKEN_AMONUT,
//             totalPoolTokenAmount,
//             "TOTAL_POOL_TOKEN_AMONUT is incorrect"
//         );
//         assertEq(
//             VESTING_DURATION_IN_MONTHS,
//             vestingDurationInMonths,
//             "vestingDurationInMonths is incorrect"
//         );
//         assertEq(
//             vestingDurationInDays,
//             30 * vestingDurationInMonths,
//             "vestingDurationInDays is incorrect"
//         );
//         assertEq(
//             vestingEndDate,
//             cliffEndDate + 24 * 3600 * 30 * vestingDurationInMonths,
//             "vestingEndDate is incorrect"
//         );
//         assertEq(
//             TOTAL_POOL_TOKEN_AMONUT,
//             unlockedPoolTokens,
//             "unlockedPoolTokens is incorrect"
//         );
//         assertEq(
//             cliffEndDate,
//             listingDate + 24 * 3600 * cliffInDays,
//             "cliffEndDate is incorrect"
//         );
//     }

//     function checkBeneficiaryState(
//         uint poolIndex,
//         address beneficiary,
//         uint amount,
//         uint calculatedClaimedAmount
//     ) public {
//         (
//             uint totalTokens,
//             uint listingTokenAmount,
//             uint cliffTokenAmount,
//             uint vestedTokenAmount,
//             uint claimedTotalTokenAmount
//         ) = vesting.getBeneficiaryInformation(poolIndex, beneficiary);

//         uint calculatedListingTokenAmount = (amount *
//             LISTING_PERCENTAGE_DIVIDEND) / LISTING_PERCENTAGE_DIVISOR;
//         uint calculateCliffTokenAmount = (amount * CLIFF_PERCENTAGE_DIVIDEND) /
//             CLIFF_PERCENTAGE_DIVISOR;
//         uint calculatedVestedTokenAmount = amount -
//             listingTokenAmount -
//             cliffTokenAmount;

//         assertEq(amount, totalTokens, "totalTokens is incorrect.");
//         assertEq(
//             calculatedListingTokenAmount,
//             listingTokenAmount,
//             "listingTokenAmount is incorrect"
//         );
//         assertEq(
//             calculateCliffTokenAmount,
//             cliffTokenAmount,
//             "cliffTokenAmount is incorrect"
//         );
//         assertEq(
//             calculatedVestedTokenAmount,
//             vestedTokenAmount,
//             "vestedTokenAmount is incorrect"
//         );
//         assertEq(
//             calculatedClaimedAmount,
//             claimedTotalTokenAmount,
//             "claimedTotalTokenAmount is incorrect"
//         );
//     }
// }
