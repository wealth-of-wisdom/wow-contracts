// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {INftSale} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {NftSale_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftSaleUnit.t.sol";

contract NftSale_SetVestingRewardWOWTokens_Unit_Test is NftSale_Unit_Test {
    uint256 internal constant NEW_WOW_AMOUNT = 50 * WOW_DECIMALS;

    function test_setVestingRewardWOWTokens_RevertIf_NotDefaultAdmin()
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
        sale.setVestingRewardWOWTokens(DEFAULT_LEVEL_2, NEW_WOW_AMOUNT);
    }

    function test_setVestingRewardWOWTokens_RevertIf_PassedZeroAmount()
        external
    {
        vm.expectRevert(Errors.NftSale__PassedZeroAmount.selector);
        vm.prank(admin);
        sale.setVestingRewardWOWTokens(DEFAULT_LEVEL_2, 0);
    }

    function test_setVestingRewardWOWTokens_SetsVestingReward() external {
        vm.prank(admin);
        sale.setVestingRewardWOWTokens(DEFAULT_LEVEL_2, NEW_WOW_AMOUNT);
        assertEq(
            sale.getVestingRewardWOWTokens(DEFAULT_LEVEL_2),
            NEW_WOW_AMOUNT,
            "New token amount set incorrectly"
        );
    }

    function test_setVestingRewardWOWTokens_EmitsLevelTokensSetEvent()
        external
    {
        vm.expectEmit(true, true, true, true);
        emit LevelTokensSet(DEFAULT_LEVEL_2, NEW_WOW_AMOUNT);

        vm.prank(admin);
        sale.setVestingRewardWOWTokens(DEFAULT_LEVEL_2, NEW_WOW_AMOUNT);
    }
}
