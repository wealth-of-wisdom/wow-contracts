// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {Nft_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftUnit.t.sol";

contract NftSale_WithdrawTokens_Unit_Test is Nft_Unit_Test {
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
        vm.expectRevert(Errors.NftSale__ZeroAmount.selector);
        vm.prank(admin);
        sale.withdrawTokens(tokenUSDT, 0);
    }

    function test_withdrawTokens_RevertIf_InsufficientContractBalance()
        external
        mintLevel2NftDataForAlice
    {
        uint256 minimalAmount = 100 wei;
        uint256 contractBalance = tokenUSDC.balanceOf(address(sale));
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.NftSale__InsufficientContractBalance.selector,
                contractBalance,
                minimalAmount
            )
        );
        vm.prank(admin);
        sale.withdrawTokens(tokenUSDC, minimalAmount);
    }

    function test_withdrawTokens_TransfersTokensToAdmin()
        external
        mintLevel2NftDataForAlice
    {
        vm.startPrank(admin);
        tokenUSDT.mint(address(sale), INIT_TOKEN_BALANCE);
        uint256 contractBalance = tokenUSDT.balanceOf(address(sale));
        uint256 adminStartingBalance = tokenUSDT.balanceOf(admin);

        sale.withdrawTokens(tokenUSDT, contractBalance);
        vm.stopPrank();
        uint256 adminEndingBalance = tokenUSDT.balanceOf(admin);

        assertEq(
            adminStartingBalance + contractBalance,
            adminEndingBalance,
            "Funds not transfered"
        );
    }

    function test_withdrawTokens_TransfersTokensFromContract()
        external
        mintLevel2NftDataForAlice
    {
        vm.startPrank(admin);
        tokenUSDT.mint(address(sale), INIT_TOKEN_BALANCE);
        uint256 contractStartingBalance = tokenUSDT.balanceOf(address(sale));

        sale.withdrawTokens(tokenUSDT, contractStartingBalance);
        vm.stopPrank();
        uint256 contractEndingBalance = tokenUSDT.balanceOf(address(sale));

        assertEq(contractEndingBalance, 0, "Funds not transfered");
    }

    function test_withdrawTokens_EmitsTokensWithdrawnEvent()
        external
        mintLevel2NftDataForAlice
    {
        vm.startPrank(admin);
        tokenUSDT.mint(address(sale), INIT_TOKEN_BALANCE);
        uint256 contractBalance = tokenUSDT.balanceOf(address(sale));

        vm.expectEmit(true, true, true, true);
        emit TokensWithdrawn(tokenUSDT, admin, contractBalance);

        sale.withdrawTokens(tokenUSDT, contractBalance);
        vm.stopPrank();
    }
}
