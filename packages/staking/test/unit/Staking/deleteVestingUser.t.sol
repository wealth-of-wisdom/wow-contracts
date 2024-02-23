// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";
import {IStaking} from "../../../contracts/interfaces/IStaking.sol";

contract Staking_DeleteVestingUser_Unit_Test is Unit_Test {
    function test_deleteVestingUser_RevertIf_CallerNotVestingContract()
        external
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                VESTING_ROLE
            )
        );
        vm.prank(alice);
        staking.deleteVestingUser(alice);
    }

    function test_deleteVestingUser_RevertIf_UserIsZeroAddress() external {
        vm.expectRevert(Errors.Staking__ZeroAddress.selector);
        vm.prank(address(vesting));
        staking.deleteVestingUser(ZERO_ADDRESS);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    FLEXI STAKING
    //////////////////////////////////////////////////////////////////////////*/

    function test_deleteVestingUser_FlexiType_Deletes1StakerBandData()
        external
        setBandLevelData
        setSharesInMonth
        stakeVestedTokens(STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        vm.prank(address(vesting));
        staking.deleteVestingUser(alice);

        (
            address owner,
            uint32 stakingStartDate,
            uint16 bandLevel,
            uint8 fixedMonths,
            IStaking.StakingTypes stakingType,
            bool areTokensVested
        ) = staking.getStakerBand(BAND_ID_0);

        assertEq(owner, ZERO_ADDRESS, "Owner not removed");
        assertEq(stakingStartDate, 0, "Timestamp not removed");
        assertEq(uint8(stakingType), 0, "Staking type not removed");
        assertEq(bandLevel, 0, "BandLevel Level not removed");
        assertEq(fixedMonths, 0, "Fixed months not removed");
        assertEq(areTokensVested, false, "Vesting status not removed");
    }

    function test_deleteVestingUser_FlexiType_Deletes3StakerBandsData()
        external
        setBandLevelData
        setSharesInMonth
        stakeVestedTokens(STAKING_TYPE_FLEXI, BAND_LEVEL_1, MONTH_0)
        stakeVestedTokens(STAKING_TYPE_FLEXI, BAND_LEVEL_5, MONTH_0)
        stakeVestedTokens(STAKING_TYPE_FLEXI, BAND_LEVEL_9, MONTH_0)
    {
        vm.prank(address(vesting));
        staking.deleteVestingUser(alice);

        (
            address owner,
            uint32 stakingStartDate,
            uint16 bandLevel,
            uint8 fixedMonths,
            IStaking.StakingTypes stakingType,
            bool areTokensVested
        ) = staking.getStakerBand(BAND_ID_0);

        assertEq(owner, ZERO_ADDRESS, "Owner not removed");
        assertEq(stakingStartDate, 0, "Timestamp not removed");
        assertEq(uint8(stakingType), 0, "Staking type not removed");
        assertEq(bandLevel, 0, "BandLevel Level not removed");
        assertEq(fixedMonths, 0, "Fixed months not removed");
        assertEq(areTokensVested, false, "Vesting status not removed");

        (
            owner,
            stakingStartDate,
            bandLevel,
            fixedMonths,
            stakingType,
            areTokensVested
        ) = staking.getStakerBand(BAND_ID_1);

        assertEq(owner, ZERO_ADDRESS, "Owner not removed");
        assertEq(stakingStartDate, 0, "Timestamp not removed");
        assertEq(uint8(stakingType), 0, "Staking type not removed");
        assertEq(bandLevel, 0, "BandLevel Level not removed");
        assertEq(fixedMonths, 0, "Fixed months not removed");
        assertEq(areTokensVested, false, "Vesting status not removed");

        (
            owner,
            stakingStartDate,
            bandLevel,
            fixedMonths,
            stakingType,
            areTokensVested
        ) = staking.getStakerBand(BAND_ID_2);

        assertEq(owner, ZERO_ADDRESS, "Owner not removed");
        assertEq(stakingStartDate, 0, "Timestamp not removed");
        assertEq(uint8(stakingType), 0, "Staking type not removed");
        assertEq(bandLevel, 0, "BandLevel Level not removed");
        assertEq(fixedMonths, 0, "Fixed months not removed");
        assertEq(areTokensVested, false, "Vesting status not removed");
    }

    // @todo continue from here

    function test_deleteVestingUser_FlexiType_EmitsVestingUserDeletedEvent()
        external
        setBandLevelData
        stakeVestedTokens(STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        vm.expectEmit(address(staking));
        emit VestingUserDeleted(alice);

        vm.prank(address(vesting));
        staking.deleteVestingUser(alice);
    }
}
