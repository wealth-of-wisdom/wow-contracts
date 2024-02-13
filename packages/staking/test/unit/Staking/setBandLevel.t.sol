// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_SetBand_Unit_Test is Unit_Test {
    function test_setBand_RevertIf_NotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        staking.setBandLevel(BAND_ID_1, BAND_1_PRICE, BAND_1_ACCESSIBLE_POOLS);
    }

    function test_setBand_RevertIf_BandLevelIsZero() external {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Staking__InvalidBandLevel.selector, 0)
        );
        vm.prank(admin);
        staking.setBandLevel(0, BAND_1_PRICE, BAND_1_ACCESSIBLE_POOLS);
    }

    function test_setBand_RevertIf_BandLevelIsGreaterThanMaxBands() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InvalidBandLevel.selector,
                TOTAL_BAND_LEVELS + 1
            )
        );
        vm.prank(admin);
        staking.setBandLevel(
            TOTAL_BAND_LEVELS + 1,
            BAND_1_PRICE,
            BAND_1_ACCESSIBLE_POOLS
        );
    }

    function test_setBand_RevertIf_BandPriceIsZero() external {
        vm.expectRevert(Errors.Staking__ZeroAmount.selector);
        vm.prank(admin);
        staking.setBandLevel(BAND_ID_1, 0, BAND_1_ACCESSIBLE_POOLS);
    }

    function test_setBand_RevertIf_AccessiblePoolsArrayIsTooLarge() external {
        vm.expectRevert(Errors.Staking__MaximumLevelExceeded.selector);
        vm.prank(admin);
        staking.setBandLevel(BAND_ID_1, BAND_1_PRICE, new uint16[](10));
    }

    function test_setBand_SetsBandData() external {
        vm.prank(admin);
        staking.setBandLevel(BAND_ID_1, BAND_1_PRICE, BAND_1_ACCESSIBLE_POOLS);

        (uint256 price, uint16[] memory accessiblePools) = staking.getBand(
            BAND_ID_1
        );
        uint256 poolsAmount = accessiblePools.length;

        assertEq(price, BAND_1_PRICE);

        for (uint256 i = 0; i < poolsAmount; i++) {
            assertEq(accessiblePools[i], BAND_1_ACCESSIBLE_POOLS[i]);
        }
    }

    function test_setBand_EmitsBandLevelSetEvent() external {
        vm.expectEmit(address(staking));
        emit BandLevelSet(BAND_ID_1, BAND_1_PRICE, BAND_1_ACCESSIBLE_POOLS);

        vm.prank(admin);
        staking.setBandLevel(BAND_ID_1, BAND_1_PRICE, BAND_1_ACCESSIBLE_POOLS);
    }
}
