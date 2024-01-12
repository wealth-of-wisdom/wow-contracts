// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {NftSale_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftSaleUnit.t.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract NftSale_MintGenesisBand_Unit_Test is NftSale_Unit_Test {
    function test_mintGenesisBand_RevertIf_AccessControlUnauthorizedAccount()
        external
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        sale.mintGenesisBand(alice, DEFAULT_LEVEL_2, DEFAULT_GENESIS_AMOUNT);
    }

    function test_mintGenesisBand_RevertIf_ZeroAddress() external {
        vm.expectRevert(Errors.NftSale__ZeroAddress.selector);
        vm.prank(admin);
        sale.mintGenesisBand(
            ZERO_ADDRESS,
            DEFAULT_LEVEL_2,
            DEFAULT_GENESIS_AMOUNT
        );
    }

    function test_mintGenesisBand_RevertIf_InvalidLevel() external {
        uint16 fakeLevel = 16;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.NftSale__InvalidLevel.selector,
                fakeLevel
            )
        );
        vm.prank(admin);
        sale.mintGenesisBand(alice, fakeLevel, DEFAULT_GENESIS_AMOUNT);
    }

    function test_mintGenesisBand_RevertIf_PassedZeroAmount() external {
        vm.expectRevert(Errors.NftSale__PassedZeroAmount.selector);
        vm.prank(admin);
        sale.mintGenesisBand(alice, DEFAULT_LEVEL_2, 0);
    }

    function test_mintGenesisBand_EmitsBandMinted() external {
        vm.expectEmit(true, true, true, true);
        emit BandMinted(alice, NFT_TOKEN_ID_0, DEFAULT_LEVEL_2, true);
        vm.prank(admin);
        sale.mintGenesisBand(alice, DEFAULT_LEVEL_2, DEFAULT_GENESIS_AMOUNT);
    }

    function test_mintGenesisBand_MintGenesisBandWithDataUpdates() external {
        vm.prank(admin);
        sale.mintGenesisBand(alice, DEFAULT_LEVEL_2, DEFAULT_GENESIS_AMOUNT);
        INftSale.Band memory bandData = sale.getBand(NFT_TOKEN_ID_0);

        assertEq(
            nftContract.getNextTokenId(),
            DEFAULT_GENESIS_AMOUNT,
            "Token was not minted and ID not changed"
        );
        assertEq(
            uint8(bandData.activityType),
            uint8(NFT_ACTIVITY_TYPE_INACTIVE),
            "Band not activated"
        );
        assertTrue(bandData.isGenesis, "Band not set as genesis");
        assertEq(bandData.level, DEFAULT_LEVEL_2, "Band level set incorrectly");
        assertEq(
            nftContract.balanceOf(alice),
            DEFAULT_GENESIS_AMOUNT,
            "User did not receive nft"
        );
    }
}
