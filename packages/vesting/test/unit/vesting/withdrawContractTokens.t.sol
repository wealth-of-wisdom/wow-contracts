// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {MockToken} from "../../mocks/MockToken.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Vesting_Unit_Test} from "./VestingUnit.t.sol";

contract Vesting_WithdrawContractTokens_Unit_Test is Vesting_Unit_Test {
    uint256 internal withdrawAmount = 1 ether;
    MockToken internal customToken;

    function setUp() public virtual override {
        Vesting_Unit_Test.setUp();

        vm.startPrank(admin);
        customToken = new MockToken();
        customToken.initialize("TEST", "TST", TOTAL_POOL_TOKEN_AMOUNT * 10);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////////////////////
                                        TESTS
    //////////////////////////////////////////////////////////////////////////////*/

    function test_withdrawContractTokens_RevertIf_NotAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        vesting.withdrawContractTokens(customToken, alice, withdrawAmount);
    }

    function test_withdrawContractTokens_RevertIf_TokenAddressIsZero()
        external
    {
        vm.expectRevert(Errors.Vesting__ZeroAddress.selector);
        vm.prank(admin);
        vesting.withdrawContractTokens(
            IERC20(ZERO_ADDRESS),
            alice,
            withdrawAmount
        );
    }

    function test_withdrawContractTokens_RevertIf_RecipientAddressIsZero()
        external
    {
        vm.expectRevert(Errors.Vesting__ZeroAddress.selector);
        vm.prank(admin);
        vesting.withdrawContractTokens(
            customToken,
            ZERO_ADDRESS,
            withdrawAmount
        );
    }

    function test_withdrawContractTokens_RevertIf_TokenAmountIsZero() external {
        vm.expectRevert(Errors.Vesting__TokenAmountZero.selector);
        vm.prank(admin);
        vesting.withdrawContractTokens(customToken, alice, 0);
    }

    function test_withdrawContractTokens_RevertIf_TokenIsVestedToken()
        external
    {
        vm.expectRevert(Errors.Vesting__CanNotWithdrawVestedTokens.selector);
        vm.prank(admin);
        vesting.withdrawContractTokens(token, alice, withdrawAmount);
    }

    function test_withdrawContractTokens_RevertIf_TokenAmountIsGreaterThanBalance()
        external
    {
        vm.expectRevert(Errors.Vesting__InsufficientBalance.selector);
        vm.prank(admin);
        vesting.withdrawContractTokens(customToken, alice, withdrawAmount);
    }

    function test_withdrawContractTokens_TransfersTokensFromContract()
        external
    {
        vm.prank(admin);
        customToken.mint(address(vesting), withdrawAmount);

        uint256 balanceBefore = customToken.balanceOf(address(vesting));
        vm.prank(admin);
        vesting.withdrawContractTokens(customToken, bob, withdrawAmount);
        uint256 balanceAfter = customToken.balanceOf(address(vesting));

        assertEq(
            balanceBefore - withdrawAmount,
            balanceAfter,
            "Incorrect balance"
        );
    }

    function test_withdrawContractTokens_TransfersTokensToRecipient() external {
        vm.prank(admin);
        customToken.mint(address(vesting), withdrawAmount);

        uint256 balanceBefore = customToken.balanceOf(bob);
        vm.prank(admin);
        vesting.withdrawContractTokens(customToken, bob, withdrawAmount);
        uint256 balanceAfter = customToken.balanceOf(bob);

        assertEq(
            balanceBefore + withdrawAmount,
            balanceAfter,
            "Incorrect balance"
        );
    }

    function test_withdrawContractTokens_EmitsContractTokensWithdrawnEvent()
        external
    {
        vm.prank(admin);
        customToken.mint(address(vesting), withdrawAmount);

        vm.expectEmit(true, true, true, true);
        emit ContractTokensWithdrawn(customToken, bob, withdrawAmount);

        vm.prank(admin);
        vesting.withdrawContractTokens(customToken, bob, withdrawAmount);
    }
}
