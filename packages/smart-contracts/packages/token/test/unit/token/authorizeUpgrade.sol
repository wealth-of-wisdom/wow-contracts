// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {TokenMock} from "../../mocks/TokenMock.sol";
import {Unit_Test} from "../Unit.t.sol";

contract WOWToken_AuthorizeUpgrade_Unit_Test is Unit_Test {
    function setUp() public virtual override {
        Unit_Test.setUp();

        newWowToken = new TokenMock();
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
        wowToken.authorizeUpgrade(address(newWowToken));
    }

    function test_upgradeTo_ShouldPassAuhorizeWithNewImplementation() external {
        vm.startPrank(admin);
        wowToken.authorizeUpgrade(address(newWowToken));
    }
}
