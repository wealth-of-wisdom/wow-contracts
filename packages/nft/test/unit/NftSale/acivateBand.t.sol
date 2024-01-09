// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {INftSale} from "../../../contracts/interfaces/INftSale.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Nft_Sale_Unit_Test} from "../NftSaleUnit.t.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Nft_Sale_ActivateBand_Unit_Test is Nft_Sale_Unit_Test {
    function test_activateBand_RevertIf_NotBandOwner()
        external
        mintOneBandForUser
    {
        vm.expectRevert(Errors.Nft__NotBandOwner.selector);
        vm.prank(bob);
        sale.activateBand(STARTER_TOKEN_ID);
    }

    function test_activateBand_EmitsBandActivated()
        external
        mintOneBandForUser
    {
        vm.expectEmit(true, true, true, true);
        emit BandActivated(alice, STARTER_TOKEN_ID, DEFAULT_LEVEL, false);
        vm.prank(alice);
        sale.activateBand(STARTER_TOKEN_ID);
    }

    function test_activateBand_activatesBand() external mintOneBandForUser {
        vm.prank(alice);
        sale.activateBand(STARTER_TOKEN_ID);
        INftSale.Band memory bandData = sale.getBand(STARTER_TOKEN_ID);
        assertFalse(bandData.isGenesis, "Token genesis state changed");
        assertEq(bandData.level, DEFAULT_LEVEL, "Level data changed");
        assertEq(
            uint8(bandData.activityType),
            uint8(NFT_ACTIVITY_TYPE_ACTIVATED),
            "Band was not activated"
        );
    }
}
