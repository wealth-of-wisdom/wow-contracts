// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {INft} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_SetLevelData_Unit_Test is Unit_Test {
    function test_setLevelData_RevertIf_NotDefaultAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        nft.setLevelData(
            LEVEL_5,
            false,
            LEVEL_5_PRICE,
            LEVEL_5_VESTING_REWARD,
            LEVEL_5_LIFECYCLE_DURATION,
            LEVEL_5_EXTENSION_DURATION,
            LEVEL_5_ALLOCATION_PER_PROJECT,
            LEVEL_5_SUPPLY_CAP,
            LEVEL_5_BASE_URI
        );
    }

    function test_setLevelData_RevertIf_LevelIsZero() external {
        uint16 level = 0;

        vm.expectRevert(
            abi.encodeWithSelector(Errors.Nft__InvalidLevel.selector, level)
        );
        vm.prank(admin);
        nft.setLevelData(
            level,
            false,
            LEVEL_5_PRICE,
            LEVEL_5_VESTING_REWARD,
            LEVEL_5_LIFECYCLE_DURATION,
            LEVEL_5_EXTENSION_DURATION,
            LEVEL_5_ALLOCATION_PER_PROJECT,
            LEVEL_5_SUPPLY_CAP,
            LEVEL_5_BASE_URI
        );
    }

    function test_setLevelData_RevertIf_LevelIsTooHigh() external {
        uint16 level = MAX_LEVEL + 1;

        vm.expectRevert(
            abi.encodeWithSelector(Errors.Nft__InvalidLevel.selector, level)
        );
        vm.prank(admin);
        nft.setLevelData(
            level,
            false,
            LEVEL_5_PRICE,
            LEVEL_5_VESTING_REWARD,
            LEVEL_5_LIFECYCLE_DURATION,
            LEVEL_5_EXTENSION_DURATION,
            LEVEL_5_ALLOCATION_PER_PROJECT,
            LEVEL_5_SUPPLY_CAP,
            LEVEL_5_BASE_URI
        );
    }

    function test_setLevelData_RevertIf_PriceIsZero() external {
        vm.expectRevert(Errors.Nft__ZeroAmount.selector);
        vm.prank(admin);
        nft.setLevelData(
            LEVEL_5,
            false,
            0,
            LEVEL_5_VESTING_REWARD,
            LEVEL_5_LIFECYCLE_DURATION,
            LEVEL_5_EXTENSION_DURATION,
            LEVEL_5_ALLOCATION_PER_PROJECT,
            LEVEL_5_SUPPLY_CAP,
            LEVEL_5_BASE_URI
        );
    }

    function test_setLevelData_RevertIf_LifecycleDurationIsZero() external {
        vm.expectRevert(Errors.Nft__ZeroAmount.selector);
        vm.prank(admin);
        nft.setLevelData(
            LEVEL_5,
            false,
            LEVEL_5_PRICE,
            LEVEL_5_VESTING_REWARD,
            0,
            LEVEL_5_EXTENSION_DURATION,
            LEVEL_5_ALLOCATION_PER_PROJECT,
            LEVEL_5_SUPPLY_CAP,
            LEVEL_5_BASE_URI
        );
    }

    function test_setLevelData_RevertIf_BaseURIEmpty() external {
        vm.expectRevert(Errors.Nft__EmptyString.selector);
        vm.prank(admin);
        nft.setLevelData(
            LEVEL_5,
            false,
            LEVEL_5_PRICE,
            LEVEL_5_VESTING_REWARD,
            LEVEL_5_LIFECYCLE_DURATION,
            LEVEL_5_EXTENSION_DURATION,
            LEVEL_5_ALLOCATION_PER_PROJECT,
            LEVEL_5_SUPPLY_CAP,
            ""
        );
    }

    function test_setLevelData_RevertIf_SupplyCapTooLow() external {
        uint256 newSupplyCap = 10;
        nft.mock_setNftAmount(LEVEL_5, false, newSupplyCap);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Nft__SupplyCapTooLow.selector,
                newSupplyCap - 1
            )
        );
        vm.prank(admin);
        nft.setLevelData(
            LEVEL_5,
            false,
            LEVEL_5_PRICE,
            LEVEL_5_VESTING_REWARD,
            LEVEL_5_LIFECYCLE_DURATION,
            LEVEL_5_EXTENSION_DURATION,
            LEVEL_5_ALLOCATION_PER_PROJECT,
            newSupplyCap - 1,
            LEVEL_5_BASE_URI
        );
    }

    function test_setLevelData_SetsNftLevelData() external {
        vm.prank(admin);
        nft.setLevelData(
            LEVEL_5,
            false,
            LEVEL_5_PRICE,
            LEVEL_5_VESTING_REWARD,
            LEVEL_5_LIFECYCLE_DURATION,
            LEVEL_5_EXTENSION_DURATION,
            LEVEL_5_ALLOCATION_PER_PROJECT,
            LEVEL_5_SUPPLY_CAP,
            LEVEL_5_BASE_URI
        );

        INft.NftLevel memory nftLevel = nft.getLevelData(LEVEL_5, false);
        assertEq(nftLevel.price, LEVEL_5_PRICE, "Price inocrrect");
        assertEq(
            nftLevel.vestingRewardWOWTokens,
            LEVEL_5_VESTING_REWARD,
            "Vesting reward incorrect"
        );
        assertEq(
            nftLevel.lifecycleDuration,
            LEVEL_5_LIFECYCLE_DURATION,
            "Lifecycle duration incorrect"
        );
        assertEq(
            nftLevel.extensionDuration,
            LEVEL_5_EXTENSION_DURATION,
            "Extension duration incorrect"
        );
        assertEq(
            nftLevel.allocationPerProject,
            LEVEL_5_ALLOCATION_PER_PROJECT,
            "Allocation per project incorrect"
        );
        assertEq(
            nftLevel.supplyCap,
            LEVEL_5_SUPPLY_CAP,
            "Supply cap incorrect"
        );
        assertEq(nftLevel.nftAmount, 0, "NFT amount incorrect");
        assertEq(nftLevel.baseURI, LEVEL_5_BASE_URI, "Base URI incorrect");
    }

    function test_setLevelData_EmitsLevelDataSetEvent() external {
        vm.expectEmit(true, true, true, true);
        emit LevelDataSet(
            LEVEL_5,
            false,
            LEVEL_5_PRICE,
            LEVEL_5_VESTING_REWARD,
            LEVEL_5_LIFECYCLE_DURATION,
            LEVEL_5_EXTENSION_DURATION,
            LEVEL_5_ALLOCATION_PER_PROJECT,
            LEVEL_5_SUPPLY_CAP,
            LEVEL_5_BASE_URI
        );

        vm.prank(admin);
        nft.setLevelData(
            LEVEL_5,
            false,
            LEVEL_5_PRICE,
            LEVEL_5_VESTING_REWARD,
            LEVEL_5_LIFECYCLE_DURATION,
            LEVEL_5_EXTENSION_DURATION,
            LEVEL_5_ALLOCATION_PER_PROJECT,
            LEVEL_5_SUPPLY_CAP,
            LEVEL_5_BASE_URI
        );
    }
}
