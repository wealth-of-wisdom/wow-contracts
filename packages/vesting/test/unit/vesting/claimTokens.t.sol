// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Vesting_Unit_Test} from "./VestingUnit.t.sol";

contract Vesting_ClaimTokens_Unit_Test is Vesting_Unit_Test {
    function test_claimTokens_RevertIf_PoolDoesNotExist() external {
        vm.expectRevert(Errors.Vesting__PoolDoesNotExist.selector);
        vesting.claimTokens(PRIMARY_POOL);
    }

    function test_claimTokens_RevertIf_SenderIsZeroAddress()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__ZeroAddress.selector);
        vm.prank(ZERO_ADDRESS);
        vesting.claimTokens(PRIMARY_POOL);
    }

    function test_claimTokens_ReverIf_NotBeneficiary()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__NotBeneficiary.selector);
        vesting.claimTokens(PRIMARY_POOL);
    }

    function test_claimTokens_RevertIf_NoTokensUnlocked()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.expectRevert(Errors.Vesting__NoTokensUnlocked.selector);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);
    }

    function test_claimTokens_RevertIf_NotEnoughTokens()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(address(vesting));
        token.burn(TOTAL_POOL_TOKEN_AMOUNT);

        vm.expectRevert(Errors.Vesting__NotEnoughTokens.selector);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);
    }

    // function test_claimTokens_RevertIf_ClaimingStakedTokens()
    //     external
    //     approveAndAddPool
    //     addBeneficiary(alice)
    // {
    // }

    // function test_claimTokens_IncreasesClaimedTokensAmount()
    //     external
    //     approveAndAddPool
    // {}

    // function test_claimTokens_TransfersTokensToSender()
    //     external
    //     approveAndAddPool
    // {}

    // function test_claimTokens_TransfersTokensFromVesting()
    //     external
    //     approveAndAddPool
    // {}

    // function test_claimTokens_EmitsTokensClaimedEvent()
    //     external
    //     approveAndAddPool
    // {}
}
