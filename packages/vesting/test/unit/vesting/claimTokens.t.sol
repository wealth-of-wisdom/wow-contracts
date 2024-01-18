// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
import {Errors} from "@wealth-of-wisdom/vesting/contracts/libraries/Errors.sol";
import {Vesting_Unit_Test} from "@wealth-of-wisdom/vesting/test/unit/VestingUnit.t.sol";

contract Vesting_ClaimTokens_Unit_Test is Vesting_Unit_Test {
    function test_claimTokens_RevertIf_PoolDoesNotExist() external {
        vm.expectRevert(Errors.Vesting__PoolDoesNotExist.selector);
        vesting.claimTokens(PRIMARY_POOL);
    }

    function test_claimTokens_RevertIf_SenderIsZeroAddress()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__NotBeneficiary.selector);
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

    function test_claimTokens_RevertIf_ClaimingStakedTokens()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.prank(address(staking));
        vesting.updateVestedStakedTokens(
            PRIMARY_POOL,
            alice,
            BENEFICIARY_TOKEN_AMOUNT,
            true
        );

        vm.warp(LISTING_DATE + 1 minutes);
        vm.expectRevert(Errors.Vesting__StakedTokensCanNotBeClaimed.selector);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);
    }

    function test_claimTokens_IncreasesClaimedTokensAmountWhenClaimingAfterListingDate()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            beneficiary.claimedTokenAmount,
            beneficiary.listingTokenAmount
        );
    }

    function test_claimTokens_IncreasesClaimedTokensAmountWhenClaimingAfterCliffDate()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(LISTING_DATE + CLIFF_IN_DAYS * 1 days);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            beneficiary.claimedTokenAmount,
            beneficiary.listingTokenAmount + beneficiary.cliffTokenAmount
        );
    }

    function test_claimTokens_TransfersTokensToSender()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        uint256 balanceBefore = token.balanceOf(alice);

        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);

        uint256 balanceAfter = token.balanceOf(alice);

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(balanceBefore + beneficiary.listingTokenAmount, balanceAfter);
    }

    function test_claimTokens_TransfersTokensFromVesting()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        uint256 balanceBefore = token.balanceOf(address(vesting));

        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);

        uint256 balanceAfter = token.balanceOf(address(vesting));

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(balanceBefore - beneficiary.listingTokenAmount, balanceAfter);
    }

    function test_claimTokens_EmitsTokensClaimedEvent()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );

        vm.expectEmit(true, true, true, true);
        emit TokensClaimed(PRIMARY_POOL, alice, beneficiary.listingTokenAmount);

        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);
    }
}
