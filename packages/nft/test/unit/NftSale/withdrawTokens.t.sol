// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {INftSale} from "../../../contracts/interfaces/INftSale.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {NftSale_Unit_Test} from "../NftSaleUnit.t.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract NftSale_WithdrawTokens_Unit_Test is NftSale_Unit_Test {
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

    function test_withdrawTokens_RevertIf_PassedZeroAmount() external {
        vm.expectRevert(Errors.Nft__PassedZeroAmount.selector);
        vm.prank(admin);
        sale.withdrawTokens(tokenUSDT, 0);
    }

    function test_withdrawTokens_RevertIf_InsufficientContractBalance()
        external
        mintOneBandForUser
    {
        uint256 minimalAmount = 100;
        uint256 contractBalance = tokenUSDC.balanceOf(address(sale));
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Nft__InsufficientContractBalance.selector,
                contractBalance,
                minimalAmount
            )
        );
        vm.prank(admin);
        sale.withdrawTokens(tokenUSDC, minimalAmount);
    }

    function test_withdrawTokens_EmitsTokensWithdrawn()
        external
        mintOneBandForUser
    {
        uint256 contractBalance = tokenUSDT.balanceOf(address(sale));
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, true);
        emit TokensWithdrawn(tokenUSDT, admin, contractBalance);
        sale.withdrawTokens(tokenUSDT, contractBalance);
        vm.stopPrank();
    }

    function test_withdrawTokens_WithdrawTokens() external mintOneBandForUser {
        uint256 contractBalance = tokenUSDT.balanceOf(address(sale));
        uint256 adminBalanceUSDT = tokenUSDT.balanceOf(admin);

        vm.startPrank(admin);
        sale.withdrawTokens(tokenUSDT, contractBalance);
        vm.stopPrank();

        assertEq(
            tokenUSDT.balanceOf(address(sale)),
            0,
            "Tokens were not wihdrawn"
        );
        assertEq(
            tokenUSDT.balanceOf(admin),
            contractBalance + adminBalanceUSDT,
            "Funds not transfered"
        );
    }
}
