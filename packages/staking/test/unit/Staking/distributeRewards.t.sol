// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_DistributeRewards_Unit_Test is Unit_Test {
    function test_distributeRewards_RevertIf_CallerNotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                GELATO_EXECUTOR_ROLE
            )
        );
        vm.prank(alice);
        staking.distributeRewards(usdtToken, STAKERS, DISTRIBUTION_REWARDS);
    }

    function test_distributeRewards_RevertIf_TokenForDistributionNotSupported()
        external
    {
        vm.expectRevert(Errors.Staking__NonExistantToken.selector);
        vm.prank(admin);
        staking.distributeRewards(wowToken, STAKERS, DISTRIBUTION_REWARDS);
    }

    function test_distributeRewards_RevertIf_StakersAndRewardsLengthsMismatch()
        external
    {
        // Remove one reward amount
        DISTRIBUTION_REWARDS.pop();

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__MismatchedArrayLengths.selector,
                5,
                4
            )
        );
        vm.prank(admin);
        staking.distributeRewards(usdtToken, STAKERS, DISTRIBUTION_REWARDS);
    }

    function test_distributeRewards_IncreasesUnclaimedRewardsForFirstTime()
        external
        createDistribution
    {
        (uint256 aliceRewardsBefore, ) = staking.getStakerReward(
            alice,
            usdtToken
        );
        (uint256 bobRewardsBefore, ) = staking.getStakerReward(bob, usdtToken);
        (uint256 carolRewardsBefore, ) = staking.getStakerReward(
            carol,
            usdtToken
        );
        (uint256 danRewardsBefore, ) = staking.getStakerReward(dan, usdtToken);
        (uint256 eveRewardsBefore, ) = staking.getStakerReward(eve, usdtToken);

        vm.prank(admin);
        staking.distributeRewards(usdtToken, STAKERS, DISTRIBUTION_REWARDS);

        (uint256 aliceRewardsAfter, ) = staking.getStakerReward(
            alice,
            usdtToken
        );
        (uint256 bobRewardsAfter, ) = staking.getStakerReward(bob, usdtToken);
        (uint256 carolRewardsAfter, ) = staking.getStakerReward(
            carol,
            usdtToken
        );
        (uint256 danRewardsAfter, ) = staking.getStakerReward(dan, usdtToken);
        (uint256 eveRewardsAfter, ) = staking.getStakerReward(eve, usdtToken);

        assertEq(
            aliceRewardsBefore + DISTRIBUTION_REWARDS[0],
            aliceRewardsAfter,
            "Alice DISTRIBUTION_REWARDS not increased"
        );
        assertEq(
            bobRewardsBefore + DISTRIBUTION_REWARDS[1],
            bobRewardsAfter,
            "Bob DISTRIBUTION_REWARDS not increased"
        );
        assertEq(
            carolRewardsBefore + DISTRIBUTION_REWARDS[2],
            carolRewardsAfter,
            "Carol DISTRIBUTION_REWARDS not increased"
        );
        assertEq(
            danRewardsBefore + DISTRIBUTION_REWARDS[3],
            danRewardsAfter,
            "Dan DISTRIBUTION_REWARDS not increased"
        );
        assertEq(
            eveRewardsBefore + DISTRIBUTION_REWARDS[4],
            eveRewardsAfter,
            "Eve DISTRIBUTION_REWARDS not increased"
        );
    }

    function test_distributeRewards_IncreasesUnclaimedRewardsForSecondTime()
        external
        createDistribution
        createDistribution
    {
        (uint256 aliceRewardsBefore, ) = staking.getStakerReward(
            alice,
            usdtToken
        );
        (uint256 bobRewardsBefore, ) = staking.getStakerReward(bob, usdtToken);
        (uint256 carolRewardsBefore, ) = staking.getStakerReward(
            carol,
            usdtToken
        );
        (uint256 danRewardsBefore, ) = staking.getStakerReward(dan, usdtToken);
        (uint256 eveRewardsBefore, ) = staking.getStakerReward(eve, usdtToken);

        vm.startPrank(admin);
        staking.distributeRewards(usdtToken, STAKERS, DISTRIBUTION_REWARDS);
        staking.distributeRewards(usdtToken, STAKERS, DISTRIBUTION_REWARDS);
        vm.stopPrank();

        (uint256 aliceRewardsAfter, ) = staking.getStakerReward(
            alice,
            usdtToken
        );
        (uint256 bobRewardsAfter, ) = staking.getStakerReward(bob, usdtToken);
        (uint256 carolRewardsAfter, ) = staking.getStakerReward(
            carol,
            usdtToken
        );
        (uint256 danRewardsAfter, ) = staking.getStakerReward(dan, usdtToken);
        (uint256 eveRewardsAfter, ) = staking.getStakerReward(eve, usdtToken);

        assertEq(
            aliceRewardsBefore + DISTRIBUTION_REWARDS[0] * 2,
            aliceRewardsAfter,
            "Alice DISTRIBUTION_REWARDS not increased"
        );
        assertEq(
            bobRewardsBefore + DISTRIBUTION_REWARDS[1] * 2,
            bobRewardsAfter,
            "Bob DISTRIBUTION_REWARDS not increased"
        );
        assertEq(
            carolRewardsBefore + DISTRIBUTION_REWARDS[2] * 2,
            carolRewardsAfter,
            "Carol DISTRIBUTION_REWARDS not increased"
        );
        assertEq(
            danRewardsBefore + DISTRIBUTION_REWARDS[3] * 2,
            danRewardsAfter,
            "Dan DISTRIBUTION_REWARDS not increased"
        );
        assertEq(
            eveRewardsBefore + DISTRIBUTION_REWARDS[4] * 2,
            eveRewardsAfter,
            "Eve DISTRIBUTION_REWARDS not increased"
        );
    }

    function test_distributionRewards_EmitsRewardsDistributedEvent()
        external
        createDistribution
    {
        vm.expectEmit(address(staking));
        emit RewardsDistributed(usdtToken);

        vm.prank(admin);
        staking.distributeRewards(usdtToken, STAKERS, DISTRIBUTION_REWARDS);
    }
}
