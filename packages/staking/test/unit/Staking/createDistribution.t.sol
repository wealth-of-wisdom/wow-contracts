// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_CreateDistribution_Unit_Test is Unit_Test {
    function test_createDistribution_RevertIf_CallerNotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        staking.createDistribution(usdtToken, DISTRIBUTION_AMOUNT);
    }

    function test_createDistribution_RevertIf_TokenIsNotSupportedForDistribution()
        external
    {
        vm.expectRevert(Errors.Staking__NonExistantToken.selector);
        vm.prank(admin);
        staking.createDistribution(wowToken, DISTRIBUTION_AMOUNT);
    }

    function test_createDistribution_RevertIf_AmountIsZero() external {
        vm.expectRevert(Errors.Staking__ZeroAmount.selector);
        vm.prank(admin);
        staking.createDistribution(usdtToken, 0);
    }

    function test_createDistribution_TransfersTokensFromSender() external {
        uint256 adminBalanceBefore = usdtToken.balanceOf(admin);

        vm.startPrank(admin);
        usdtToken.approve(address(staking), DISTRIBUTION_AMOUNT);
        staking.createDistribution(usdtToken, DISTRIBUTION_AMOUNT);
        vm.stopPrank();

        uint256 adminBalanceAfter = usdtToken.balanceOf(admin);

        assertEq(
            adminBalanceBefore - DISTRIBUTION_AMOUNT,
            adminBalanceAfter,
            "Admin balance not decreased"
        );
    }

    function test_createDistribution_TransfersTokensToStaking() external {
        uint256 stakingBalanceBefore = usdtToken.balanceOf(address(staking));

        vm.startPrank(admin);
        usdtToken.approve(address(staking), DISTRIBUTION_AMOUNT);
        staking.createDistribution(usdtToken, DISTRIBUTION_AMOUNT);
        vm.stopPrank();

        uint256 stakingBalanceAfter = usdtToken.balanceOf(address(staking));

        assertEq(
            stakingBalanceBefore + DISTRIBUTION_AMOUNT,
            stakingBalanceAfter,
            "Staking balance not increased"
        );
    }

    function test_createDistribution_EmitsDistributionCreatedEvent() external {
        for (uint8 i; i < TOTAL_BAND_LEVELS; i++) {
            vm.prank(address(uint160(i + 100)));
            staking.stake(STAKING_TYPE_FLEXI, i + 1, MONTH_0);
        }

        vm.startPrank(admin);
        usdtToken.approve(address(staking), DISTRIBUTION_AMOUNT);

        vm.expectEmit(address(staking));
        emit DistributionCreated(
            usdtToken,
            DISTRIBUTION_AMOUNT,
            TOTAL_POOLS,
            TOTAL_BAND_LEVELS,
            TOTAL_BAND_LEVELS // one user for each band level
        );

        staking.createDistribution(usdtToken, DISTRIBUTION_AMOUNT);
        vm.stopPrank();
    }
}
