// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
import {Errors} from "@wealth-of-wisdom/vesting/contracts/libraries/Errors.sol";
import {Vesting_Unit_Test} from "@wealth-of-wisdom/vesting/test/unit/VestingUnit.t.sol";

contract Vesting_AddVestingPool_Unit_Test is Vesting_Unit_Test {
    function test_addVestingPool_RevertIf_NotAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        _addDefaultVestingPool();
    }

    function test_addVestingPool_RevertIf_ZeroTokenAMount() external {
        vm.expectRevert(Errors.Vesting__TokenAmountZero.selector);
        vm.prank(admin);
        vesting.addVestingPool(
            POOL_NAME,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_IN_DAYS,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR,
            VESTING_DURATION_IN_MONTHS,
            IVesting.UnlockTypes.MONTHLY,
            0
        );
    }

    function test_addVestingPool_RevertIf_EmptyName() external {
        vm.expectRevert(Errors.Vesting__EmptyName.selector);
        vm.prank(admin);
        vesting.addVestingPool(
            "",
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_IN_DAYS,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR,
            VESTING_DURATION_IN_MONTHS,
            IVesting.UnlockTypes.MONTHLY,
            TOTAL_POOL_TOKEN_AMOUNT
        );
    }

    function test_addVestingPool_RevertIf_PoolWithThisNameExists()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__PoolWithThisNameExists.selector);
        vm.prank(admin);
        _addDefaultVestingPool();
    }

    function test_addVestingPool_RevertIf_ListingDivisorZero() external {
        vm.expectRevert(Errors.Vesting__PercentageDivisorZero.selector);
        vm.prank(admin);
        vesting.addVestingPool(
            POOL_NAME,
            LISTING_PERCENTAGE_DIVIDEND,
            0,
            CLIFF_IN_DAYS,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR,
            VESTING_DURATION_IN_MONTHS,
            IVesting.UnlockTypes.MONTHLY,
            TOTAL_POOL_TOKEN_AMOUNT
        );
    }

    function test_addVestingPool_RevertIf_CliffDivisorZero() external {
        vm.expectRevert(Errors.Vesting__PercentageDivisorZero.selector);
        vm.prank(admin);
        vesting.addVestingPool(
            POOL_NAME,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_IN_DAYS,
            CLIFF_PERCENTAGE_DIVIDEND,
            0,
            VESTING_DURATION_IN_MONTHS,
            IVesting.UnlockTypes.MONTHLY,
            TOTAL_POOL_TOKEN_AMOUNT
        );
    }

    function test_addVestingPool_RevertIf_ListingAndCliffPercentageOverflow()
        external
    {
        vm.expectRevert(
            Errors.Vesting__ListingAndCliffPercentageOverflow.selector
        );
        vm.prank(admin);
        vesting.addVestingPool(
            POOL_NAME,
            51,
            100,
            CLIFF_IN_DAYS,
            5,
            10,
            VESTING_DURATION_IN_MONTHS,
            IVesting.UnlockTypes.MONTHLY,
            TOTAL_POOL_TOKEN_AMOUNT
        );
    }

    function test_addVestingPool_RevertIf_VestingDurationZero() external {
        vm.expectRevert(Errors.Vesting__VestingDurationZero.selector);
        vm.prank(admin);
        vesting.addVestingPool(
            POOL_NAME,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_IN_DAYS,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR,
            0,
            IVesting.UnlockTypes.MONTHLY,
            TOTAL_POOL_TOKEN_AMOUNT
        );
    }

    function test_addVestingPool_SetsPoolNameCorrectly()
        external
        approveAndAddPool
    {
        (string memory name, , , ) = vesting.getGeneralPoolData(PRIMARY_POOL);
        assertEq(name, POOL_NAME, "Pool name incorrect");
    }

    function test_addVestingPool_SetsPoolUnlockTypeCorrectly()
        external
        approveAndAddPool
    {
        (, IVesting.UnlockTypes unlockType, , ) = vesting.getGeneralPoolData(
            PRIMARY_POOL
        );
        assertEq(
            uint8(unlockType),
            uint8(VESTING_UNLOCK_TYPE),
            "Unlock type incorrect"
        );
    }

    function test_addVestingPool_SetsPoolTotalAmountCorrectly()
        external
        approveAndAddPool
    {
        (, , uint256 totalAmount, ) = vesting.getGeneralPoolData(PRIMARY_POOL);
        assertEq(
            totalAmount,
            TOTAL_POOL_TOKEN_AMOUNT,
            "Total pool token amount incorrect"
        );
    }

    function test_addVestingPool_DoesNotChangePoolLockedAmount()
        external
        approveAndAddPool
    {
        (, , , uint256 lockedAmount) = vesting.getGeneralPoolData(PRIMARY_POOL);
        assertEq(lockedAmount, 0, "Locked pool token amount incorrect");
    }

    function test_addVestingPool_SetsListingPercentageDividendCorrectly()
        external
        approveAndAddPool
    {
        (uint16 divided, ) = vesting.getPoolListingData(PRIMARY_POOL);
        assertEq(
            divided,
            LISTING_PERCENTAGE_DIVIDEND,
            "Listing percentage dividend incorrect"
        );
    }

    function test_addVestingPool_SetsListingPercentageDivisorCorrectly()
        external
        approveAndAddPool
    {
        (, uint16 divisor) = vesting.getPoolListingData(PRIMARY_POOL);
        assertEq(
            divisor,
            LISTING_PERCENTAGE_DIVISOR,
            "Listing percentage divisor incorrect"
        );
    }

    function test_addVestingPool_SetsCliffEndDateCorrectly()
        external
        approveAndAddPool
    {
        (uint32 endDate, , , ) = vesting.getPoolCliffData(PRIMARY_POOL);
        uint32 actualEndDate = uint32(LISTING_DATE + CLIFF_IN_DAYS * 1 days);
        assertEq(endDate, actualEndDate, "Cliff in days incorrect");
    }

    function test_addVestingPool_SetsCliffInDaysCorrectly()
        external
        approveAndAddPool
    {
        (, uint16 inDays, , ) = vesting.getPoolCliffData(PRIMARY_POOL);
        assertEq(inDays, CLIFF_IN_DAYS, "Cliff in days incorrect");
    }

    function test_addVestingPool_SetsCliffPercentageDividendCorrectly()
        external
        approveAndAddPool
    {
        (, , uint16 dividend, ) = vesting.getPoolCliffData(PRIMARY_POOL);
        assertEq(
            dividend,
            CLIFF_PERCENTAGE_DIVIDEND,
            "Cliff percentage dividend incorrect"
        );
    }

    function test_addVestingPool_SetsCliffPercentageDivisorCorrectly()
        external
        approveAndAddPool
    {
        (, , , uint16 divisor) = vesting.getPoolCliffData(PRIMARY_POOL);
        assertEq(
            divisor,
            CLIFF_PERCENTAGE_DIVISOR,
            "Cliff percentage divisor incorrect"
        );
    }

    function test_addVestingPool_SetsVestingEndDateCorrectly()
        external
        approveAndAddPool
    {
        (uint32 endDate, , ) = vesting.getPoolVestingData(PRIMARY_POOL);
        uint32 actualEndDate = uint32(
            LISTING_DATE +
                ((CLIFF_IN_DAYS + (VESTING_DURATION_IN_MONTHS * 30)) * 1 days)
        );

        assertEq(endDate, actualEndDate, "Vesting end date incorrect");
    }

    function test_addVestingPool_SetsVestingDurationInDaysCorrectly()
        external
        approveAndAddPool
    {
        (, , uint16 vestingDurationInDays) = vesting.getPoolVestingData(
            PRIMARY_POOL
        );
        assertEq(
            vestingDurationInDays,
            VESTING_DURATION_IN_MONTHS * 30,
            "Vesting duration in days incorrect"
        );
    }

    function test_addVestingPool_SetsVestingDurationInMonthsCorrectly()
        external
        approveAndAddPool
    {
        (, uint16 vestingDurationInMonths, ) = vesting.getPoolVestingData(
            PRIMARY_POOL
        );
        assertEq(
            vestingDurationInMonths,
            VESTING_DURATION_IN_MONTHS,
            "Vesting duration in months incorrect"
        );
    }

    function test_addVestingPool_IncreasesPoolCountByOne()
        external
        approveAndAddPool
    {
        assertEq(vesting.getPoolCount(), 1, "Pool count incorrect");
    }

    function test_addVestingPool_TransfersTokensFromAdmin() external {
        uint256 adminBalanceBefore = token.balanceOf(admin);
        _approveAndAddPool();
        uint256 adminBalanceAfter = token.balanceOf(admin);

        assertEq(
            adminBalanceBefore - TOTAL_POOL_TOKEN_AMOUNT,
            adminBalanceAfter,
            "Admin account balance incorrect"
        );
    }

    function test_addVestingPool_TransfersTokensToVestingContract() external {
        uint256 vestingBalanceBefore = token.balanceOf(address(vesting));
        _approveAndAddPool();
        uint256 vestingBalanceAfter = token.balanceOf(address(vesting));

        assertEq(
            vestingBalanceBefore + TOTAL_POOL_TOKEN_AMOUNT,
            vestingBalanceAfter,
            "Vesting contract balance incorrect"
        );
    }

    function test_addVestingPool_EmitsVestingPoolAddedEvent() external {
        vm.prank(admin);
        token.approve(address(vesting), TOTAL_POOL_TOKEN_AMOUNT);

        vm.expectEmit(true, true, true, true);
        emit VestingPoolAdded(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);

        vm.prank(admin);
        _addDefaultVestingPool();
    }
}
