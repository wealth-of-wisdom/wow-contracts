// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_SetLevel5SupplyCap_Unit_Test is Unit_Test {
    function test_setLevel5SupplyCap_RevertIf_NotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        nft.setLevel5SupplyCap(LEVEL_5_SUPPLY_CAP);
    }

    function test_setLevel5SupplyCap_RevertIf_NewCapIsTooLow() external {
        uint256 newCap = LEVEL_5_SUPPLY_CAP - 1;

        // Simulate: mint 10 of level 5 nfts
        nft.mock_setNftAmount(LEVEL_5, false, LEVEL_5_SUPPLY_CAP);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.Nft__SupplyCapTooLow.selector, newCap)
        );
        vm.prank(admin);
        nft.setLevel5SupplyCap(newCap);
    }

    function test_setLevel5SupplyCap_SetLevel5SupplyCap() external {
        uint256 newCap = LEVEL_5_SUPPLY_CAP * 2;

        vm.prank(admin);
        nft.setLevel5SupplyCap(newCap);

        assertEq(nft.getLevel5SupplyCap(), newCap);
    }

    function test_setLevel5SupplyCap_EmitsLevel5SupplyCapSetEvent() external {
        uint256 newCap = LEVEL_5_SUPPLY_CAP * 2;

        vm.expectEmit(true, true, true, true);
        emit Level5SupplyCapSet(newCap);

        vm.prank(admin);
        nft.setLevel5SupplyCap(newCap);
    }
}
