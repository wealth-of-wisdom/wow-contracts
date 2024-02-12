// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_SetPool_Unit_Test is Unit_Test {
    modifier setPoolId1() {
        vm.prank(admin);
        staking.setPool(POOL_ID_1, POOL_1_PERCENTAGE);
        _;
    }

    function test_setPool_RevertIf_NotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        staking.setPool(POOL_ID_1, POOL_1_PERCENTAGE);
    }

    function test_setPool_RevertIf_PoolIdIsZero() external {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Staking__InvalidPoolId.selector, 0)
        );
        vm.prank(admin);
        staking.setPool(0, POOL_1_PERCENTAGE);
    }

    function test_setPool_RevertIf_PoolIdIsGreaterThanMaxPools() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InvalidPoolId.selector,
                TOTAL_POOLS + 1
            )
        );
        vm.prank(admin);
        staking.setPool(TOTAL_POOLS + 1, POOL_1_PERCENTAGE);
    }

    function test_setPool_RevertIf_PoolPercentageExeeds100Percent() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Staking__InvalidDistributionPercentage.selector,
                PERCENTAGE_PRECISION + 1
            )
        );
        vm.prank(admin);
        staking.setPool(POOL_ID_1, PERCENTAGE_PRECISION + 1);
    }

    function test_setPool_SetsPoolDistributionPercentage() external setPoolId1 {
        (uint48 percentage, , ) = staking.getPool(POOL_ID_1);
        assertEq(
            percentage,
            POOL_1_PERCENTAGE,
            "Pool distribution percentage not set"
        );
    }

    function test_setPool_EmitsPoolSetEvent() external {
        vm.expectEmit(address(staking));
        emit PoolSet(POOL_ID_1, POOL_1_PERCENTAGE);

        vm.prank(admin);
        staking.setPool(POOL_ID_1, POOL_1_PERCENTAGE);
    }
}
