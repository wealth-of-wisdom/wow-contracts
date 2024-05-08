// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_SetBandLevel_Unit_Test is Unit_Test {
    uint16[] internal INVALID_ACCESSIBLE_POOLS = [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10
    ];

    function test_setBandLevel_RevertIf_CallerNotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        staking.setBandLevel(
            BAND_LEVEL_1,
            BAND_1_PRICE,
            BAND_1_ACCESSIBLE_POOLS
        );
    }

    function test_setBandLevel_RevertIf_BandLevelIsZero() external {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Staking__InvalidBandLevel.selector, 0)
        );
        vm.prank(admin);
        staking.setBandLevel(0, BAND_1_PRICE, BAND_1_ACCESSIBLE_POOLS);
    }

    function test_setBandLevel_RevertIf_BandLevelIsGreaterThanMaxBands()
        external
    {
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

    function test_setBandLevel_RevertIf_BandPriceIsZero() external {
        vm.expectRevert(Errors.Staking__ZeroAmount.selector);
        vm.prank(admin);
        staking.setBandLevel(BAND_LEVEL_1, 0, BAND_1_ACCESSIBLE_POOLS);
    }

    function test_setBandLevel_RevertIf_MaximumLevelExceeded() external {
        vm.expectRevert(Errors.Staking__MaximumLevelExceeded.selector);
        vm.prank(admin);
        staking.setBandLevel(
            BAND_LEVEL_1,
            BAND_1_PRICE,
            INVALID_ACCESSIBLE_POOLS
        );
    }

    function test_setBandLevel_SetsBandLevelData() external {
        vm.prank(admin);
        staking.setBandLevel(
            BAND_LEVEL_1,
            BAND_1_PRICE,
            BAND_1_ACCESSIBLE_POOLS
        );

        uint256 price = staking.getBandLevel(BAND_LEVEL_1);

        assertEq(price, BAND_1_PRICE);
    }

    function test_setBandLevel_UpdatesBandLevelPrice() external {
        uint16[] memory emptyArray;
        vm.startPrank(admin);
        staking.setBandLevel(
            BAND_LEVEL_1,
            BAND_1_PRICE,
            BAND_1_ACCESSIBLE_POOLS
        );
        staking.setBandLevel(BAND_LEVEL_1, BAND_2_PRICE, emptyArray);
        vm.stopPrank();

        uint256 price = staking.getBandLevel(BAND_LEVEL_1);

        assertEq(price, BAND_2_PRICE);
    }

    function test_setBandLevel_EmitsBandLevelSetEvent() external {
        vm.expectEmit(address(staking));
        emit BandLevelSet(BAND_LEVEL_1, BAND_1_PRICE, BAND_1_ACCESSIBLE_POOLS);

        vm.prank(admin);
        staking.setBandLevel(
            BAND_LEVEL_1,
            BAND_1_PRICE,
            BAND_1_ACCESSIBLE_POOLS
        );
    }
}
