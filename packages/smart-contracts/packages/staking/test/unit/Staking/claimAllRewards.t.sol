// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";
import {IStaking} from "../../../contracts/interfaces/IStaking.sol";

contract Staking_ClaimAllRewards_Unit_Test is Unit_Test {
    function test_claimAllRewards_RevertIf_DistributionInProgress()
        external
        setDistributionInProgress(true)
    {
        vm.expectRevert(Errors.Staking__DistributionInProgress.selector);
        vm.prank(alice);
        staking.claimAllRewards();
    }

    function test_claimAllRewards_USDTToken_UpdatesStakerRewardsDataOnce()
        external
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
    {
        vm.prank(alice);
        staking.claimAllRewards();
        (uint256 unclaimedAmount, uint256 claimedAmount) = staking
            .getStakerReward(alice, usdtToken);
        assertEq(unclaimedAmount, 0);
        assertEq(claimedAmount, ALICE_REWARDS);
    }

    function test_claimAllRewards_USDTToken_UpdatesStakerRewardsDataTwice()
        external
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
    {
        vm.prank(alice);
        staking.claimAllRewards();
        _createDistribution(usdtToken);
        _distributeRewards(usdtToken);
        vm.prank(alice);
        staking.claimAllRewards();
        (uint256 unclaimedAmount, uint256 claimedAmount) = staking
            .getStakerReward(alice, usdtToken);
        assertEq(unclaimedAmount, 0);
        assertEq(claimedAmount, ALICE_REWARDS * 2);
    }

    function test_claimAllRewards_USDTToken_TransfersTokensFromStaking()
        external
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
    {
        uint256 stakingBalanceBefore = usdtToken.balanceOf(address(staking));
        vm.prank(alice);
        staking.claimAllRewards();
        uint256 stakingBalanceAfter = usdtToken.balanceOf(address(staking));
        assertEq(
            stakingBalanceBefore - ALICE_REWARDS,
            stakingBalanceAfter,
            "Invalid staking balance"
        );
    }

    function test_claimAllRewards_USDTToken_TransfersTokensToStaker()
        external
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
    {
        uint256 aliceBalanceBefore = usdtToken.balanceOf(alice);
        vm.prank(alice);
        staking.claimAllRewards();
        uint256 aliceBalanceAfter = usdtToken.balanceOf(alice);
        assertEq(
            aliceBalanceBefore + ALICE_REWARDS,
            aliceBalanceAfter,
            "Invalid staker balance"
        );
    }

    function test_claimAllRewards_USDTToken_EmitsRewardsClaimedEvent()
        external
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
    {
        vm.expectEmit(address(staking));
        emit RewardsClaimed(alice, usdtToken, ALICE_REWARDS);
        vm.prank(alice);
        staking.claimAllRewards();
    }

    function test_claimAllRewards_USDCToken_UpdatesStakerRewardsDataOnce()
        external
        createDistribution(usdcToken)
        distributeRewards(usdcToken)
    {
        vm.prank(alice);
        staking.claimAllRewards();
        (uint256 unclaimedAmount, uint256 claimedAmount) = staking
            .getStakerReward(alice, usdcToken);
        assertEq(unclaimedAmount, 0);
        assertEq(claimedAmount, ALICE_REWARDS);
    }

    function test_claimAllRewards_USDCToken_UpdatesStakerRewardsDataTwice()
        external
        createDistribution(usdcToken)
        distributeRewards(usdcToken)
    {
        vm.prank(alice);
        staking.claimAllRewards();
        _createDistribution(usdcToken);
        _distributeRewards(usdcToken);
        vm.prank(alice);
        staking.claimAllRewards();
        (uint256 unclaimedAmount, uint256 claimedAmount) = staking
            .getStakerReward(alice, usdcToken);
        assertEq(unclaimedAmount, 0);
        assertEq(claimedAmount, ALICE_REWARDS * 2);
    }

    function test_claimAllRewards_USDCToken_TransfersTokensFromStaking()
        external
        createDistribution(usdcToken)
        distributeRewards(usdcToken)
    {
        uint256 stakingBalanceBefore = usdcToken.balanceOf(address(staking));
        vm.prank(alice);
        staking.claimAllRewards();
        uint256 stakingBalanceAfter = usdcToken.balanceOf(address(staking));
        assertEq(
            stakingBalanceBefore - ALICE_REWARDS,
            stakingBalanceAfter,
            "Invalid staking balance"
        );
    }

    function test_claimAllRewards_USDCToken_TransfersTokensToStaker()
        external
        createDistribution(usdcToken)
        distributeRewards(usdcToken)
    {
        uint256 aliceBalanceBefore = usdcToken.balanceOf(alice);
        vm.prank(alice);
        staking.claimAllRewards();
        uint256 aliceBalanceAfter = usdcToken.balanceOf(alice);
        assertEq(
            aliceBalanceBefore + ALICE_REWARDS,
            aliceBalanceAfter,
            "Invalid staker balance"
        );
    }

    function test_claimAllRewards_USDCToken_EmitsRewardsClaimedEvent()
        external
        createDistribution(usdcToken)
        distributeRewards(usdcToken)
    {
        vm.expectEmit(address(staking));
        emit RewardsClaimed(alice, usdcToken, ALICE_REWARDS);
        vm.prank(alice);
        staking.claimAllRewards();
    }

    function test_claimAllRewards_USDTandUSDCToken_UpdatesStakerRewardsDataOnce()
        external
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
        createDistribution(usdcToken)
        distributeRewards(usdcToken)
    {
        vm.prank(alice);
        staking.claimAllRewards();
        (uint256 unclaimedAmount, uint256 claimedAmount) = staking
            .getStakerReward(alice, usdcToken);
        assertEq(unclaimedAmount, 0);
        assertEq(claimedAmount, ALICE_REWARDS);

        (unclaimedAmount, claimedAmount) = staking.getStakerReward(
            alice,
            usdtToken
        );
        assertEq(unclaimedAmount, 0);
        assertEq(claimedAmount, ALICE_REWARDS);
    }

    function test_claimAllRewards_USDTandUSDCToken_UpdatesStakerRewardsDataTwice()
        external
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
        createDistribution(usdcToken)
        distributeRewards(usdcToken)
    {
        vm.prank(alice);
        staking.claimAllRewards();

        _createDistribution(usdtToken);
        _distributeRewards(usdtToken);
        _createDistribution(usdcToken);
        _distributeRewards(usdcToken);

        vm.prank(alice);
        staking.claimAllRewards();
        (uint256 unclaimedAmount, uint256 claimedAmount) = staking
            .getStakerReward(alice, usdcToken);
        assertEq(unclaimedAmount, 0);
        assertEq(claimedAmount, ALICE_REWARDS * 2);

        (unclaimedAmount, claimedAmount) = staking.getStakerReward(
            alice,
            usdtToken
        );
        assertEq(unclaimedAmount, 0);
        assertEq(claimedAmount, ALICE_REWARDS * 2);
    }

    function test_claimAllRewards_USDTandUSDCToken_TransfersTokensFromStaking()
        external
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
        createDistribution(usdcToken)
        distributeRewards(usdcToken)
    {
        uint256 stakingUsdtBalanceBefore = usdtToken.balanceOf(
            address(staking)
        );
        uint256 stakingUsdcBalanceBefore = usdcToken.balanceOf(
            address(staking)
        );
        vm.prank(alice);
        staking.claimAllRewards();
        uint256 stakingUsdcBalanceAfter = usdcToken.balanceOf(address(staking));
        uint256 stakingUsdtBalanceAfter = usdtToken.balanceOf(address(staking));
        assertEq(
            stakingUsdtBalanceBefore - ALICE_REWARDS,
            stakingUsdtBalanceAfter,
            "Invalid staking USDT balance"
        );
        assertEq(
            stakingUsdcBalanceBefore - ALICE_REWARDS,
            stakingUsdcBalanceAfter,
            "Invalid staking USDC balance"
        );
    }

    function test_claimAllRewards_USDTandUSDCToken_TransfersTokensToStaker()
        external
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
        createDistribution(usdcToken)
        distributeRewards(usdcToken)
    {
        uint256 aliceUsdtBalanceBefore = usdtToken.balanceOf(alice);
        uint256 aliceUsdcBalanceBefore = usdcToken.balanceOf(alice);
        vm.prank(alice);
        staking.claimAllRewards();
        uint256 aliceUsdtBalanceAfter = usdtToken.balanceOf(alice);
        uint256 aliceUsdcBalanceAfter = usdcToken.balanceOf(alice);
        assertEq(
            aliceUsdtBalanceBefore + ALICE_REWARDS,
            aliceUsdtBalanceAfter,
            "Invalid staker USDT balance"
        );
        assertEq(
            aliceUsdcBalanceBefore + ALICE_REWARDS,
            aliceUsdcBalanceAfter,
            "Invalid staker USDC balance"
        );
    }

    function test_claimAllRewards_USDTandUSDCToken_EmitsRewardsClaimedEvent()
        external
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
        createDistribution(usdcToken)
        distributeRewards(usdcToken)
    {
        vm.expectEmit(address(staking));
        emit RewardsClaimed(alice, usdcToken, ALICE_REWARDS);
        emit RewardsClaimed(alice, usdtToken, ALICE_REWARDS);
        vm.prank(alice);
        staking.claimAllRewards();
    }
}
