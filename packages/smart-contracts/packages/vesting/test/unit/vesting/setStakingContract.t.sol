// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IStaking} from "@wealth-of-wisdom/staking/contracts/interfaces/IStaking.sol";
import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {StakingMock} from "../../mocks/StakingMock.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Vesting_SetStakingContract_Unit_Test is Unit_Test {
    IStaking internal newStakingContract;

    function setUp() public virtual override {
        Unit_Test.setUp();

        newStakingContract = IStaking(address(new StakingMock()));
    }

    function test_setStakingContract_RevertIf_CallerNotAdmin() external {
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

    function test_setStakingContract_SetsStakingContractCorrectly() external {
        vm.prank(admin);
        vesting.setStakingContract(newStakingContract);

        assertEq(
            address(vesting.getStakingContract()),
            address(newStakingContract),
            "Should set staking contract correctly"
        );
    }

    function test_setStakingContract_AllowsToSetStakingContractToZeroAddress()
        external
    {
        vm.prank(admin);
        vesting.setStakingContract(IStaking(ZERO_ADDRESS));

        assertEq(
            address(vesting.getStakingContract()),
            ZERO_ADDRESS,
            "Should set staking contract correctly"
        );
    }

    function test_setStakingContract_EmitsStakingContractSetEvent() external {
        vm.expectEmit(address(vesting));
        emit StakingContractSet(newStakingContract);

        vm.prank(admin);
        vesting.setStakingContract(newStakingContract);
    }
}
