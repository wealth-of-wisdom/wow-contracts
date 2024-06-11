// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Vesting_UpdateGeneralPoolData_Unit_Test is Unit_Test {
    function test_updateGeneralPoolData_RevertIf_CallerNotAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        vesting.updateGeneralPoolData(
            PRIMARY_POOL,
            POOL_NAME_2,
            DAILY_UNLOCK_TYPE,
            TOTAL_POOL_TOKEN_AMOUNT_2
        );
    }

    function test_updateGeneralPoolData_RevertIf_BeneficiariesAdded()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.expectRevert(Errors.Vesting__PoolHasBeneficiaries.selector);
        _updateGeneralPoolData(PRIMARY_POOL);
    }

    function test_updateGeneralPoolData_RevertIf_EmptyName()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__EmptyName.selector);
        vm.prank(admin);
        vesting.updateGeneralPoolData(
            PRIMARY_POOL,
            "",
            DAILY_UNLOCK_TYPE,
            TOTAL_POOL_TOKEN_AMOUNT_2
        );
    }

    function test_updateGeneralPoolData_RevertIf_PoolWithThisNameExists()
        external
        approveAndAddPoolWithName(POOL_NAME)
        approveAndAddPoolWithName(POOL_NAME_2)
    {
        vm.expectRevert(Errors.Vesting__PoolWithThisNameExists.selector);
        vm.prank(admin);
        vesting.updateGeneralPoolData(
            PRIMARY_POOL,
            POOL_NAME_2,
            DAILY_UNLOCK_TYPE,
            TOTAL_POOL_TOKEN_AMOUNT_2
        );
    }

    function test_updateGeneralPoolData_UpdatesPoolNameCorrectly()
        external
        approveAndAddPool
        updateGeneralPoolData
    {
        (string memory name, , , ) = vesting.getGeneralPoolData(PRIMARY_POOL);
        assertEq(name, POOL_NAME_2, "Pool name incorrect");
    }

    function test_updateGeneralPoolData_DoesNotChangePoolLockedAmount()
        external
        approveAndAddPool
        updateGeneralPoolData
    {
        (, , , uint256 lockedAmount) = vesting.getGeneralPoolData(PRIMARY_POOL);
        assertEq(lockedAmount, 0, "Locked pool token amount incorrect");
    }

    function test_updateGeneralPoolData_UpdatesPoolUnlockTypeCorrectly()
        external
        approveAndAddPool
        updateGeneralPoolData
    {
        (, IVesting.UnlockTypes unlockType, , ) = vesting.getGeneralPoolData(
            PRIMARY_POOL
        );
        assertEq(
            uint8(unlockType),
            uint8(DAILY_UNLOCK_TYPE),
            "Unlock type incorrect"
        );
    }

    function test_updateGeneralPoolData_UpdatesPoolTotalAmountCorrectly()
        external
        approveAndAddPool
        updateGeneralPoolData
    {
        (, , uint256 totalAmount, ) = vesting.getGeneralPoolData(PRIMARY_POOL);
        assertEq(
            totalAmount,
            TOTAL_POOL_TOKEN_AMOUNT_2,
            "Total pool token amount incorrect"
        );
    }

    function test_updateGeneralPoolData_TransfersTokensToAdmin_Return()
        external
        approveAndAddPool
    {
        uint256 adminBalanceBefore = wowToken.balanceOf(admin);
        _updateGeneralPoolData();
        uint256 adminBalanceAfter = wowToken.balanceOf(admin);
        uint256 tokenAmountTransferredBack = TOTAL_POOL_TOKEN_AMOUNT -
            TOTAL_POOL_TOKEN_AMOUNT_2;

        assertEq(
            adminBalanceBefore + tokenAmountTransferredBack,
            adminBalanceAfter,
            "Admin account balance incorrect"
        );
    }

    function test_updateGeneralPoolData_TransfersTokensFromVestingContract_Return()
        external
        approveAndAddPool
    {
        uint256 vestingBalanceBefore = wowToken.balanceOf(address(vesting));
        _updateGeneralPoolData();
        uint256 vestingBalanceAfter = wowToken.balanceOf(address(vesting));
        uint256 tokenAmountTransferredBack = TOTAL_POOL_TOKEN_AMOUNT -
            TOTAL_POOL_TOKEN_AMOUNT_2;

        assertEq(
            vestingBalanceBefore - tokenAmountTransferredBack,
            vestingBalanceAfter,
            "Vesting contract balance incorrect"
        );
    }

    function test_updateGeneralPoolData_TransfersTokensFromAdmin_Deposit()
        external
    {
        vm.startPrank(admin);
        wowToken.approve(address(vesting), TOTAL_POOL_TOKEN_AMOUNT_2);
        vesting.addVestingPool(
            POOL_NAME,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_IN_DAYS,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR,
            VESTING_DURATION_IN_MONTHS,
            IVesting.UnlockTypes.MONTHLY,
            TOTAL_POOL_TOKEN_AMOUNT_2
        );

        uint256 adminBalanceBefore = wowToken.balanceOf(admin);

        wowToken.approve(address(vesting), TOTAL_POOL_TOKEN_AMOUNT);
        vesting.updateGeneralPoolData(
            PRIMARY_POOL,
            POOL_NAME_2,
            DAILY_UNLOCK_TYPE,
            TOTAL_POOL_TOKEN_AMOUNT
        );
        vm.stopPrank();

        uint256 adminBalanceAfter = wowToken.balanceOf(admin);
        uint256 tokenAmountTransferredBack = TOTAL_POOL_TOKEN_AMOUNT -
            TOTAL_POOL_TOKEN_AMOUNT_2;

        assertEq(
            adminBalanceBefore - tokenAmountTransferredBack,
            adminBalanceAfter,
            "Admin account balance incorrect"
        );
    }

    function test_updateGeneralPoolData_TransfersTokensToVestingContract_Deposit()
        external
    {
        vm.startPrank(admin);
        wowToken.approve(address(vesting), TOTAL_POOL_TOKEN_AMOUNT_2);
        vesting.addVestingPool(
            POOL_NAME,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_IN_DAYS,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR,
            VESTING_DURATION_IN_MONTHS,
            IVesting.UnlockTypes.MONTHLY,
            TOTAL_POOL_TOKEN_AMOUNT_2
        );

        uint256 vestingBalanceBefore = wowToken.balanceOf(address(vesting));

        wowToken.approve(address(vesting), TOTAL_POOL_TOKEN_AMOUNT);
        vesting.updateGeneralPoolData(
            PRIMARY_POOL,
            POOL_NAME_2,
            DAILY_UNLOCK_TYPE,
            TOTAL_POOL_TOKEN_AMOUNT
        );
        vm.stopPrank();

        uint256 vestingBalanceAfter = wowToken.balanceOf(address(vesting));
        uint256 tokenAmountTransferredBack = TOTAL_POOL_TOKEN_AMOUNT -
            TOTAL_POOL_TOKEN_AMOUNT_2;

        assertEq(
            vestingBalanceBefore + tokenAmountTransferredBack,
            vestingBalanceAfter,
            "Vesting contract balance incorrect"
        );
    }

    function test_updateGeneralPoolData_EmitsVestingPoolUpdatedEvent()
        external
        approveAndAddPool
    {
        vm.expectEmit(address(vesting));
        emit GeneralPoolDataUpdated(
            PRIMARY_POOL,
            POOL_NAME_2,
            DAILY_UNLOCK_TYPE,
            TOTAL_POOL_TOKEN_AMOUNT_2
        );

        _updateGeneralPoolData();
    }
}
