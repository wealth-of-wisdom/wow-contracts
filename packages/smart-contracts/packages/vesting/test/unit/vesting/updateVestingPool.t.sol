// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Vesting_UpdateVestingPool_Unit_Test is Unit_Test {
    function test_updateVestingPool_RevertIf_CallerNotAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        _updateVestingPool(PRIMARY_POOL);
    }

    function test_updateVestingPool_RevertIf_PoolDoesNotExist() external {
        vm.expectRevert(Errors.Vesting__PoolDoesNotExist.selector);
        vm.prank(admin);
        _updateVestingPool(PRIMARY_POOL);
    }

    function test_updateVestingPool_RevertIf_BeneficiariesAdded()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.expectRevert(Errors.Vesting__BeneficiariesAddedToPool.selector);
        vm.prank(admin);
        _updateVestingPool(PRIMARY_POOL);
    }

    function test_updateVestingPool_RevertIf_EmptyName()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__EmptyName.selector);
        vm.prank(admin);
        vesting.updateVestingPool(
            PRIMARY_POOL,
            "",
            LISTING_PERCENTAGE_DIVIDEND_2,
            LISTING_PERCENTAGE_DIVISOR_2,
            CLIFF_IN_DAYS_2,
            CLIFF_PERCENTAGE_DIVIDEND_2,
            CLIFF_PERCENTAGE_DIVISOR_2,
            VESTING_DURATION_IN_MONTHS_2,
            IVesting.UnlockTypes.DAILY,
            TOTAL_POOL_TOKEN_AMOUNT_2
        );
    }

    function test_updateVestingPool_RevertIf_PoolWithThisNameExists()
        external
        approveAndAddPoolWithName(POOL_NAME_2)
    {
        vm.expectRevert(Errors.Vesting__PoolWithThisNameExists.selector);
        vm.prank(admin);
        vesting.updateVestingPool(
            PRIMARY_POOL,
            POOL_NAME_2,
            LISTING_PERCENTAGE_DIVIDEND_2,
            LISTING_PERCENTAGE_DIVISOR_2,
            CLIFF_IN_DAYS_2,
            CLIFF_PERCENTAGE_DIVIDEND_2,
            CLIFF_PERCENTAGE_DIVISOR_2,
            VESTING_DURATION_IN_MONTHS_2,
            IVesting.UnlockTypes.DAILY,
            TOTAL_POOL_TOKEN_AMOUNT_2
        );
    }

    function test_updateVestingPool_RevertIf_ListingDivisorZero()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__PercentageDivisorZero.selector);
        vm.prank(admin);
        vesting.updateVestingPool(
            PRIMARY_POOL,
            POOL_NAME_2,
            LISTING_PERCENTAGE_DIVIDEND_2,
            0,
            CLIFF_IN_DAYS_2,
            CLIFF_PERCENTAGE_DIVIDEND_2,
            CLIFF_PERCENTAGE_DIVISOR_2,
            VESTING_DURATION_IN_MONTHS_2,
            IVesting.UnlockTypes.DAILY,
            TOTAL_POOL_TOKEN_AMOUNT_2
        );
    }

    function test_updateVestingPool_RevertIf_CliffDivisorZero()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__PercentageDivisorZero.selector);
        vm.prank(admin);
        vesting.updateVestingPool(
            PRIMARY_POOL,
            POOL_NAME,
            LISTING_PERCENTAGE_DIVIDEND_2,
            LISTING_PERCENTAGE_DIVISOR_2,
            CLIFF_IN_DAYS_2,
            CLIFF_PERCENTAGE_DIVIDEND_2,
            0,
            VESTING_DURATION_IN_MONTHS_2,
            IVesting.UnlockTypes.DAILY,
            TOTAL_POOL_TOKEN_AMOUNT_2
        );
    }

    function test_updateVestingPool_RevertIf_ListingAndCliffPercentageOverflow()
        external
        approveAndAddPool
    {
        vm.expectRevert(
            Errors.Vesting__ListingAndCliffPercentageOverflow.selector
        );
        vm.prank(admin);
        vesting.updateVestingPool(
            PRIMARY_POOL,
            POOL_NAME_2,
            51,
            100,
            CLIFF_IN_DAYS_2,
            5,
            10,
            VESTING_DURATION_IN_MONTHS_2,
            IVesting.UnlockTypes.DAILY,
            TOTAL_POOL_TOKEN_AMOUNT_2
        );
    }

    function test_updateVestingPool_RevertIf_VestingDurationZero()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__VestingDurationZero.selector);
        vm.prank(admin);
        vesting.updateVestingPool(
            PRIMARY_POOL,
            POOL_NAME_2,
            LISTING_PERCENTAGE_DIVIDEND_2,
            LISTING_PERCENTAGE_DIVISOR_2,
            CLIFF_IN_DAYS_2,
            CLIFF_PERCENTAGE_DIVIDEND_2,
            CLIFF_PERCENTAGE_DIVISOR_2,
            0,
            IVesting.UnlockTypes.DAILY,
            TOTAL_POOL_TOKEN_AMOUNT_2
        );
    }

    function test_updateVestingPool_UpdatesPoolNameCorrectly()
        external
        approveAndAddPool
        updateVestingPool(PRIMARY_POOL)
    {
        (string memory name, , , ) = vesting.getGeneralPoolData(PRIMARY_POOL);
        assertEq(name, POOL_NAME_2, "Pool name incorrect");
    }

    function test_updateVestingPool_DoesNotChangePoolLockedAmount()
        external
        approveAndAddPool
        updateVestingPool(PRIMARY_POOL)
    {
        (, , , uint256 lockedAmount) = vesting.getGeneralPoolData(PRIMARY_POOL);
        assertEq(lockedAmount, 0, "Locked pool token amount incorrect");
    }

    function test_updateVestingPool_UpdatesListingPercentageDividendCorrectly()
        external
        approveAndAddPool
        updateVestingPool(PRIMARY_POOL)
    {
        (uint16 divided, ) = vesting.getPoolListingData(PRIMARY_POOL);
        assertEq(
            divided,
            LISTING_PERCENTAGE_DIVIDEND_2,
            "Listing percentage dividend incorrect"
        );
    }

    function test_updateVestingPool_UpdatesListingPercentageDivisorCorrectly()
        external
        approveAndAddPool
        updateVestingPool(PRIMARY_POOL)
    {
        (, uint16 divisor) = vesting.getPoolListingData(PRIMARY_POOL);
        assertEq(
            divisor,
            LISTING_PERCENTAGE_DIVISOR_2,
            "Listing percentage divisor incorrect"
        );
    }

    function test_updateVestingPool_UpdatesCliffInDaysCorrectly()
        external
        approveAndAddPool
        updateVestingPool(PRIMARY_POOL)
    {
        (, uint16 inDays, , ) = vesting.getPoolCliffData(PRIMARY_POOL);
        assertEq(inDays, CLIFF_IN_DAYS_2, "Cliff in days incorrect");
    }

    function test_updateVestingPool_UpdatesCliffEndDateCorrectly()
        external
        approveAndAddPool
        updateVestingPool(PRIMARY_POOL)
    {
        (uint32 endDate, , , ) = vesting.getPoolCliffData(PRIMARY_POOL);
        uint32 actualEndDate = uint32(LISTING_DATE + CLIFF_IN_SECONDS_2);
        assertEq(endDate, actualEndDate, "Cliff in days incorrect");
    }

    function test_updateVestingPool_UpdatesCliffPercentageDividendCorrectly()
        external
        approveAndAddPool
        updateVestingPool(PRIMARY_POOL)
    {
        (, , uint16 dividend, ) = vesting.getPoolCliffData(PRIMARY_POOL);
        assertEq(
            dividend,
            CLIFF_PERCENTAGE_DIVIDEND_2,
            "Cliff percentage dividend incorrect"
        );
    }

    function test_updateVestingPool_UpdatesCliffPercentageDivisorCorrectly()
        external
        approveAndAddPool
        updateVestingPool(PRIMARY_POOL)
    {
        (, , , uint16 divisor) = vesting.getPoolCliffData(PRIMARY_POOL);
        assertEq(
            divisor,
            CLIFF_PERCENTAGE_DIVISOR_2,
            "Cliff percentage divisor incorrect"
        );
    }

    function test_updateVestingPool_UpdatesVestingDurationInDaysCorrectly()
        external
        approveAndAddPool
        updateVestingPool(PRIMARY_POOL)
    {
        (, , uint16 vestingDurationInDays) = vesting.getPoolVestingData(
            PRIMARY_POOL
        );
        assertEq(
            vestingDurationInDays,
            VESTING_DURATION_IN_MONTHS_2 * 30,
            "Vesting duration in days incorrect"
        );
    }

    function test_updateVestingPool_UpdatesVestingDurationInMonthsCorrectly()
        external
        approveAndAddPool
        updateVestingPool(PRIMARY_POOL)
    {
        (, uint16 vestingDurationInMonths, ) = vesting.getPoolVestingData(
            PRIMARY_POOL
        );
        assertEq(
            vestingDurationInMonths,
            VESTING_DURATION_IN_MONTHS_2,
            "Vesting duration in months incorrect"
        );
    }

    function test_updateVestingPool_UpdatesVestingEndDateCorrectly()
        external
        approveAndAddPool
        updateVestingPool(PRIMARY_POOL)
    {
        (uint32 endDate, , ) = vesting.getPoolVestingData(PRIMARY_POOL);
        uint32 actualEndDate = uint32(
            LISTING_DATE + CLIFF_IN_SECONDS_2 + VESTING_DURATION_IN_SECONDS_2
        );

        assertEq(endDate, actualEndDate, "Vesting end date incorrect");
    }

    function test_updateVestingPool_UpdatesPoolUnlockTypeCorrectly()
        external
        approveAndAddPool
        updateVestingPool(PRIMARY_POOL)
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

    function test_updateVestingPool_UpdatesPoolTotalAmountCorrectly()
        external
        approveAndAddPool
        updateVestingPool(PRIMARY_POOL)
    {
        (, , uint256 totalAmount, ) = vesting.getGeneralPoolData(PRIMARY_POOL);
        assertEq(
            totalAmount,
            TOTAL_POOL_TOKEN_AMOUNT_2,
            "Total pool token amount incorrect"
        );
    }

    function test_updateVestingPool_DoesNotIncreasePoolCount()
        external
        approveAndAddPool
        updateVestingPool(PRIMARY_POOL)
    {
        assertEq(vesting.getPoolCount(), 1, "Pool count increased");
    }

    function test_updateVestingPool_TransfersTokensToAdmin()
        external
        approveAndAddPool
    {
        uint256 adminBalanceBefore = wowToken.balanceOf(admin);
        _updateVestingPool(PRIMARY_POOL);
        uint256 adminBalanceAfter = wowToken.balanceOf(admin);
        uint256 tokenAmountTransferredBack = TOTAL_POOL_TOKEN_AMOUNT -
            TOTAL_POOL_TOKEN_AMOUNT_2;

        assertEq(
            adminBalanceBefore + tokenAmountTransferredBack,
            adminBalanceAfter,
            "Admin account balance incorrect"
        );
    }

    function test_updateVestingPool_TransfersTokensFromVestingContract()
        external
        approveAndAddPool
    {
        uint256 vestingBalanceBefore = wowToken.balanceOf(address(vesting));
        _updateVestingPool(PRIMARY_POOL);
        uint256 vestingBalanceAfter = wowToken.balanceOf(address(vesting));
        uint256 tokenAmountTransferredBack = TOTAL_POOL_TOKEN_AMOUNT -
            TOTAL_POOL_TOKEN_AMOUNT_2;

        assertEq(
            vestingBalanceBefore - tokenAmountTransferredBack,
            vestingBalanceAfter,
            "Vesting contract balance incorrect"
        );
    }

    function test_updateVestingPool_TransfersTokensFromAdmin() external {
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
        vesting.updateVestingPool(
            PRIMARY_POOL,
            POOL_NAME,
            LISTING_PERCENTAGE_DIVIDEND_2,
            LISTING_PERCENTAGE_DIVISOR_2,
            CLIFF_IN_DAYS_2,
            CLIFF_PERCENTAGE_DIVIDEND_2,
            CLIFF_PERCENTAGE_DIVISOR_2,
            VESTING_DURATION_IN_MONTHS_2,
            IVesting.UnlockTypes.DAILY,
            TOTAL_POOL_TOKEN_AMOUNT
        );
        uint256 adminBalanceAfter = wowToken.balanceOf(admin);
        uint256 tokenAmountTransferredBack = TOTAL_POOL_TOKEN_AMOUNT -
            TOTAL_POOL_TOKEN_AMOUNT_2;

        assertEq(
            adminBalanceBefore - tokenAmountTransferredBack,
            adminBalanceAfter,
            "Admin account balance incorrect"
        );
    }

    function test_updateVestingPool_TransfersTokensToVestingContract()
        external
    {
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
        vesting.updateVestingPool(
            PRIMARY_POOL,
            POOL_NAME,
            LISTING_PERCENTAGE_DIVIDEND_2,
            LISTING_PERCENTAGE_DIVISOR_2,
            CLIFF_IN_DAYS_2,
            CLIFF_PERCENTAGE_DIVIDEND_2,
            CLIFF_PERCENTAGE_DIVISOR_2,
            VESTING_DURATION_IN_MONTHS_2,
            IVesting.UnlockTypes.DAILY,
            TOTAL_POOL_TOKEN_AMOUNT
        );
        uint256 vestingBalanceAfter = wowToken.balanceOf(address(vesting));
        uint256 tokenAmountTransferredBack = TOTAL_POOL_TOKEN_AMOUNT -
            TOTAL_POOL_TOKEN_AMOUNT_2;

        assertEq(
            vestingBalanceBefore + tokenAmountTransferredBack,
            vestingBalanceAfter,
            "Vesting contract balance incorrect"
        );
    }

    function test_updateVestingPool_EmitsVestingPoolUpdatedEvent() external {
        vm.prank(admin);
        wowToken.approve(address(vesting), TOTAL_POOL_TOKEN_AMOUNT);

        vm.expectEmit(address(vesting));
        emit VestingPoolAdded(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);

        vm.prank(admin);
        _addDefaultVestingPool();
    }
}
