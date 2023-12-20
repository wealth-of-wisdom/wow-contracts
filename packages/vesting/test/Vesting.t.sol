// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {WOW_Vesting} from "../contracts/WOW_Vesting.sol";
import {VestingTester} from "./VestingTester.sol";
import {IVesting} from "../contracts/interfaces/IVesting.sol";

contract VestingTest is VestingTester {
    event Initialized(uint8 version);

    uint32 listingDate = uint32(block.timestamp);
    uint16 primaryPool = 0;
    WOW_Vesting internal vesting;

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
            IVesting.UnlockTypes.MONTHLY,
            1 * 10 ** 22
        );
    }

    /* ========== INITIALIZE TESTS ========== */

    // function test_claimTokens_RevertIf_PoolDoesNotExist() public {
    //     vm.prank(alice);
    //     vm.expectRevert(WOW_Vesting.PoolDoesNotExist.selector);
    //     vesting.claimTokens(primaryPool);
    // }

    // function test_claimTokens_RevertIf_NotInBeneficiaryList() public {
    //     addVestingPool();
    //     vm.prank(alice);
    //     vm.expectRevert(WOW_Vesting.NotInBeneficiaryList.selector);
    //     vesting.claimTokens(primaryPool);
    // }
}
