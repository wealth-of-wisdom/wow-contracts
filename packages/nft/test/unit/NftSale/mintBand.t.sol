// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {INft} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Nft_Sale_Unit_Test} from "../NftSaleUnit.t.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Nft_Sale_MintBand_Unit_Test is Nft_Sale_Unit_Test {
    function test_mintBand_RevertIf_NonExistantPayment() external {
        vm.expectRevert(Errors.Nft__NonExistantPayment.selector);
        vm.prank(admin);
        sale.mintBand(DEFAULT_LEVEL, IERC20(ZERO_ADDRESS));
    }
}
