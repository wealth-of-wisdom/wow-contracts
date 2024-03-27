// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_WithdrawTokens_Unit_Test is Unit_Test {
    function test_withdrawTokens_RevertIf_AccessControlUnauthorizedAccount()
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
        staking.withdrawTokens(wowToken, INIT_TOKEN_BALANCE);
    }

    function test_withdrawTokens_RevertIf_ZeroAmount() external {
        vm.expectRevert(Errors.Staking__ZeroAmount.selector);
        vm.prank(admin);
        staking.withdrawTokens(wowToken, 0);
    }

    function test_withdrawTokens_RevertIf_ContractBalanceIsZero() external {
        uint256 amount = 1 wei;
        uint256 contractBalance = wowToken.balanceOf(address(staking));
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InsufficientContractBalance.selector,
                contractBalance,
                amount
            )
        );
        vm.prank(admin);
        staking.withdrawTokens(wowToken, amount);
    }

    function test_withdrawTokens_RevertIf_InsufficientContractBalance()
        external
    {
        uint256 amount = 1 ether;
        uint256 withdrawAmount = amount + 1 wei;

        vm.prank(admin);
        wowToken.mint(address(staking), amount);

        uint256 contractBalance = wowToken.balanceOf(address(staking));
        assertEq(contractBalance, amount, "Contract balance not set correctly");

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InsufficientContractBalance.selector,
                contractBalance,
                withdrawAmount
            )
        );
        vm.prank(admin);
        staking.withdrawTokens(wowToken, withdrawAmount);
    }

    function test_withdrawTokens_TransfersTokensToAdmin()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        vm.startPrank(admin);
        uint256 contractBalance = wowToken.balanceOf(address(staking));

        uint256 adminStartingBalance = wowToken.balanceOf(admin);
        staking.withdrawTokens(wowToken, contractBalance);
        uint256 adminEndingBalance = wowToken.balanceOf(admin);
        vm.stopPrank();

        assertEq(
            adminStartingBalance + contractBalance,
            adminEndingBalance,
            "Funds not transfered"
        );
    }

    function test_withdrawTokens_TransfersTokensFromContract()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        vm.startPrank(admin);

        uint256 contractStartingBalance = wowToken.balanceOf(address(staking));
        staking.withdrawTokens(wowToken, contractStartingBalance);
        uint256 contractEndingBalance = wowToken.balanceOf(address(staking));
        vm.stopPrank();

        assertEq(contractStartingBalance, BAND_4_PRICE, "Balance not set");
        assertEq(contractEndingBalance, 0, "Funds not transfered");
    }

    function test_withdrawTokens_EmitsTokensWithdrawnEvent()
        external
        setBandLevelData
        stakeTokens(alice, STAKING_TYPE_FLEXI, BAND_LEVEL_4, MONTH_0)
    {
        vm.startPrank(admin);
        uint256 contractBalance = wowToken.balanceOf(address(staking));

        vm.expectEmit(true, true, true, true);
        emit TokensWithdrawn(wowToken, admin, contractBalance);

        staking.withdrawTokens(wowToken, contractBalance);
        vm.stopPrank();
    }
}
