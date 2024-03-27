// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract NftSale_SetVestingContract_Unit_Test is Unit_Test {
    IVesting internal constant newVesting = IVesting(address(100));

    function test_setVestingContract_RevertIf_NotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        nft.setVestingContract(newVesting);
    }

    function test_setVestingContract_RevertIf_ZeroAddress() external {
        vm.expectRevert(Errors.Nft__ZeroAddress.selector);
        vm.prank(admin);
        nft.setVestingContract(IVesting(ZERO_ADDRESS));
    }

    function test_setVestingContract_SetsVestingContract() external {
        vm.prank(admin);
        nft.setVestingContract(newVesting);
        assertEq(
            address(nft.getVestingContract()),
            address(newVesting),
            "New vesting contract incorrect"
        );
    }

    function test_setVestingContract_EmitsVestingContractSetEvent() external {
        vm.expectEmit(true, true, true, true);
        emit VestingContractSet(newVesting);

        vm.prank(admin);
        nft.setVestingContract(newVesting);
    }
}
