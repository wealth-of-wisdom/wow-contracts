// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IStaking} from "@wealth-of-wisdom/staking/contracts/interfaces/IStaking.sol";
import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {StakingMock} from "../../mocks/StakingMock.sol";
import {Vesting_Unit_Test} from "../VestingUnit.t.sol";

contract Vesting_SetStakingContract_Unit_Test is Vesting_Unit_Test {
    StakingMock internal newStakingContract;

    function setUp() public virtual override {
        Vesting_Unit_Test.setUp();

        newStakingContract = new StakingMock();
    }

    function test_setStakingContract_RevertIf_NotAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        vesting.setStakingContract(newStakingContract);
    }

    function test_setStakingContract_RevokeStakingRoleFromOldContract()
        external
    {
        assertTrue(
            vesting.hasRole(STAKING_ROLE, address(staking)),
            "Old staking contract should have staking role"
        );

        vm.prank(admin);
        vesting.setStakingContract(newStakingContract);

        assertTrue(
            !vesting.hasRole(STAKING_ROLE, address(staking)),
            "Old staking contract shouldn't have staking role"
        );
    }

    function test_setStakingContract_GrantStakingRoleToNewContract() external {
        assertTrue(
            !vesting.hasRole(STAKING_ROLE, address(newStakingContract)),
            "New staking contract shouldn't have staking role"
        );

        vm.prank(admin);
        vesting.setStakingContract(newStakingContract);

        assertTrue(
            vesting.hasRole(STAKING_ROLE, address(newStakingContract)),
            "New staking contract should have staking role"
        );
    }

    function test_setStakingContract_RevertIf_NewStakingContractIsZero()
        external
    {
        vm.expectRevert(Errors.Vesting__ZeroAddress.selector);
        vm.prank(admin);
        vesting.setStakingContract(IStaking(ZERO_ADDRESS));
    }

    function test_setStakingContract_SetsStakingContractCorrectly() external {
        vm.prank(admin);
        vesting.setStakingContract(newStakingContract);

        assertEq(
            address(vesting.getStakingContract()),
            address(newStakingContract),
            "Should set staking contract correctly"
        );
    }

    function test_setStakingContract_EmitsStakingContractSetEvent() external {
        vm.expectEmit(true, true, true, true);
        emit StakingContractSet(newStakingContract);

        vm.prank(admin);
        vesting.setStakingContract(newStakingContract);
    }
}
