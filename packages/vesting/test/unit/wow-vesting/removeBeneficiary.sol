// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {WOW_Vesting_Unit_Test} from "./WowVestingUnit.t.sol";

contract WOW_Vesting_RemoveBeneficiary_Unit_Test is WOW_Vesting_Unit_Test {
    event Initialized(uint8 version);

    uint256 calculatedUnlockedPoolTokens =
        TOTAL_POOL_TOKEN_AMOUNT -
            (BENEFICIARY_DEFAULT_TOKEN_AMOUNT * CLIFF_PERCENTAGE_DIVIDEND) /
            CLIFF_PERCENTAGE_DIVISOR -
            (BENEFICIARY_DEFAULT_TOKEN_AMOUNT * LISTING_PERCENTAGE_DIVIDEND) /
            LISTING_PERCENTAGE_DIVISOR;

    function setUp() public override {
        WOW_Vesting_Unit_Test.setUp();
        token.mint(address(vesting), INIT_SUPER_TOKEN_BALANCE);
    }

    /* ========== INITIALIZE TESTS ========== */

    function test_removeBeneficiary_RevertIf_NotAdmin() external {
        addOneNormalVestingPool();
        checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
        vm.prank(alice);
        vm.expectRevert();
        vesting.addBeneficiary(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_DEFAULT_TOKEN_AMOUNT
        );
        vesting.removeBeneficiary(PRIMARY_POOL, alice);
    }

    function test_removeBeneficiary_RevertIf_PoolDoesNotExist() external {
        vm.expectRevert(Errors.Vesting__PoolDoesNotExist.selector);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);
    }

    function test_removeBeneficiary_RemoveDurringCliffPeriod_WhenNoTokensWereClaimed()
        external
    {
        addOneNormalVestingPool();
        checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
        vesting.addBeneficiary(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_DEFAULT_TOKEN_AMOUNT
        );
        vm.warp(1000001);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);
        checkBeneficiaryState(PRIMARY_POOL, alice, 0, 0);
        checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
    }

    function test_removeBeneficiary_RemoveDurringCliffPeriod_WhenTokensWereClaimedDurringCliff()
        external
    {
        addOneNormalVestingPool();
        checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
        vesting.addBeneficiary(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_DEFAULT_TOKEN_AMOUNT
        );
        vm.warp(1000001);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);
        checkBeneficiaryState(PRIMARY_POOL, alice, 0, 0);
        checkPoolState(PRIMARY_POOL, calculatedUnlockedPoolTokens);
    }

    function test_removeBeneficiary_RemoveDurringBegginingOfVesting_WhenNoTokensWereClaimed()
        external
    {
        addOneNormalVestingPool();
        checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
        vesting.addBeneficiary(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_DEFAULT_TOKEN_AMOUNT
        );
        vm.warp(1000000);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);
        checkBeneficiaryState(PRIMARY_POOL, alice, 0, 0);
        checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
    }

    function test_removeBeneficiary_RemoveDurringBegginingOfVesting_WhenTokensWereClaimedDurringCliff()
        external
    {
        addOneNormalVestingPool();
        checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
        vesting.addBeneficiary(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_DEFAULT_TOKEN_AMOUNT
        );
        vm.warp(1000001);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);
        checkBeneficiaryState(PRIMARY_POOL, alice, 0, 0);
        checkPoolState(PRIMARY_POOL, calculatedUnlockedPoolTokens);
    }

    function test_removeBeneficiary_RemoveDurringVesting_WhenNoTokensWereClaimed()
        external
    {
        addOneNormalVestingPool();
        checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
        vesting.addBeneficiary(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_DEFAULT_TOKEN_AMOUNT
        );
        vesting.removeBeneficiary(PRIMARY_POOL, alice);
        checkBeneficiaryState(PRIMARY_POOL, alice, 0, 0);
        checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
    }

    function test_removeBeneficiary_RemoveDurringVesting_WhenTokensWereClaimedDurringCliff()
        external
    {
        addOneNormalVestingPool();
        checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
        vesting.addBeneficiary(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_DEFAULT_TOKEN_AMOUNT
        );
        vm.warp(1000001);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);
        vm.warp(2);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);
        checkBeneficiaryState(PRIMARY_POOL, alice, 0, 0);
        checkPoolState(PRIMARY_POOL, calculatedUnlockedPoolTokens);
    }

    function test_removeBeneficiary_CantNotClaimTokensAfterBeneficiaryRemoval()
        external
    {
        addOneNormalVestingPool();
        checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
        vesting.addBeneficiary(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_DEFAULT_TOKEN_AMOUNT
        );
        vm.warp(1000001);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);
        vm.prank(alice);
        vm.expectRevert(Errors.Vesting__NotInBeneficiaryList.selector);
        vesting.claimTokens(PRIMARY_POOL);
    }
}
