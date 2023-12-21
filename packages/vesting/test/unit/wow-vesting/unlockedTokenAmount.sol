// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {WOW_Vesting_Unit_Test} from "./WowVestingUnit.t.sol";

contract WOW_Vesting_UnlockedTokenAmount_Unit_Test is WOW_Vesting_Unit_Test {
    event Initialized(uint8 version);

    uint256 calculatedUnlockedPoolTokens =
        (BENEFICIARY_DEFAULT_TOKEN_AMOUNT * CLIFF_PERCENTAGE_DIVIDEND) /
            CLIFF_PERCENTAGE_DIVISOR +
            (BENEFICIARY_DEFAULT_TOKEN_AMOUNT * LISTING_PERCENTAGE_DIVIDEND) /
            LISTING_PERCENTAGE_DIVISOR;

    function setUp() public override {
        WOW_Vesting_Unit_Test.setUp();
        token.mint(address(vesting), INIT_SUPER_TOKEN_BALANCE);
    }

    /* ========== INITIALIZE TESTS ========== */

    function test_unlockedTokenAmount_ShouldGetUnlockedTokenAmountCorrectly()
        external
    {
        addOneNormalVestingPool();
        checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
        vesting.addBeneficiary(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_DEFAULT_TOKEN_AMOUNT
        );

        vm.warp(900000);
        assertEq(
            vesting.getUnlockedTokenAmount(PRIMARY_POOL, alice),
            calculatedUnlockedPoolTokens,
            "unlockedTokenAmount was calculated incorrectly"
        );

        vm.warp(1000000);
        assertEq(
            vesting.getUnlockedTokenAmount(PRIMARY_POOL, alice),
            calculatedUnlockedPoolTokens,
            "unlockedTokenAmount was calculated incorrectly"
        );

        //during cliff
        vm.warp(1000000);
        assertEq(
            vesting.getUnlockedTokenAmount(PRIMARY_POOL, alice),
            calculatedUnlockedPoolTokens,
            "during cliff unlockedTokenAmount was calculated incorrectly"
        );
        vm.warp(1000001);
        assertEq(
            vesting.getUnlockedTokenAmount(PRIMARY_POOL, alice),
            calculatedUnlockedPoolTokens,
            "during cliff unlockedTokenAmount was calculated incorrectly"
        );

        //TODO:
        //after cliff
        //...
        vm.warp(2000000);
        assertEq(
            vesting.getUnlockedTokenAmount(PRIMARY_POOL, alice),
            calculatedUnlockedPoolTokens,
            "after cliff unlockedTokenAmount was calculated incorrectly"
        );
    }
}
