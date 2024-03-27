// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract NftSale_WithdrawTokens_Unit_Test is Unit_Test {
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
        sale.withdrawTokens(tokenUSDT, INIT_TOKEN_BALANCE);
    }

    function test_withdrawTokens_RevertIf_ZeroAmount() external {
        vm.expectRevert(Errors.NftSale__ZeroAmount.selector);
        vm.prank(admin);
        sale.withdrawTokens(tokenUSDT, 0);
    }

    function test_withdrawTokens_RevertIf_ContractBalanceIsZero() external {
        uint256 amount = 1 wei;
        uint256 contractBalance = tokenUSDT.balanceOf(address(sale));
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.NftSale__InsufficientContractBalance.selector,
                contractBalance,
                amount
            )
        );
        vm.prank(admin);
        sale.withdrawTokens(tokenUSDT, amount);
    }

    function test_withdrawTokens_RevertIf_InsufficientContractBalance()
        external
    {
        uint256 amount = 1 ether;
        uint256 withdrawAmount = amount + 1 wei;

        vm.prank(admin);
        tokenUSDT.mint(address(sale), amount);

        uint256 contractBalance = tokenUSDT.balanceOf(address(sale));
        assertEq(contractBalance, amount, "Contract balance not set correctly");

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.NftSale__InsufficientContractBalance.selector,
                contractBalance,
                withdrawAmount
            )
        );
        vm.prank(admin);
        sale.withdrawTokens(tokenUSDT, withdrawAmount);
    }

    function test_withdrawTokens_TransfersTokensToAdmin()
        external
        mintLevel2NftForAlice
    {
        vm.startPrank(admin);
        uint256 contractBalance = tokenUSDT.balanceOf(address(sale));

        uint256 adminStartingBalance = tokenUSDT.balanceOf(admin);
        sale.withdrawTokens(tokenUSDT, contractBalance);
        uint256 adminEndingBalance = tokenUSDT.balanceOf(admin);
        vm.stopPrank();

        assertEq(
            adminStartingBalance + contractBalance,
            adminEndingBalance,
            "Funds not transfered"
        );
    }

    function test_withdrawTokens_TransfersTokensFromContract()
        external
        mintLevel2NftForAlice
    {
        vm.startPrank(admin);

        uint256 contractStartingBalance = tokenUSDT.balanceOf(address(sale));
        sale.withdrawTokens(tokenUSDT, contractStartingBalance);
        uint256 contractEndingBalance = tokenUSDT.balanceOf(address(sale));
        vm.stopPrank();

        assertEq(
            contractStartingBalance,
            LEVEL_2_PRICE,
            "Balance not set"
        );
        assertEq(contractEndingBalance, 0, "Funds not transfered");
    }

    function test_withdrawTokens_EmitsTokensWithdrawnEvent()
        external
        mintLevel2NftForAlice
    {
        vm.startPrank(admin);
        uint256 contractBalance = tokenUSDT.balanceOf(address(sale));

        vm.expectEmit(true, true, true, true);
        emit TokensWithdrawn(tokenUSDT, admin, contractBalance);

        sale.withdrawTokens(tokenUSDT, contractBalance);
        vm.stopPrank();
    }
}
