// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_SetDistributionInProgress_Unit_Test is Unit_Test {
    function test_setDistributionInProgress_RevertIf_CallerNotDefaultAdmin()
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
        staking.setDistributionInProgress(true);
    }

    function test_setDistributionInProgress_DefaultStatusIsNotInProgress()
        external
    {
        assertFalse(
            staking.isDistributionInProgress(),
            "Band upgrades should be enabled"
        );
    }

    function test_setDistributionInProgress_SetsStatusToInProgress() external {
        vm.prank(admin);
        staking.setDistributionInProgress(true);
        assertTrue(
            staking.isDistributionInProgress(),
            "Distribution should be in progress"
        );
    }

    function test_setDistributionInProgress_SetsStatusToNotInProgress()
        external
    {
        vm.startPrank(admin);
        staking.setDistributionInProgress(true);
        staking.setDistributionInProgress(false);
        vm.stopPrank();

        assertFalse(
            staking.isDistributionInProgress(),
            "Distribution should not be in progress"
        );
    }

    function test_setDistributionInProgress_EmitsBandUpgradeStatusSet()
        external
    {
        vm.expectEmit(address(staking));
        emit DistributionStatusSet(true);

        vm.prank(admin);
        staking.setDistributionInProgress(true);
    }
}
