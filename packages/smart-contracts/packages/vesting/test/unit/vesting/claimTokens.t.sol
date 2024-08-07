// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Vesting_ClaimTokens_Unit_Test is Unit_Test {
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

    function test_claimTokens_RevertIf_NotEnoughTokensInContract()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(address(vesting));
        wowToken.burn(TOTAL_POOL_TOKEN_AMOUNT);

        vm.expectRevert(Errors.Vesting__NotEnoughTokens.selector);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);
    }

    function test_claimTokens_RevertIf_NoAvailableTokens()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(LISTING_DATE + 1 minutes);

        vm.startPrank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FIX,
            BAND_LEVEL_3,
            MONTH_1,
            PRIMARY_POOL
        );
        vm.expectRevert(Errors.Vesting__NoAvailableTokens.selector);
        vesting.claimTokens(PRIMARY_POOL);
        vm.stopPrank();
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
        vm.warp(LISTING_DATE + CLIFF_IN_SECONDS);
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

    function test_claimTokens_IncreasesClaimedTokensAmountWhenClaimingAfterEndDate()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(LISTING_DATE + CLIFF_IN_SECONDS + DURATION_3_MONTHS_IN_SECONDS);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(beneficiary.claimedTokenAmount, beneficiary.totalTokenAmount);
    }

    function test_claimTokens_ClaimsAfterStaking()
        external
        approveAndAddPool
        addBeneficiary(alice)
        stakeVestedTokens(alice)
    {
        vm.warp(LISTING_DATE + CLIFF_IN_SECONDS);
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

    function test_claimTokens_ClaimsAfterStakingAndWaitingToClaimAgain()
        external
        approveAndAddPool
        addBeneficiary(alice)
        stakeVestedTokens(alice)
    {
        vm.warp(LISTING_DATE + CLIFF_IN_SECONDS);
        vm.startPrank(alice);
        vesting.claimTokens(PRIMARY_POOL);

        vm.warp(LISTING_DATE + CLIFF_IN_SECONDS + DURATION_3_MONTHS_IN_SECONDS);
        vesting.claimTokens(PRIMARY_POOL);
        vm.stopPrank();

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            beneficiary.claimedTokenAmount,
            beneficiary.totalTokenAmount - beneficiary.stakedTokenAmount
        );
    }

    function test_claimTokens_ClaimingAfterUnstaking()
        external
        approveAndAddPool
        addBeneficiary(alice)
        stakeVestedTokens(alice)
    {
        vm.warp(LISTING_DATE + CLIFF_IN_SECONDS + DURATION_3_MONTHS_IN_SECONDS);
        vm.startPrank(alice);
        vesting.unstakeVestedTokens(BAND_ID_0);
        vesting.claimTokens(PRIMARY_POOL);
        vm.stopPrank();

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(beneficiary.claimedTokenAmount, beneficiary.totalTokenAmount);
    }

    function test_claimTokens_ClaimingBeforeUnstakingAndThenClaimAgain()
        external
        approveAndAddPool
        addBeneficiary(alice)
        stakeVestedTokens(alice)
    {
        vm.warp(LISTING_DATE + CLIFF_IN_SECONDS);
        vm.startPrank(alice);
        vesting.claimTokens(PRIMARY_POOL);

        vm.warp(LISTING_DATE + CLIFF_IN_SECONDS + DURATION_3_MONTHS_IN_SECONDS);
        vesting.unstakeVestedTokens(BAND_ID_0);
        vesting.claimTokens(PRIMARY_POOL);
        vm.stopPrank();

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(beneficiary.claimedTokenAmount, beneficiary.totalTokenAmount);
    }

    function test_claimTokens_TransfersTokensToSender()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        uint256 balanceBefore = wowToken.balanceOf(alice);

        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);

        uint256 balanceAfter = wowToken.balanceOf(alice);

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
        uint256 balanceBefore = wowToken.balanceOf(address(vesting));

        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);

        uint256 balanceAfter = wowToken.balanceOf(address(vesting));

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

        vm.expectEmit(address(vesting));
        emit TokensClaimed(PRIMARY_POOL, alice, beneficiary.listingTokenAmount);

        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(alice);
        vesting.claimTokens(PRIMARY_POOL);
    }
}
