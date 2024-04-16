// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INft} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract NftSale_Pause_Unit_Test is Unit_Test {
    INft internal constant newNft = INft(address(100));
    IERC20 internal constant NEW_USDT_TOKEN = IERC20(address(101));
    IERC20 internal constant NEW_USDC_TOKEN = IERC20(address(102));
    address[] threeUsersArray = [alice, alice, bob];
    uint16[] threeLevelsArray = [LEVEL_1, LEVEL_2, LEVEL_3];

    function test_pause_RevertIf_EnforcedPause_OnMintNft() external {
        vm.prank(admin);
        sale.pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(alice);
        sale.mintNft(LEVEL_2, tokenUSDT);
    }

    function test_pause_RevertIf_EnforcedPause_OnUpdateNft()
        external
        mintLevel2NftForAlice
    {
        uint256 level2Price = nft.getLevelData(LEVEL_2, false).price;
        uint256 level3Price = nft.getLevelData(LEVEL_3, false).price;
        uint256 upgradePrice = level3Price - level2Price;

        vm.prank(admin);
        sale.pause();

        vm.startPrank(alice);
        tokenUSDT.approve(address(sale), upgradePrice);

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        sale.updateNft(NFT_TOKEN_ID_0, LEVEL_3, tokenUSDT);
        vm.stopPrank();
    }

    function test_pause_RevertIf_EnforcedPause_OnMintGenesisNfts()
        external
        mintLevel2NftForAlice
    {
        vm.prank(admin);
        sale.pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(admin);
        sale.mintGenesisNfts(threeUsersArray, threeLevelsArray);
    }

    function test_pause_RevertIf_EnforcedPause_OnWithdrawTokens()
        external
        mintLevel2NftForAlice
    {
        uint256 contractBalance = tokenUSDT.balanceOf(address(sale));

        vm.prank(admin);
        sale.pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(admin);
        sale.withdrawTokens(tokenUSDT, contractBalance);
    }

    function test_pause_RevertIf_EnforcedPause_OnSetUSDTToken() external {
        vm.prank(admin);
        sale.pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(admin);
        sale.setUSDTToken(NEW_USDT_TOKEN);
    }

    function test_pause_RevertIf_EnforcedPause_OnSetUSDCToken() external {
        vm.prank(admin);
        sale.pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(admin);
        sale.setUSDCToken(NEW_USDC_TOKEN);
    }

    function test_pause_RevertIf_EnforcedPause_OnSetNftContract() external {
        vm.prank(admin);
        sale.pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(admin);
        sale.setNftContract(newNft);
    }
}
