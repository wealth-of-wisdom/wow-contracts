// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {StakingMock} from "../../mocks/StakingMock.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Staking_SetPool_Unit_Test is Unit_Test {
    modifier setPoolId1() {
        vm.prank(admin);
        staking.setPool(
            POOL_ID_1,
            POOL_1_PERCENTAGE,
            POOL_1_BAND_ALLOCATION_PERCENTAGE
        );
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
        staking.setPool(
            POOL_ID_1,
            POOL_1_PERCENTAGE,
            POOL_1_BAND_ALLOCATION_PERCENTAGE
        );
    }

    function test_setPool_SetsPoolDistributionPercentage() external setPoolId1 {
        (uint48 percentage, , , , ) = staking.getPool(POOL_ID_1);
        assertEq(
            percentage,
            POOL_1_PERCENTAGE,
            "Pool distribution percentage not set"
        );
    }

    function test_setPool_SetsPoolBandAllocationPercentage()
        external
        setPoolId1
    {
        (, uint48[] memory bandPercentages, , , ) = staking.getPool(POOL_ID_1);

        uint256 bandsAmount = bandPercentages.length;
        for (uint256 i; i < bandsAmount; i++) {
            assertEq(
                bandPercentages[i],
                POOL_1_BAND_ALLOCATION_PERCENTAGE[i],
                "Pool band allocation percentage not set"
            );
        }
    }
}
