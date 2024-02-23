// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_DistributeRewards_Unit_Test is Unit_Test {
    address[] internal stakers = [alice, bob, carol, dan, eve];
    uint256[] internal rewards = [
        DISTRIBUTION_AMOUNT / 10, // 10%
        (DISTRIBUTION_AMOUNT * 15) / 100, // 15%
        DISTRIBUTION_AMOUNT / 5, // 20%
        DISTRIBUTION_AMOUNT / 4, // 25%
        (DISTRIBUTION_AMOUNT * 3) / 10 // 30%
    ];

    function test_distributeRewards_RevertIf_CallerNotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                GELATO_EXECUTOR_ROLE
            )
        );
        vm.prank(alice);
        staking.distributeRewards(usdtToken, stakers, rewards);
    }

    function test_distributeRewards_RevertIf_TokenForDistributionNotSupported()
        external
    {
        vm.expectRevert(Errors.Staking__NonExistantToken.selector);
        vm.prank(admin);
        staking.distributeRewards(wowToken, stakers, rewards);
    }

    function test_distributeRewards_RevertIf_StakersAndRewardsLengthsMismatch()
        external
    {
        // Remove one reward amount
        rewards.pop();

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__MismatchedArrayLengths.selector,
                5,
                4
            )
        );
        vm.prank(admin);
        staking.distributeRewards(usdtToken, stakers, rewards);
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
        staking.distributeRewards(usdtToken, stakers, rewards);

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
            aliceRewardsBefore + rewards[0],
            aliceRewardsAfter,
            "Alice rewards not increased"
        );
        assertEq(
            bobRewardsBefore + rewards[1],
            bobRewardsAfter,
            "Bob rewards not increased"
        );
        assertEq(
            carolRewardsBefore + rewards[2],
            carolRewardsAfter,
            "Carol rewards not increased"
        );
        assertEq(
            danRewardsBefore + rewards[3],
            danRewardsAfter,
            "Dan rewards not increased"
        );
        assertEq(
            eveRewardsBefore + rewards[4],
            eveRewardsAfter,
            "Eve rewards not increased"
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
        staking.distributeRewards(usdtToken, stakers, rewards);
        staking.distributeRewards(usdtToken, stakers, rewards);
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
            aliceRewardsBefore + rewards[0] * 2,
            aliceRewardsAfter,
            "Alice rewards not increased"
        );
        assertEq(
            bobRewardsBefore + rewards[1] * 2,
            bobRewardsAfter,
            "Bob rewards not increased"
        );
        assertEq(
            carolRewardsBefore + rewards[2] * 2,
            carolRewardsAfter,
            "Carol rewards not increased"
        );
        assertEq(
            danRewardsBefore + rewards[3] * 2,
            danRewardsAfter,
            "Dan rewards not increased"
        );
        assertEq(
            eveRewardsBefore + rewards[4] * 2,
            eveRewardsAfter,
            "Eve rewards not increased"
        );
    }

    function test_distributionRewards_EmitsRewardsDistributedEvent()
        external
        createDistribution
    {
        vm.expectEmit(address(staking));
        emit RewardsDistributed(usdtToken);

        vm.prank(admin);
        staking.distributeRewards(usdtToken, stakers, rewards);
    }
}
