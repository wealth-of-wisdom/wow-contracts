// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {WOW_Vesting} from "../contracts/WOW_Vesting.sol";
import {VestingHelper} from "./VestingHelper.sol";

contract VestingTest is VestingHelper {
    event Initialized(uint8 version);

    function setUp() public override {
        super.setUp();

        vesting = new WOW_Vesting();
        vesting.initialize(token, LISTING_DATE);
    }

    /* ========== INITIALIZE TESTS ========== */

    function test_addToBeneficiariesList_AddsBeneficiaryToPool() public {
        addOneNormalVestingPool();
        checkPoolState(PRIMARY_POOL);

        vesting.addToBeneficiariesList(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_DEFAULT_TOKEN_AMOUNT
        );
        checkBeneficiaryState(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_DEFAULT_TOKEN_AMOUNT,
            0
        );
    }

    function test_addToBeneficiariesList_RevertIf_NotAdmin() public {
        vm.prank(alice);
        vm.expectRevert();
        vesting.addToBeneficiariesList(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_DEFAULT_TOKEN_AMOUNT
        );
    }

    function test_addToBeneficiariesList_RevertIf_TokenAmonutZero() public {
        addOneNormalVestingPool();
        checkPoolState(PRIMARY_POOL);
        vm.expectRevert(WOW_Vesting.TokenAmonutZero.selector);
        vesting.addToBeneficiariesList(PRIMARY_POOL, alice, 0);
    }

    function test_addToBeneficiariesList_RevertIf_PoolDoesNotExist() public {
        vm.expectRevert(WOW_Vesting.PoolDoesNotExist.selector);
        vesting.addToBeneficiariesList(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_DEFAULT_TOKEN_AMOUNT
        );
    }

    function test_addToBeneficiariesList_RevertIf_TokenAmountExeedsTotalPoolAmount()
        public
    {
        vesting.addVestingPool(
            POOL_NAME,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_IN_DAYS,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR,
            VESTING_DURATION_IN_MONTHS,
            WOW_Vesting.UnlockTypes.MONTHLY,
            100
        );
        vm.expectRevert(WOW_Vesting.TokenAmountExeedsTotalPoolAmount.selector);
        vesting.addToBeneficiariesList(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_DEFAULT_TOKEN_AMOUNT
        );
    }

    function test_addToBeneficiariesList_CanAddToBeneficiariesListTwice()
        public
    {
        uint newAmount = 100;
        addOneNormalVestingPool();
        checkPoolState(PRIMARY_POOL);
        vesting.addToBeneficiariesList(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_DEFAULT_TOKEN_AMOUNT
        );
        vesting.addToBeneficiariesList(PRIMARY_POOL, alice, newAmount);
        checkBeneficiaryState(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_DEFAULT_TOKEN_AMOUNT + newAmount,
            0
        );
    }
}
