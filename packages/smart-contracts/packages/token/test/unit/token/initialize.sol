// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {TokenMock} from "../../mocks/TokenMock.sol";
import {Unit_Test} from "../Unit.t.sol";

contract WOWToken_Initialize_Unit_Test is Unit_Test {
    function setUp() public virtual override {
        Unit_Test.setUp();

        wowToken = new TokenMock();
    }

    function test_initialize_GrantsDefaultAdminRoleToAdmin() external {
        vm.prank(admin);
        wowToken.initialize(TOKEN_NAME, TOKEN_SYMBOL, INIT_TOKEN_SUPPLY);

        assertTrue(
            wowToken.hasRole(DEFAULT_ADMIN_ROLE, admin),
            "Admin should have default admin role"
        );
    }

    function test_initialize_GrantsMinterRoleToAdmin() external {
        vm.prank(admin);
        wowToken.initialize(TOKEN_NAME, TOKEN_SYMBOL, INIT_TOKEN_SUPPLY);

        assertTrue(
            wowToken.hasRole(MINTER_ROLE, admin),
            "Admin should have default minter role"
        );
    }

    function test_initialize_GrantsUpgraderRoleToAdmin() external {
        vm.prank(admin);
        wowToken.initialize(TOKEN_NAME, TOKEN_SYMBOL, INIT_TOKEN_SUPPLY);

        assertTrue(
            wowToken.hasRole(UPGRADER_ROLE, admin),
            "Admin should have default upgrader role"
        );
    }

    function test_initialize_ShouldMintInitialAmount() external {
        uint256 balanceBefore = wowToken.balanceOf(admin);
        vm.prank(admin);
        wowToken.initialize(TOKEN_NAME, TOKEN_SYMBOL, INIT_TOKEN_SUPPLY);

        uint256 balanceAfter = wowToken.balanceOf(admin);

        assertEq(
            balanceBefore + INIT_TOKEN_SUPPLY * 10 ** WOW_DECIMALS,
            balanceAfter,
            "Tokens were not minted to Admin"
        );
    }

    function test_initialize_ShouldIncreaseTotalSupply() external {
        vm.prank(admin);
        wowToken.initialize(TOKEN_NAME, TOKEN_SYMBOL, INIT_TOKEN_SUPPLY);

        uint256 totalSupplyAfter = wowToken.totalSupply();

        assertEq(
            INIT_TOKEN_SUPPLY * 10 ** WOW_DECIMALS,
            totalSupplyAfter,
            "Tokens supply did not increase"
        );
    }
}
