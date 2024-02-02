// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {StakingMock} from "../../mocks/StakingMock.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_SetBand_Unit_Test is Unit_Test {
    modifier setBandId1() {
        vm.prank(admin);
        staking.setBand(
            BAND_ID_1,
            BAND_1_PRICE,
            BAND_1_ACCESSIBLE_POOLS,
            BAND_1_STAKING_TIMESPAN
        );
        _;
    }

    function test_setBand_RevertIf_NotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        staking.setBand(
            BAND_ID_1,
            BAND_1_PRICE,
            BAND_1_ACCESSIBLE_POOLS,
            BAND_1_STAKING_TIMESPAN
        );
    }

    function test_setBand_RevertIf_BandIdIsZero() external {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Staking__InvalidBandId.selector, 0)
        );
        vm.prank(admin);
        staking.setBand(
            0,
            BAND_1_PRICE,
            BAND_1_ACCESSIBLE_POOLS,
            BAND_1_STAKING_TIMESPAN
        );
    }

    function test_setBand_RevertIf_BandIdIsGreaterThanMaxBands() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InvalidBandId.selector,
                TOTAL_BANDS + 1
            )
        );
        vm.prank(admin);
        staking.setBand(
            TOTAL_BANDS + 1,
            BAND_1_PRICE,
            BAND_1_ACCESSIBLE_POOLS,
            BAND_1_STAKING_TIMESPAN
        );
    }

    function test_setBand_RevertIf_BandPriceIsZero() external {
        vm.expectRevert(Errors.Staking__ZeroAmount.selector);
        vm.prank(admin);
        staking.setBand(
            BAND_ID_1,
            0,
            BAND_1_ACCESSIBLE_POOLS,
            BAND_1_STAKING_TIMESPAN
        );
    }

    function test_setBand_RevertIf_AccessiblePoolsArrayIsTooLarge() external {
        vm.expectRevert(Errors.Staking__MaximumLevelExceeded.selector);
        vm.prank(admin);
        staking.setBand(
            BAND_ID_1,
            BAND_1_PRICE,
            new uint16[](10),
            BAND_1_STAKING_TIMESPAN
        );
    }

    function test_setBand_RevertIf_StakingTimespanIsZero() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InvalidStaingTimespan.selector,
                0
            )
        );
        vm.prank(admin);
        staking.setBand(BAND_ID_1, BAND_1_PRICE, BAND_1_ACCESSIBLE_POOLS, 0);
    }

    function test_setBand_SetsBandData() external setBandId1 {
        (
            uint256 price,
            uint16[] memory accessiblePools,
            uint256 stakingTimespan
        ) = staking.getBand(BAND_ID_1);
        uint256 poolsAmount = accessiblePools.length;

        assertEq(price, BAND_1_PRICE);
        assertEq(stakingTimespan, BAND_1_STAKING_TIMESPAN);

        for (uint256 i = 0; i < poolsAmount; i++) {
            assertEq(accessiblePools[i], BAND_1_ACCESSIBLE_POOLS[i]);
        }
    }

    function test_setBand_EmitsBandSetEvent() external {
        vm.expectEmit(address(staking));
        emit BandSet(BAND_ID_1);

        vm.prank(admin);
        staking.setBand(
            BAND_ID_1,
            BAND_1_PRICE,
            BAND_1_ACCESSIBLE_POOLS,
            BAND_1_STAKING_TIMESPAN
        );
    }
}
