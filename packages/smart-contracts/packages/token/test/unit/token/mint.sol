// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Unit_Test} from "../Unit.t.sol";

contract WOWToken_Mint_Unit_Test is Unit_Test {
    bytes public constant arithmeticError =
        abi.encodeWithSignature("Panic(uint256)", 0x11);

    function test_mint_RevertIf_CallerNotMinter() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                MINTER_ROLE
            )
        );
        vm.prank(alice);
        wowToken.mint(admin, DEFAULT_AMOUNT);
    }

    function test_mint_RevertIf_ERC20InvalidReceiver() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidReceiver.selector,
                ZERO_ADDRESS
            )
        );
        vm.prank(admin);
        wowToken.mint(ZERO_ADDRESS, DEFAULT_AMOUNT);
    }

    function test_mint_RevertIf_Overflow() external {
        vm.expectRevert(arithmeticError);
        vm.prank(admin);
        wowToken.mint(alice, type(uint256).max);
    }

    function test_mint_IncrementsTotalSupply() external {
        uint256 totalSupplyBefore = wowToken.totalSupply();
        uint256 newAmount = 1000;
        vm.prank(admin);
        wowToken.mint(alice, newAmount);

        uint256 totalSupplyAfter = wowToken.totalSupply();

        assertEq(
            totalSupplyBefore + newAmount,
            totalSupplyAfter,
            "Tokens supply did not increase"
        );
    }

    function test_mint_ToOneUser() external {
        uint256 aliceBalanceBefore = wowToken.balanceOf(alice);
        vm.prank(admin);
        wowToken.mint(alice, DEFAULT_AMOUNT);
        uint256 aliceBalanceAfter = wowToken.balanceOf(alice);

        assertEq(
            aliceBalanceBefore + DEFAULT_AMOUNT,
            aliceBalanceAfter,
            "Tokens were not minted to Alice"
        );
    }

    function test_mint_EmitsTransfer() external {
        vm.expectEmit(address(wowToken));
        emit Transfer(ZERO_ADDRESS, alice, DEFAULT_AMOUNT);
        vm.prank(admin);
        wowToken.mint(alice, DEFAULT_AMOUNT);
    }
}
