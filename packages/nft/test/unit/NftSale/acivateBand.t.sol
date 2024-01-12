// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IVesting, IVestingEvents} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {NftSale_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftSaleUnit.t.sol";

contract NftSale_ActivateBand_Unit_Test is NftSale_Unit_Test, IVestingEvents {
    function test_activateBand_RevertIf_NotBandOwner()
        external
        mintLevel2BandForAlice
    {
        vm.expectRevert(Errors.NftSale__NotBandOwner.selector);
        vm.prank(bob);
        sale.activateBand(NFT_TOKEN_ID_0);
    }

    function test_activateBand_RevertIf_BandAlreadyActivated()
        external
        mintLevel2BandForAlice
    {
        vm.startPrank(alice);
        sale.activateBand(NFT_TOKEN_ID_0);
        vm.expectRevert(Errors.NftSale__AlreadyActivated.selector);
        sale.activateBand(NFT_TOKEN_ID_0);
        vm.stopPrank();
    }

    function test_activateBand_UpdatesBandActivity()
        external
        mintLevel2BandForAlice
    {
        vm.prank(alice);
        sale.activateBand(NFT_TOKEN_ID_0);

        INftSale.Band memory bandData = sale.getBand(NFT_TOKEN_ID_0);

        assertFalse(bandData.isGenesis, "Token genesis state changed");
        assertEq(bandData.level, DEFAULT_LEVEL_2, "Level data changed");
        assertEq(
            uint8(bandData.activityType),
            uint8(NFT_ACTIVITY_TYPE_ACTIVATED),
            "Band was not activated"
        );
    }

    function test_activateBand_AddsBeneficiaryInVestingContract()
        external
        mintLevel2BandForAlice
    {
        vm.prank(alice);
        sale.activateBand(NFT_TOKEN_ID_0);

        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            DEFAULT_VESTING_PID,
            alice
        );
        uint256 tokensInVesting = sale.getVestingRewardWOWTokens(
            DEFAULT_LEVEL_2
        );

        assertEq(
            beneficiary.totalTokenAmount,
            tokensInVesting,
            "Locked tokens amount is incorrect"
        );
    }

    function test_activateBand_EmitsBeneficiaryAddedEvent()
        external
        mintLevel2BandForAlice
    {
        vm.expectEmit(true, true, true, true);
        emit BeneficiaryAdded(
            DEFAULT_VESTING_PID,
            alice,
            sale.getVestingRewardWOWTokens(DEFAULT_LEVEL_2)
        );

        vm.prank(alice);
        sale.activateBand(NFT_TOKEN_ID_0);
    }

    function test_activateBand_EmitsBandActivatedEvent()
        external
        mintLevel2BandForAlice
    {
        vm.expectEmit(true, true, true, true);
        emit BandActivated(alice, NFT_TOKEN_ID_0, DEFAULT_LEVEL_2, false);

        vm.prank(alice);
        sale.activateBand(NFT_TOKEN_ID_0);
    }
}
