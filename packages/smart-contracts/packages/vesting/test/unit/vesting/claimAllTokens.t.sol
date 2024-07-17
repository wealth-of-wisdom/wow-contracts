// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Vesting_ClaimAllTokens_Unit_Test is Unit_Test {
    modifier approveAndAddTwoPools() {
        _approveAndAddPool(POOL_NAME);
        _approveAndAddPool(POOL_NAME_2);

        _;
    }

    modifier addBeneficiaryToTwoPools(address beneficiary) {
        vm.startPrank(admin);
        vesting.addBeneficiary(
            PRIMARY_POOL,
            beneficiary,
            BENEFICIARY_TOKEN_AMOUNT
        );
        vesting.addBeneficiary(
            SECONDARY_POOL,
            beneficiary,
            BENEFICIARY_TOKEN_AMOUNT * 2
        );
        vm.stopPrank();

        _;
    }

    function test_claimAllTokens_RevertIf_NoTokensUnlockedToClaim() external {
        vm.expectRevert(Errors.Vesting__NoTokensUnlocked.selector);
        vm.prank(alice);
        vesting.claimAllTokens();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  CLAIM FROM ONE POOL
    //////////////////////////////////////////////////////////////////////////*/

    function test_claimAllTokens_SinglePool_IncreasesClaimedTokensAmountWhenClaimingAfterListingDate()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(alice);
        vesting.claimAllTokens();

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            beneficiary.claimedTokenAmount,
            beneficiary.listingTokenAmount
        );
    }

    function test_claimAllTokens_SinglePool_IncreasesClaimedTokensAmountWhenClaimingAfterCliffDate()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(LISTING_DATE + CLIFF_IN_SECONDS);
        vm.prank(alice);
        vesting.claimAllTokens();

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            beneficiary.claimedTokenAmount,
            beneficiary.listingTokenAmount + beneficiary.cliffTokenAmount
        );
    }

    function test_claimAllTokens_SinglePool_IncreasesClaimedTokensAmountWhenClaimingAfterEndDate()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.warp(LISTING_DATE + CLIFF_IN_SECONDS + DURATION_3_MONTHS_IN_SECONDS);
        vm.prank(alice);
        vesting.claimAllTokens();

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(beneficiary.claimedTokenAmount, beneficiary.totalTokenAmount);
    }

    function test_claimAllTokens_SinglePool_TransfersTokensToSender()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        uint256 balanceBefore = wowToken.balanceOf(alice);

        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(alice);
        vesting.claimAllTokens();

        uint256 balanceAfter = wowToken.balanceOf(alice);

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(balanceBefore + beneficiary.listingTokenAmount, balanceAfter);
    }

    function test_claimAllTokens_SinglePool_TransfersTokensFromVesting()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        uint256 balanceBefore = wowToken.balanceOf(address(vesting));

        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(alice);
        vesting.claimAllTokens();

        uint256 balanceAfter = wowToken.balanceOf(address(vesting));

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(balanceBefore - beneficiary.listingTokenAmount, balanceAfter);
    }

    function test_claimAllTokens_SinglePool_EmitsTokensClaimedEvent()
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
        vesting.claimAllTokens();
    }

    function test_claimAllTokens_SinglePool_EmitsAllTokensClaimedEvent()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );

        vm.expectEmit(address(vesting));
        emit AllTokensClaimed(alice, beneficiary.listingTokenAmount);

        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(alice);
        vesting.claimAllTokens();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  CLAIM FROM TWO POOLS
    //////////////////////////////////////////////////////////////////////////*/

    function test_claimAllTokens_MultiplePools_IncreasesClaimedTokensAmountWhenClaimingAfterListingDate()
        external
        approveAndAddTwoPools
        addBeneficiaryToTwoPools(alice)
    {
        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(alice);
        vesting.claimAllTokens();

        IVesting.Beneficiary memory tokenData1 = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        IVesting.Beneficiary memory tokenData2 = vesting.getBeneficiary(
            SECONDARY_POOL,
            alice
        );
        assertEq(tokenData1.claimedTokenAmount, tokenData1.listingTokenAmount);
        assertEq(tokenData2.claimedTokenAmount, tokenData2.listingTokenAmount);
    }

    function test_claimAllTokens_MultiplePools_IncreasesClaimedTokensAmountWhenClaimingAfterCliffDate()
        external
        approveAndAddTwoPools
        addBeneficiaryToTwoPools(alice)
    {
        vm.warp(LISTING_DATE + CLIFF_IN_SECONDS);
        vm.prank(alice);
        vesting.claimAllTokens();

        IVesting.Beneficiary memory tokenData1 = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        IVesting.Beneficiary memory tokenData2 = vesting.getBeneficiary(
            SECONDARY_POOL,
            alice
        );
        assertEq(
            tokenData1.claimedTokenAmount,
            tokenData1.listingTokenAmount + tokenData1.cliffTokenAmount
        );
        assertEq(
            tokenData2.claimedTokenAmount,
            tokenData2.listingTokenAmount + tokenData2.cliffTokenAmount
        );
    }

    function test_claimAllTokens_MultiplePools_IncreasesClaimedTokensAmountWhenClaimingAfterEndDate()
        external
        approveAndAddTwoPools
        addBeneficiaryToTwoPools(alice)
    {
        vm.warp(LISTING_DATE + CLIFF_IN_SECONDS + DURATION_3_MONTHS_IN_SECONDS);
        vm.prank(alice);
        vesting.claimAllTokens();

        IVesting.Beneficiary memory tokenData1 = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        IVesting.Beneficiary memory tokenData2 = vesting.getBeneficiary(
            SECONDARY_POOL,
            alice
        );
        assertEq(tokenData1.claimedTokenAmount, tokenData1.totalTokenAmount);
        assertEq(tokenData2.claimedTokenAmount, tokenData2.totalTokenAmount);
    }

    function test_claimAllTokens_MultiplePools_TransfersTokensToSender()
        external
        approveAndAddTwoPools
        addBeneficiaryToTwoPools(alice)
    {
        uint256 balanceBefore = wowToken.balanceOf(alice);

        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(alice);
        vesting.claimAllTokens();

        uint256 balanceAfter = wowToken.balanceOf(alice);

        IVesting.Beneficiary memory tokenData1 = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        IVesting.Beneficiary memory tokenData2 = vesting.getBeneficiary(
            SECONDARY_POOL,
            alice
        );
        assertEq(
            balanceBefore +
                tokenData1.listingTokenAmount +
                tokenData2.listingTokenAmount,
            balanceAfter
        );
    }

    function test_claimAllTokens_MultiplePools_TransfersTokensFromVesting()
        external
        approveAndAddTwoPools
        addBeneficiaryToTwoPools(alice)
    {
        uint256 balanceBefore = wowToken.balanceOf(address(vesting));

        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(alice);
        vesting.claimAllTokens();

        uint256 balanceAfter = wowToken.balanceOf(address(vesting));

        IVesting.Beneficiary memory tokenData1 = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        IVesting.Beneficiary memory tokenData2 = vesting.getBeneficiary(
            SECONDARY_POOL,
            alice
        );
        assertEq(
            balanceBefore -
                tokenData1.listingTokenAmount -
                tokenData2.listingTokenAmount,
            balanceAfter
        );
    }

    function test_claimAllTokens_MultiplePools_SkipsPoolIfBeneficiaryStakedTokens()
        external
        approveAndAddTwoPools
        addBeneficiaryToTwoPools(alice)
    {
        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FIX,
            BAND_LEVEL_3,
            MONTH_1,
            PRIMARY_POOL
        );

        IVesting.Beneficiary memory tokenData = vesting.getBeneficiary(
            SECONDARY_POOL,
            alice
        );

        vm.expectEmit(address(vesting));
        emit AllTokensClaimed(alice, tokenData.listingTokenAmount);

        vm.prank(alice);
        vesting.claimAllTokens();
    }

    function test_claimAllTokens_MultiplePools_ClaimFromOnePool_OtherPoolUnlockedTokensZero()
        external
        approveAndAddTwoPools
        addBeneficiaryToTwoPools(alice)
    {
        uint256 balanceBefore = wowToken.balanceOf(address(vesting));

        vm.warp(LISTING_DATE + 1 minutes);
        vm.startPrank(alice);

        vesting.claimTokens(SECONDARY_POOL);
        vesting.claimAllTokens();
        vm.stopPrank();

        uint256 balanceAfter = wowToken.balanceOf(address(vesting));

        IVesting.Beneficiary memory tokenData1 = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        IVesting.Beneficiary memory tokenData2 = vesting.getBeneficiary(
            SECONDARY_POOL,
            alice
        );
        assertEq(
            balanceBefore -
                tokenData1.listingTokenAmount -
                tokenData2.listingTokenAmount,
            balanceAfter
        );
    }

    function test_claimAllTokens_MultiplePools_StakedInBoth()
        external
        approveAndAddTwoPools
        addBeneficiaryToTwoPools(alice)
        stakeVestedTokens(alice)
    {
        vm.warp(LISTING_DATE + CLIFF_IN_SECONDS + DURATION_3_MONTHS_IN_SECONDS);
        vm.startPrank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FIX,
            BAND_LEVEL_1,
            MONTH_1,
            SECONDARY_POOL
        );

        vesting.claimAllTokens();
        vm.stopPrank();

        IVesting.Beneficiary memory tokenData1 = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        IVesting.Beneficiary memory tokenData2 = vesting.getBeneficiary(
            SECONDARY_POOL,
            alice
        );
        assertEq(
            tokenData1.claimedTokenAmount,
            tokenData1.totalTokenAmount - tokenData1.stakedTokenAmount
        );
        assertEq(
            tokenData2.claimedTokenAmount,
            tokenData2.totalTokenAmount - tokenData2.stakedTokenAmount
        );
    }

    function test_claimAllTokens_MultiplePools_StakedInBoth_AwaitToClaimAfterStake()
        external
        approveAndAddTwoPools
        addBeneficiaryToTwoPools(alice)
        stakeVestedTokens(alice)
    {
        vm.warp(LISTING_DATE + CLIFF_IN_SECONDS);
        vm.startPrank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FIX,
            BAND_LEVEL_1,
            MONTH_1,
            SECONDARY_POOL
        );

        vesting.claimAllTokens();
        vm.warp(LISTING_DATE + CLIFF_IN_SECONDS + DURATION_3_MONTHS_IN_SECONDS);
        vesting.claimAllTokens();
        vm.stopPrank();

        IVesting.Beneficiary memory tokenData1 = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        IVesting.Beneficiary memory tokenData2 = vesting.getBeneficiary(
            SECONDARY_POOL,
            alice
        );
        assertEq(
            tokenData1.claimedTokenAmount,
            tokenData1.totalTokenAmount - tokenData1.stakedTokenAmount
        );
        assertEq(
            tokenData2.claimedTokenAmount,
            tokenData2.totalTokenAmount - tokenData2.stakedTokenAmount
        );
    }

    function test_claimAllTokens_MultiplePools_UnstakeInBoth_AndClaim()
        external
        approveAndAddTwoPools
        addBeneficiaryToTwoPools(alice)
        stakeVestedTokens(alice)
    {
        vm.startPrank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FIX,
            BAND_LEVEL_1,
            MONTH_1,
            SECONDARY_POOL
        );

        vm.warp(LISTING_DATE + CLIFF_IN_SECONDS + DURATION_3_MONTHS_IN_SECONDS);

        vesting.unstakeVestedTokens(BAND_ID_0);
        vesting.unstakeVestedTokens(BAND_ID_1);
        vesting.claimAllTokens();
        vm.stopPrank();

        IVesting.Beneficiary memory tokenData1 = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        IVesting.Beneficiary memory tokenData2 = vesting.getBeneficiary(
            SECONDARY_POOL,
            alice
        );
        assertEq(tokenData1.claimedTokenAmount, tokenData1.totalTokenAmount);
        assertEq(tokenData2.claimedTokenAmount, tokenData2.totalTokenAmount);
    }

    function test_claimAllTokens_MultiplePools_ClaimInBoth_UnstakeInBoth_AndClaimInOne()
        external
        approveAndAddTwoPools
        addBeneficiaryToTwoPools(alice)
        stakeVestedTokens(alice)
    {
        vm.startPrank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FIX,
            BAND_LEVEL_1,
            MONTH_1,
            SECONDARY_POOL
        );

        vm.warp(LISTING_DATE + CLIFF_IN_SECONDS);
        vesting.claimAllTokens();

        vm.warp(LISTING_DATE + CLIFF_IN_SECONDS + DURATION_3_MONTHS_IN_SECONDS);
        vesting.unstakeVestedTokens(BAND_ID_0);
        vesting.claimAllTokens();
        vm.stopPrank();

        IVesting.Beneficiary memory tokenData1 = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        IVesting.Beneficiary memory tokenData2 = vesting.getBeneficiary(
            SECONDARY_POOL,
            alice
        );
        assertEq(tokenData1.claimedTokenAmount, tokenData1.totalTokenAmount);
        assertEq(
            tokenData2.claimedTokenAmount,
            tokenData2.totalTokenAmount - tokenData2.stakedTokenAmount
        );
    }

    function test_claimAllTokens_MultiplePools_EmitsTokensClaimedEvent()
        external
        approveAndAddTwoPools
        addBeneficiaryToTwoPools(alice)
    {
        IVesting.Beneficiary memory tokenData1 = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        IVesting.Beneficiary memory tokenData2 = vesting.getBeneficiary(
            SECONDARY_POOL,
            alice
        );

        vm.expectEmit(address(vesting));
        emit TokensClaimed(PRIMARY_POOL, alice, tokenData1.listingTokenAmount);

        vm.expectEmit(address(vesting));
        emit TokensClaimed(
            SECONDARY_POOL,
            alice,
            tokenData2.listingTokenAmount
        );

        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(alice);
        vesting.claimAllTokens();
    }

    function test_claimAllTokens_MultiplePools_EmitsAllTokensClaimedEvent()
        external
        approveAndAddTwoPools
        addBeneficiaryToTwoPools(alice)
    {
        IVesting.Beneficiary memory tokenData1 = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        IVesting.Beneficiary memory tokenData2 = vesting.getBeneficiary(
            SECONDARY_POOL,
            alice
        );

        vm.expectEmit(address(vesting));
        emit AllTokensClaimed(
            alice,
            tokenData1.listingTokenAmount + tokenData2.listingTokenAmount
        );

        vm.warp(LISTING_DATE + 1 minutes);
        vm.prank(alice);
        vesting.claimAllTokens();
    }
}
