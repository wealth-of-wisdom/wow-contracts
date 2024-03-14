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
        uint256 stakingBalance,
        uint256 bobPostStakingBalance,
        uint256 bobPreStakingBalance,
        uint256 alicePostStakingBalance,
        uint256 alicePreStakingBalance
    ) internal {
        assertEq(
            stakingBalance,
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
}
