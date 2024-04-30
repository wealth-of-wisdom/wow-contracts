// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {StakingMock} from "../../mocks/StakingMock.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_AuthorizeUpgrade_Unit_Test is Unit_Test {
    function setUp() public virtual override {
        Unit_Test.setUp();

        newStaking = new StakingMock();
    }

    function test_mint_RevertIf_CallerNotUpgrader() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                UPGRADER_ROLE
            )
        );
        vm.prank(alice);
        staking.mock_authorizeUpgrade(address(newStaking));
    }

    function test_upgradeTo_ShouldPassAuhorizeWithNewImplementation() external {
        vm.startPrank(admin);
        staking.mock_authorizeUpgrade(address(newStaking));
    }
}
