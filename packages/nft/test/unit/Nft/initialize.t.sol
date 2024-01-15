// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Nft} from "@wealth-of-wisdom/nft/contracts/Nft.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {Nft_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftUnit.t.sol";

contract Nft_Initialize_Unit_Test is Nft_Unit_Test {
    function setUp() public virtual override {
        Nft_Unit_Test.setUp();

        nftContract = new Nft();
    }

    function test_initialize_RevertIf_NameStringIsEmpty() external {
        vm.expectRevert(Errors.Nft__EmptyString.selector);
        vm.prank(admin);
        nftContract.initialize("", "WOW");
    }

    function test_initialize_RevertIf_SymbolStringIsEmpty() external {
        vm.expectRevert(Errors.Nft__EmptyString.selector);
        vm.prank(admin);
        nftContract.initialize("WOW", "");
    }

    function test_initialize_RevertIf_NameAndSymbolStringsAreEmpty() external {
        vm.expectRevert(Errors.Nft__EmptyString.selector);
        vm.prank(admin);
        nftContract.initialize("", "");
    }

    function test_initialize_SetsNameCorrectly() external {
        vm.prank(admin);
        nftContract.initialize("Wealth of Wisdom", "WOW");
        assertEq(
            nftContract.name(),
            "Wealth of Wisdom",
            "Name not set correctly"
        );
    }

    function test_initialize_SetsSymbolCorrectly() external {
        vm.prank(admin);
        nftContract.initialize("Wealth of Wisdom", "WOW");
        assertEq(nftContract.symbol(), "WOW", "Symbol not set correctly");
    }

    function test_initialize_GrantsDefaultAdminRoleToDeployer() external {
        vm.prank(admin);
        nftContract.initialize("Wealth of Wisdom", "WOW");
        assertTrue(
            nftContract.hasRole(DEFAULT_ADMIN_ROLE, admin),
            "Admin role not granted to deployer"
        );
    }

    function test_initialize_GrantsMinterRoleToDeployer() external {
        vm.prank(admin);
        nftContract.initialize("Wealth of Wisdom", "WOW");
        assertTrue(
            nftContract.hasRole(MINTER_ROLE, admin),
            "Minter role not granted to deployer"
        );
    }

    function test_initialize_GrantsUpgraderRoleToDeployer() external {
        vm.prank(admin);
        nftContract.initialize("Wealth of Wisdom", "WOW");
        assertTrue(
            nftContract.hasRole(UPGRADER_ROLE, admin),
            "Upgrader role not granted to deployer"
        );
    }

    function test_initialize_GrantsWhitelistedSenderRoleToDeployer() external {
        vm.prank(admin);
        nftContract.initialize("Wealth of Wisdom", "WOW");
        assertTrue(
            nftContract.hasRole(WHITELISTED_SENDER_ROLE, admin),
            "Whitelisted sender role not granted to deployer"
        );
    }

    function test_initialize_SetsNextTokenIdToZero() external {
        vm.prank(admin);
        nftContract.initialize("Wealth of Wisdom", "WOW");
        assertEq(
            nftContract.getNextTokenId(),
            0,
            "Next token ID not set to zero"
        );
    }

    function test_initialize_RevertIf_ContractAlreadyInitialized() external {
        vm.startPrank(admin);
        nftContract.initialize("Wealth of Wisdom", "WOW");
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        nftContract.initialize("Wealth of Wisdom", "WOW");
        vm.stopPrank();
    }

    function test_initialize_EmitInitializedEvent() external {
        vm.expectEmit(true, true, true, true);
        emit Initialized(1);

        vm.prank(admin);
        nftContract.initialize("Wealth of Wisdom", "WOW");
    }
}
