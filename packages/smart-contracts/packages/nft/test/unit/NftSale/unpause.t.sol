// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INft} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract NftSale_Unpause_Unit_Test is Unit_Test {
    INft internal constant newNft = INft(address(100));

    function test_unpause_RevertIf_ExpectedPause_OnMintNft() external {
        vm.expectRevert(PausableUpgradeable.ExpectedPause.selector);
        vm.prank(admin);
        sale.unpause();
    }

    function test_unpause_SetNftContract() external mintLevel2NftForAlice {
        vm.startPrank(admin);
        sale.pause();
        vm.warp(100);
        sale.unpause();
        vm.stopPrank();

        vm.prank(admin);
        sale.setNftContract(newNft);
    }
}
