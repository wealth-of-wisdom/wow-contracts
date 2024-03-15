// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../contracts/libraries/Errors.sol";
import {Base_Test} from "../Base.t.sol";
import {IStaking} from "../../contracts/interfaces/IStaking.sol";

contract StakingAssertions is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        ASSERTS
    //////////////////////////////////////////////////////////////////////////*/
    function assertStaked(
        address staker,
        uint256 bandId,
        uint16 bandLvl,
        uint256 timestamp
    ) internal {
        (
            address owner,
            uint256 stakingStartDate,
            uint16 bandLevel,
            ,
            IStaking.StakingTypes stakingType,

        ) = staking.getStakerBand(bandId);

        assertEq(
            uint8(stakingType),
            uint8(STAKING_TYPE_FLEXI),
            "Staking type not set"
        );
        assertEq(owner, staker, "Owner not set");
        assertEq(bandLevel, bandLvl, "BandLevel Level not set");
        assertEq(stakingStartDate, timestamp, "Timestamp not set");
    }

    function assertUnstaked(uint256 bandId) internal {
        (
            address owner,
            uint256 stakingStartDate,
            uint16 bandLevel,
            ,
            IStaking.StakingTypes stakingType,

        ) = staking.getStakerBand(bandId);

        assertEq(uint8(stakingType), 0, "Staking type not removed");
        assertEq(owner, address(0), "Owner not removed");
        assertEq(bandLevel, 0, "BandLevel Level not removed");
        assertEq(stakingStartDate, 0, "Timestamp not removed");
    }

    function assertBalances(
        uint256 starterStakingBalance,
        uint256 endStakingBalance,
        uint256 bobPreStakingBalance,
        uint256 bobPostStakingBalance,
        uint256 alicePreStakingBalance,
        uint256 alicePostStakingBalance
    ) internal {
        assertEq(
            endStakingBalance,
            starterStakingBalance,
            "Staking balance incorrect"
        );
        assertEq(
            bobPostStakingBalance,
            bobPreStakingBalance,
            "Bob balance incorrect"
        );
        assertEq(
            alicePostStakingBalance,
            alicePreStakingBalance,
            "Alice balance incorrect"
        );
    }

    function assertDistributionCreated(
        uint256 adminBalanceBefore,
        uint256 stakingBalanceBefore
    ) internal {
        assertTrue(
            staking.isDistributionInProgress(),
            "Distribution status not set to in progress"
        );
        uint256 adminBalanceAfter = usdtToken.balanceOf(admin);
        uint256 stakingBalanceAfter = usdtToken.balanceOf(address(staking));

        assertEq(
            adminBalanceBefore - DISTRIBUTION_AMOUNT,
            adminBalanceAfter,
            "Admin balance not decreased"
        );
        assertEq(
            stakingBalanceBefore + DISTRIBUTION_AMOUNT,
            stakingBalanceAfter,
            "Staking balance not increased"
        );
    }

    function assertRewardsClaimed(address staker) internal {
        (uint256 unclaimedAmount, ) = staking.getStakerReward(
            staker,
            usdtToken
        );
        assertEq(unclaimedAmount, 0, "Staker claimed reward amount mismatch");
    }

    function assertRewardsDistributed(
        address[] memory stakers,
        uint256[] memory rewards
    ) internal {
        for (uint i = 0; i < stakers.length; i++) {
            (uint256 unclaimedAmount, ) = staking.getStakerReward(
                stakers[i],
                usdtToken
            );
            assertEq(
                unclaimedAmount,
                rewards[i],
                "Staker unclaimed amount mismatch after distribution"
            );
        }
        assertFalse(
            staking.isDistributionInProgress(),
            "Distribution status reset to in progress"
        );
    }

    function assertRewardData(
        address staker,
        uint256 stakerClaimedAmount,
        uint256 stakerUnclaimedAmount
    ) internal {
        (uint256 claimedAmount, uint256 unclaimedAmount) = staking
            .getStakerReward(staker, usdtToken);
        assertEq(
            claimedAmount,
            stakerClaimedAmount,
            "Staker claimed reward amount mismatch"
        );
        assertEq(
            unclaimedAmount,
            stakerUnclaimedAmount,
            "Staker unclaimed reward amount mismatch"
        );
    }
}
