// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_SetBandUpgradesEnabled_Unit_Test is Unit_Test {
    function test_setBandUpgradesEnabled_RevertIf_CallerNotDefaultAdmin()
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
        staking.setBandUpgradesEnabled(true);
    }

    function test_setBandUpgradesEnabled_DefaultStatusIsDisabled() external {
        assertFalse(
            staking.areBandUpgradesEnabled(),
            "Band upgrades should be enabled"
        );
    }

    function test_setBandUpgradesEnabled_SetsStatusToEnabled() external {
        vm.prank(admin);
        staking.setBandUpgradesEnabled(true);
        assertTrue(
            staking.areBandUpgradesEnabled(),
            "Band upgrades should be enabled"
        );
    }

    function test_setBandUpgradesEnabled_SetsStatusToDisabled() external {
        vm.startPrank(admin);
        staking.setBandUpgradesEnabled(true);
        staking.setBandUpgradesEnabled(false);
        vm.stopPrank();

        assertFalse(
            staking.areBandUpgradesEnabled(),
            "Band upgrades should be disabled"
        );
    }

    function test_setBandUpgradesEnabled_EmitsBandUpgradeStatusSet() external {
        vm.expectEmit(address(staking));
        emit BandUpgradeStatusSet(true);

        vm.prank(admin);
        staking.setBandUpgradesEnabled(true);
    }
}
