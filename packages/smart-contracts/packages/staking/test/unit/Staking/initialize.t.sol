// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {StakingMock} from "../../mocks/StakingMock.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_Initialize_Unit_Test is Unit_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  SET UP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Unit_Test.setUp();

        vm.startPrank(admin);
        staking = new StakingMock();
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier initializeStaking() {
        vm.prank(admin);
        staking.initialize(
            usdtToken,
            usdcToken,
            wowToken,
            address(vesting),
            GELATO_EXECUTOR_ADDRESS,
            TOTAL_POOLS,
            TOTAL_BAND_LEVELS
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  TESTS
    //////////////////////////////////////////////////////////////////////////*/

    function test_initialize_RevertIf_USDTTokenIsZeroAddress() external {
        vm.expectRevert(Errors.Staking__ZeroAddress.selector);
        staking.initialize(
            IERC20(ZERO_ADDRESS),
            usdcToken,
            wowToken,
            address(vesting),
            GELATO_EXECUTOR_ADDRESS,
            TOTAL_POOLS,
            TOTAL_BAND_LEVELS
        );
    }

    function test_initialize_RevertIf_USDCTokenIsZeroAddress() external {
        vm.expectRevert(Errors.Staking__ZeroAddress.selector);
        staking.initialize(
            usdtToken,
            IERC20(ZERO_ADDRESS),
            wowToken,
            address(vesting),
            GELATO_EXECUTOR_ADDRESS,
            TOTAL_POOLS,
            TOTAL_BAND_LEVELS
        );
    }

    function test_initialize_RevertIf_WOWTokenIsZeroAddress() external {
        vm.expectRevert(Errors.Staking__ZeroAddress.selector);
        staking.initialize(
            usdtToken,
            usdcToken,
            IERC20(ZERO_ADDRESS),
            address(vesting),
            GELATO_EXECUTOR_ADDRESS,
            TOTAL_POOLS,
            TOTAL_BAND_LEVELS
        );
    }

    function test_initialize_RevertIf_TotalPoolsIsZero() external {
        vm.expectRevert(Errors.Staking__ZeroAmount.selector);
        staking.initialize(
            usdtToken,
            usdcToken,
            wowToken,
            address(vesting),
            GELATO_EXECUTOR_ADDRESS,
            0,
            TOTAL_BAND_LEVELS
        );
    }

    function test_initialize_RevertIf_TotalBandsIsZero() external {
        vm.expectRevert(Errors.Staking__ZeroAmount.selector);
        staking.initialize(
            usdtToken,
            usdcToken,
            wowToken,
            address(vesting),
            GELATO_EXECUTOR_ADDRESS,
            TOTAL_POOLS,
            0
        );
    }

    function test_initialize_GrantsDefaultAdminRoleToDeployer()
        external
        initializeStaking
    {
        assertTrue(
            staking.hasRole(DEFAULT_ADMIN_ROLE, admin),
            "Admin should have default admin role"
        );
    }

    function test_initialize_GrantsUpgraderRoleToDeployer()
        external
        initializeStaking
    {
        assertTrue(
            staking.hasRole(UPGRADER_ROLE, admin),
            "Admin should have upgrader role"
        );
    }

    function test_initialize_GrantsGelatoExecutorRoleToDeployer()
        external
        initializeStaking
    {
        assertTrue(
            staking.hasRole(GELATO_EXECUTOR_ROLE, admin),
            "Admin should have gelato executor role"
        );
    }

    function test_initialize_GrantsVestingRoleToVestingContract()
        external
        initializeStaking
    {
        assertTrue(
            staking.hasRole(VESTING_ROLE, address(vesting)),
            "Vesting contract should have vesting role"
        );
    }

    function test_initialize_GrantsGelatoExecutorRoleToGelato()
        external
        initializeStaking
    {
        assertTrue(
            staking.hasRole(GELATO_EXECUTOR_ROLE, GELATO_EXECUTOR_ADDRESS),
            "Gelato should have gelato executor role"
        );
    }

    function test_initialize_SetsUSDTTokenCorrectly()
        external
        initializeStaking
    {
        assertEq(
            address(staking.getTokenUSDT()),
            address(usdtToken),
            "USDT token should be set correctly"
        );
    }

    function test_initialize_SetsUSDCTokenCorrectly()
        external
        initializeStaking
    {
        assertEq(
            address(staking.getTokenUSDC()),
            address(usdcToken),
            "USDC token should be set correctly"
        );
    }

    function test_initialize_SetsWOWTokenCorrectly()
        external
        initializeStaking
    {
        assertEq(
            address(staking.getTokenWOW()),
            address(wowToken),
            "WOW token should be set correctly"
        );
    }

    function test_initialize_SetsTotalPoolsCorrectly()
        external
        initializeStaking
    {
        assertEq(
            staking.getTotalPools(),
            TOTAL_POOLS,
            "Total pools should be set correctly"
        );
    }

    function test_initialize_SetsTotalBandsCorrectly()
        external
        initializeStaking
    {
        assertEq(
            staking.getTotalBandLevels(),
            TOTAL_BAND_LEVELS,
            "Total bands should be set correctly"
        );
    }

    function test_initialize_EmitsInitializedContractData() external {
        vm.expectEmit(address(staking));
        emit InitializedContractData(
            usdtToken,
            usdcToken,
            wowToken,
            TOTAL_POOLS,
            TOTAL_BAND_LEVELS
        );

        vm.prank(admin);
        staking.initialize(
            usdtToken,
            usdcToken,
            wowToken,
            address(vesting),
            GELATO_EXECUTOR_ADDRESS,
            TOTAL_POOLS,
            TOTAL_BAND_LEVELS
        );
    }

    function test_getPeriodDuration_MonthSetCorrectly() external {
        assertEq(
            staking.getPeriodDuration(),
            MONTH,
            "Period duration constant reset"
        );
    }
}
