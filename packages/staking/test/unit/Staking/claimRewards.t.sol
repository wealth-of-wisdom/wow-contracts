// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";
import {IStaking} from "../../../contracts/interfaces/IStaking.sol";

contract Staking_ClaimRewards_Unit_Test is Unit_Test {
    function test_claimRewards_RevertIf_TokenForRewardsIsNotSupported()
        external
    {
        vm.expectRevert(Errors.Staking__NonExistantToken.selector);
        vm.prank(alice);
        staking.claimRewards(wowToken);
    }

    function test_claimRewards_RevertIf_DistributionInProgress()
        external
        setDistributionInProgress(true)
    {
        vm.expectRevert(Errors.Staking__DistributionInProgress.selector);
        vm.prank(alice);
        staking.claimRewards(usdtToken);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    USDT TOKEN
    //////////////////////////////////////////////////////////////////////////*/

    function test_claimRewards_RevertIf_USDTToken_NoRewardsToClaim() external {
        vm.expectRevert(Errors.Staking__NoRewardsToClaim.selector);
        vm.prank(alice);
        staking.claimRewards(usdtToken);
    }

    function test_claimRewards_USDTToken_UpdatesStakerRewardsDataOnce()
        external
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
    {
        vm.prank(alice);
        staking.claimRewards(usdtToken);

        (uint256 unclaimedAmount, uint256 claimedAmount) = staking
            .getStakerReward(alice, usdtToken);
        assertEq(unclaimedAmount, 0);
        assertEq(claimedAmount, ALICE_REWARDS);
    }

    function test_claimRewards_USDTToken_UpdatesStakerRewardsDataTwice()
        external
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
    {
        vm.prank(alice);
        staking.claimRewards(usdtToken);

        _createDistribution(usdtToken);
        _distributeRewards(usdtToken);

        vm.prank(alice);
        staking.claimRewards(usdtToken);

        (uint256 unclaimedAmount, uint256 claimedAmount) = staking
            .getStakerReward(alice, usdtToken);
        assertEq(unclaimedAmount, 0);
        assertEq(claimedAmount, ALICE_REWARDS * 2);
    }

    function test_claimRewards_USDTToken_TransfersTokensFromStaking()
        external
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
    {
        uint256 stakingBalanceBefore = usdtToken.balanceOf(address(staking));

        vm.prank(alice);
        staking.claimRewards(usdtToken);

        uint256 stakingBalanceAfter = usdtToken.balanceOf(address(staking));

        assertEq(
            stakingBalanceBefore - ALICE_REWARDS,
            stakingBalanceAfter,
            "Invalid staking balance"
        );
    }

    function test_claimRewards_USDTToken_TransfersTokensToStaker()
        external
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
    {
        uint256 aliceBalanceBefore = usdtToken.balanceOf(alice);

        vm.prank(alice);
        staking.claimRewards(usdtToken);

        uint256 aliceBalanceAfter = usdtToken.balanceOf(alice);

        assertEq(
            aliceBalanceBefore + ALICE_REWARDS,
            aliceBalanceAfter,
            "Invalid staker balance"
        );
    }

    function test_claimRewards_USDTToken_EmitsRewardsClaimedEvent()
        external
        createDistribution(usdtToken)
        distributeRewards(usdtToken)
    {
        vm.expectEmit(address(staking));
        emit RewardsClaimed(alice, usdtToken, ALICE_REWARDS);

        vm.prank(alice);
        staking.claimRewards(usdtToken);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    USDC TOKEN
    //////////////////////////////////////////////////////////////////////////*/

    function test_claimRewards_RevertIf_USDCToken_NoRewardsToClaim() external {
        vm.expectRevert(Errors.Staking__NoRewardsToClaim.selector);
        vm.prank(alice);
        staking.claimRewards(usdcToken);
    }

    function test_claimRewards_USDCToken_UpdatesStakerRewardsDataOnce()
        external
        createDistribution(usdcToken)
        distributeRewards(usdcToken)
    {
        vm.prank(alice);
        staking.claimRewards(usdcToken);

        (uint256 unclaimedAmount, uint256 claimedAmount) = staking
            .getStakerReward(alice, usdcToken);
        assertEq(unclaimedAmount, 0);
        assertEq(claimedAmount, ALICE_REWARDS);
    }

    function test_claimRewards_USDCToken_UpdatesStakerRewardsDataTwice()
        external
        createDistribution(usdcToken)
        distributeRewards(usdcToken)
    {
        vm.prank(alice);
        staking.claimRewards(usdcToken);

        _createDistribution(usdcToken);
        _distributeRewards(usdcToken);

        vm.prank(alice);
        staking.claimRewards(usdcToken);

        (uint256 unclaimedAmount, uint256 claimedAmount) = staking
            .getStakerReward(alice, usdcToken);
        assertEq(unclaimedAmount, 0);
        assertEq(claimedAmount, ALICE_REWARDS * 2);
    }

    function test_claimRewards_USDCToken_TransfersTokensFromStaking()
        external
        createDistribution(usdcToken)
        distributeRewards(usdcToken)
    {
        uint256 stakingBalanceBefore = usdcToken.balanceOf(address(staking));

        vm.prank(alice);
        staking.claimRewards(usdcToken);

        uint256 stakingBalanceAfter = usdcToken.balanceOf(address(staking));

        assertEq(
            stakingBalanceBefore - ALICE_REWARDS,
            stakingBalanceAfter,
            "Invalid staking balance"
        );
    }

    function test_claimRewards_USDCToken_TransfersTokensToStaker()
        external
        createDistribution(usdcToken)
        distributeRewards(usdcToken)
    {
        uint256 aliceBalanceBefore = usdcToken.balanceOf(alice);

        vm.prank(alice);
        staking.claimRewards(usdcToken);

        uint256 aliceBalanceAfter = usdcToken.balanceOf(alice);

        assertEq(
            aliceBalanceBefore + ALICE_REWARDS,
            aliceBalanceAfter,
            "Invalid staker balance"
        );
    }

    function test_claimRewards_USDCToken_EmitsRewardsClaimedEvent()
        external
        createDistribution(usdcToken)
        distributeRewards(usdcToken)
    {
        vm.expectEmit(address(staking));
        emit RewardsClaimed(alice, usdcToken, ALICE_REWARDS);

        vm.prank(alice);
        staking.claimRewards(usdcToken);
    }
}
