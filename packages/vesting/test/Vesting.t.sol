// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

//ignore
import {Vm} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {WOW_Vesting} from "../contracts/WOW_Vesting.sol";
import {VestingTester} from "./VestingTester.sol";

contract VestingTest is VestingTester {
    event Initialized(uint8 version);

    uint256 listingDate = block.timestamp;
    WOW_Vesting internal vesting;

    constructor() {}

    function setUp() public override {
        super.setUp();

        vesting = new WOW_Vesting();
        vesting.initialize(token, listingDate);
    }

    /* ========== VESTING HELPER FUNCTIONS ========== */

    function addVestingPool() public {
        vesting.addVestingPool(
            "Test1",
            1,
            20,
            1,
            1,
            10,
            3,
            WOW_Vesting.UnlockTypes.MONTHLY,
            1 * 10 ** 22
        );
    }

    /* ========== INITIALIZE TESTS ========== */

    function test_claimTokens_RevertIf_PoolDoesNotExist() public {
        vm.prank(alice);
        vm.expectRevert(WOW_Vesting.PoolDoesNotExist.selector);
        vesting.claimTokens(0);
    }

    function test_claimTokens_RevertIf_NotInBeneficiaryList() public {
        addVestingPool();
        vm.prank(alice);
        vm.expectRevert(WOW_Vesting.NotInBeneficiaryList.selector);
        vesting.claimTokens(0);
    }
}
