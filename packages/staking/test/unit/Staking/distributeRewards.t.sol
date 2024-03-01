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
        createDistribution(usdtToken)
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
            aliceRewardsBefore + ALICE_REWARDS,
            aliceRewardsAfter,
            "Alice DISTRIBUTION_REWARDS not increased"
        );
        assertEq(
            bobRewardsBefore + BOB_REWARDS,
            bobRewardsAfter,
            "Bob DISTRIBUTION_REWARDS not increased"
        );
        assertEq(
            carolRewardsBefore + CAROL_REWARDS,
            carolRewardsAfter,
            "Carol DISTRIBUTION_REWARDS not increased"
        );
        assertEq(
            danRewardsBefore + DAN_REWARDS,
            danRewardsAfter,
            "Dan DISTRIBUTION_REWARDS not increased"
        );
        assertEq(
            eveRewardsBefore + EVE_REWARDS,
            eveRewardsAfter,
            "Eve DISTRIBUTION_REWARDS not increased"
        );
    }

    function test_distributeRewards_IncreasesUnclaimedRewardsForSecondTime()
        external
        createDistribution(usdtToken)
        createDistribution(usdtToken)
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
            aliceRewardsBefore + ALICE_REWARDS * 2,
            aliceRewardsAfter,
            "Alice DISTRIBUTION_REWARDS not increased"
        );
        assertEq(
            bobRewardsBefore + BOB_REWARDS * 2,
            bobRewardsAfter,
            "Bob DISTRIBUTION_REWARDS not increased"
        );
        assertEq(
            carolRewardsBefore + CAROL_REWARDS * 2,
            carolRewardsAfter,
            "Carol DISTRIBUTION_REWARDS not increased"
        );
        assertEq(
            danRewardsBefore + DAN_REWARDS * 2,
            danRewardsAfter,
            "Dan DISTRIBUTION_REWARDS not increased"
        );
        assertEq(
            eveRewardsBefore + EVE_REWARDS * 2,
            eveRewardsAfter,
            "Eve DISTRIBUTION_REWARDS not increased"
        );
    }

    function test_distributionRewards_EmitsRewardsDistributedEvent()
        external
        createDistribution(usdtToken)
    {
        vm.expectEmit(address(staking));
        emit RewardsDistributed(usdtToken);

        vm.prank(admin);
        staking.distributeRewards(usdtToken, STAKERS, DISTRIBUTION_REWARDS);
    }
}
