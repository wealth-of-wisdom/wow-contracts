// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_UpdateBandLevelDeprecationStatus_Unit_Test is Unit_Test {
    bool internal expectedDeprecationStatus = true;
    uint16 internal bandLevel = BAND_LEVEL_1;

    function test_updateBandLevelDeprecationStatus_RevertIf_CallerNotDefaultAdmin()
        external
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        staking.updateBandLevelDeprecationStatus(
            bandLevel,
            expectedDeprecationStatus
        );
    }

    function test_updateBandLevelDeprecationStatus_ChangesIsDeprecatedValue()
        external
    {
        vm.prank(admin);
        staking.updateBandLevelDeprecationStatus(
            bandLevel,
            expectedDeprecationStatus
        );
        (, , bool isDeprecated) = staking.getBandLevel(bandLevel);

        assertEq(
            isDeprecated,
            expectedDeprecationStatus,
            "Band level deprecation status not updated"
        );
    }

    function test_updateBandLevelDeprecationStatus_EmitsBandLevelDeprecationStatusUpdated()
        external
    {
        vm.expectEmit(address(staking));
        emit BandLevelDeprecationStatusUpdated(
            bandLevel,
            expectedDeprecationStatus
        );

        vm.prank(admin);
        staking.updateBandLevelDeprecationStatus(
            bandLevel,
            expectedDeprecationStatus
        );
    }
}
