// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../contracts/libraries/Errors.sol";
import {Base_Test} from "../Base.t.sol";
import {IStaking} from "../../contracts/interfaces/IStaking.sol";

contract Staking_E2E_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        ASSERTS
    //////////////////////////////////////////////////////////////////////////*/
    function assertStaked(
        address staker,
        uint256 bandId,
        uint16 bandLevel,
        uint256 timestamp
    ) internal {
        (
            IStaking.StakingTypes stakingType,
            ,
            address owner,
            uint16 bandLevel,
            uint256 stakingStartTimestamp,
            ,

        ) = staking.getStakerBandData(bandId);

        assertEq(
            uint8(stakingType),
            uint8(STAKING_TYPE_FLEXI),
            "Staking type not set"
        );
        assertEq(owner, staker, "Owner not set");
        assertEq(bandLevel, bandLevel, "Band Level not set");
        assertEq(stakingStartTimestamp, timestamp, "Timestamp not set");
    }

    function assertUnstaked(uint256 bandId) internal {
        (
            IStaking.StakingTypes stakingType,
            ,
            address owner,
            uint16 bandLevel,
            uint256 stakingStartTimestamp,
            ,

        ) = staking.getStakerBandData(bandId);

        assertEq(uint8(stakingType), 0, "Staking type not removed");
        assertEq(owner, address(0), "Owner not removed");
        assertEq(bandLevel, 0, "Band Level not removed");
        assertEq(stakingStartTimestamp, 0, "Timestamp not removed");
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

    /*//////////////////////////////////////////////////////////////////////////
                                STAKING TESTS
    //////////////////////////////////////////////////////////////////////////*/
    function test_With2Users_Stake_Wait_Unstake() external setBandLevelData {
        /**
         * 1. Alice stakes to level 3 band
         * 2. Bob stakes to level 6 band
         * 3. Both users wait
         * 4. Alice unstakes
         * 5. Bob unstakes
         */

        // ARRANGE + ACT
        uint256 alicePreUnstakingBalance = wowToken.balanceOf(alice);
        uint256 bobPreUnstakingBalance = wowToken.balanceOf(bob);

        uint256 firstBandId = staking.getNextBandId();
        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_3_PRICE);
        staking.stake(STAKING_TYPE_FLEXI, BAND_LEVEL_3);
        vm.stopPrank();

        uint256 secondBandId = staking.getNextBandId();
        vm.startPrank(bob);
        wowToken.approve(address(staking), BAND_6_PRICE);
        staking.stake(STAKING_TYPE_FLEXI, BAND_LEVEL_6);
        vm.stopPrank();

        vm.warp(MONTH);

        vm.prank(alice);
        staking.unstake(firstBandId);
        vm.prank(bob);
        staking.unstake(secondBandId);

        uint256 alicePostUnstakingBalance = wowToken.balanceOf(alice);
        uint256 bobPostUnstakingBalance = wowToken.balanceOf(bob);
        uint256 stakingPostUnstakingBalance = wowToken.balanceOf(
            address(staking)
        );

        // ASSERT
        assertBalances(
            stakingPostUnstakingBalance,
            0,
            bobPostUnstakingBalance,
            bobPreUnstakingBalance,
            alicePostUnstakingBalance,
            alicePreUnstakingBalance
        );

        assertUnstaked(firstBandId);
        assertUnstaked(secondBandId);
    }

    function test_With2Users_Stake_Wait_OnlyOneUnstakes()
        external
        setBandLevelData
    {
        /**
         * 1. Alice stakes to level 3 band
         * 2. Bob stakes to level 6 band
         * 3. Bot users wait
         * 4. Bob unstakes
         */

        // ARRANGE + ACT
        uint256 alicePreStakingBalance = wowToken.balanceOf(alice);
        uint256 bobPreUnstakingBalance = wowToken.balanceOf(bob);

        uint256 firstBandId = staking.getNextBandId();
        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_3_PRICE);
        staking.stake(STAKING_TYPE_FLEXI, BAND_LEVEL_3);
        vm.stopPrank();

        uint256 secondBandId = staking.getNextBandId();
        vm.startPrank(bob);
        wowToken.approve(address(staking), BAND_6_PRICE);
        staking.stake(STAKING_TYPE_FLEXI, BAND_LEVEL_6);
        vm.stopPrank();

        vm.warp(MONTH);

        vm.prank(bob);
        staking.unstake(secondBandId);

        uint256 alicePostStakingBalance = wowToken.balanceOf(alice);
        uint256 bobPostUnstakingBalance = wowToken.balanceOf(bob);
        uint256 stakingPostUnstakingBalance = wowToken.balanceOf(
            address(staking)
        );

        // ASSERT
        assertBalances(
            stakingPostUnstakingBalance,
            BAND_3_PRICE,
            bobPostUnstakingBalance,
            bobPreUnstakingBalance,
            alicePostStakingBalance + BAND_3_PRICE,
            alicePreStakingBalance
        );

        assertStaked(alice, firstBandId, BAND_LEVEL_3, 1);
        assertUnstaked(secondBandId);
    }

    function test_With2Users_Stake_UpgradeBand_Unstake()
        external
        setBandLevelData
    {
        /**
         * 1. Alice stakes to level 3 band
         * 2. Bob stakes to level 6 band
         * 3. Alice upgrades band
         * 4. Bob upgrades band
         * 5. Alice unstakes
         * 6. Bob unstakes
         */

        // ARRANGE + ACT
        uint256 alicePreStakingBalance = wowToken.balanceOf(alice);
        uint256 bobPreUnstakingBalance = wowToken.balanceOf(bob);

        uint256 firstBandId = staking.getNextBandId();
        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_3_PRICE);
        staking.stake(STAKING_TYPE_FLEXI, BAND_LEVEL_3);
        vm.stopPrank();

        uint256 secondBandId = staking.getNextBandId();
        vm.startPrank(bob);
        wowToken.approve(address(staking), BAND_6_PRICE);
        staking.stake(STAKING_TYPE_FLEXI, BAND_LEVEL_6);
        vm.stopPrank();

        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_8_PRICE - BAND_3_PRICE);
        staking.upgradeBand(firstBandId, BAND_LEVEL_8);
        vm.stopPrank();

        vm.startPrank(bob);
        wowToken.approve(address(staking), BAND_9_PRICE - BAND_6_PRICE);
        staking.upgradeBand(secondBandId, BAND_LEVEL_9);
        vm.stopPrank();

        vm.prank(alice);
        staking.unstake(firstBandId);
        vm.prank(bob);
        staking.unstake(secondBandId);

        uint256 alicePostStakingBalance = wowToken.balanceOf(alice);
        uint256 bobPostUnstakingBalance = wowToken.balanceOf(bob);
        uint256 stakingPostUnstakingBalance = wowToken.balanceOf(
            address(staking)
        );
        // ASSERT
        assertBalances(
            stakingPostUnstakingBalance,
            0,
            bobPostUnstakingBalance,
            bobPreUnstakingBalance,
            alicePostStakingBalance,
            alicePreStakingBalance
        );

        assertUnstaked(firstBandId);
        assertUnstaked(secondBandId);
    }

    function test_With2Users_Stake_UpgradeAndDowngradeBand_StakeAndUnstake()
        external
        setBandLevelData
    {
        /**
         * 1. Alice stakes to level 3 band
         * 2. Bob stakes to level 6 band
         * 3. Alice upgrades band
         * 4. Bob downgrades band
         * 5. Alice unstakes
         */

        // ARRANGE + ACT
        uint256 alicePreStakingBalance = wowToken.balanceOf(alice);
        uint256 bobPreUnstakingBalance = wowToken.balanceOf(bob);

        uint256 firstBandId = staking.getNextBandId();
        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_3_PRICE);
        staking.stake(STAKING_TYPE_FLEXI, BAND_LEVEL_3);
        vm.stopPrank();

        uint256 secondBandId = staking.getNextBandId();
        vm.startPrank(bob);
        wowToken.approve(address(staking), BAND_6_PRICE);
        staking.stake(STAKING_TYPE_FLEXI, BAND_LEVEL_6);
        vm.stopPrank();

        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_8_PRICE - BAND_3_PRICE);
        staking.upgradeBand(firstBandId, BAND_LEVEL_8);
        vm.stopPrank();

        vm.prank(bob);
        staking.downgradeBand(secondBandId, BAND_LEVEL_1);

        vm.prank(alice);
        staking.unstake(firstBandId);

        uint256 alicePostStakingBalance = wowToken.balanceOf(alice);
        uint256 bobPostUnstakingBalance = wowToken.balanceOf(bob);
        uint256 stakingPostUnstakingBalance = wowToken.balanceOf(
            address(staking)
        );

        // ASSERT
        assertBalances(
            stakingPostUnstakingBalance,
            BAND_1_PRICE,
            bobPostUnstakingBalance,
            bobPreUnstakingBalance - BAND_1_PRICE,
            alicePreStakingBalance,
            alicePostStakingBalance
        );

        assertUnstaked(firstBandId);
        assertStaked(bob, secondBandId, BAND_LEVEL_1, 1);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                VESTED STAKING TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_With2Users_StakeVested_Wait_Unstake()
        external
        setBandLevelData
    {
        /**
         * 1. Alice stakes to level 3 band
         * 2. Bob stakes to level 6 band
         * 3. Both users wait
         * 4. Alice unstakes
         * 5. Bob unstakes
         */

        // ARRANGE + ACT
        vm.startPrank(admin);
        staking.grantRole(DEFAULT_VESTING_ROLE, alice);
        staking.grantRole(DEFAULT_VESTING_ROLE, bob);
        vm.stopPrank();

        uint256 alicePreUnstakingBalance = wowToken.balanceOf(alice);
        uint256 bobPreUnstakingBalance = wowToken.balanceOf(bob);

        uint256 firstBandId = staking.getNextBandId();
        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_3_PRICE);
        staking.stakeVested(STAKING_TYPE_FLEXI, BAND_LEVEL_3, alice);
        vm.stopPrank();

        uint256 secondBandId = staking.getNextBandId();
        vm.startPrank(bob);
        wowToken.approve(address(staking), BAND_6_PRICE);
        staking.stakeVested(STAKING_TYPE_FLEXI, BAND_LEVEL_6, bob);
        vm.stopPrank();

        vm.warp(MONTH);

        vm.prank(alice);
        staking.unstakeVested(firstBandId, alice);
        vm.prank(bob);
        staking.unstakeVested(secondBandId, bob);

        uint256 alicePostUnstakingBalance = wowToken.balanceOf(alice);
        uint256 bobPostUnstakingBalance = wowToken.balanceOf(bob);
        uint256 stakingPostUnstakingBalance = wowToken.balanceOf(
            address(staking)
        );

        // ASSERT
        assertBalances(
            stakingPostUnstakingBalance,
            0,
            bobPostUnstakingBalance,
            bobPreUnstakingBalance,
            alicePostUnstakingBalance,
            alicePreUnstakingBalance
        );

        assertUnstaked(firstBandId);
        assertUnstaked(secondBandId);
    }

    function test_With2Users_StakeVested_Wait_OnlyOneUnstakes()
        external
        setBandLevelData
    {
        /**
         * 1. Alice stakes to level 3 band
         * 2. Bob stakes to level 6 band
         * 3. Bot users wait
         * 4. Bob unstakes
         */

        // ARRANGE + ACT
        vm.startPrank(admin);
        staking.grantRole(DEFAULT_VESTING_ROLE, alice);
        staking.grantRole(DEFAULT_VESTING_ROLE, bob);
        vm.stopPrank();
        uint256 alicePreStakingBalance = wowToken.balanceOf(alice);
        uint256 bobPreUnstakingBalance = wowToken.balanceOf(bob);

        uint256 firstBandId = staking.getNextBandId();
        vm.startPrank(alice);
        wowToken.approve(address(staking), BAND_3_PRICE);
        staking.stakeVested(STAKING_TYPE_FLEXI, BAND_LEVEL_3, alice);
        vm.stopPrank();

        uint256 secondBandId = staking.getNextBandId();
        vm.startPrank(bob);
        wowToken.approve(address(staking), BAND_6_PRICE);
        staking.stakeVested(STAKING_TYPE_FLEXI, BAND_LEVEL_6, bob);
        vm.stopPrank();

        vm.warp(MONTH);

        vm.prank(bob);
        staking.unstakeVested(secondBandId, bob);

        uint256 alicePostStakingBalance = wowToken.balanceOf(alice);
        uint256 bobPostUnstakingBalance = wowToken.balanceOf(bob);
        uint256 stakingPostUnstakingBalance = wowToken.balanceOf(
            address(staking)
        );

        // ASSERT
        assertBalances(
            stakingPostUnstakingBalance,
            0,
            bobPostUnstakingBalance,
            bobPreUnstakingBalance,
            alicePostStakingBalance,
            alicePreStakingBalance
        );

        assertStaked(alice, firstBandId, BAND_LEVEL_3, 1);
        assertUnstaked(secondBandId);
    }
}
