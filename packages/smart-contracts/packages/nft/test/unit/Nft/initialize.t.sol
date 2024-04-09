// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {NftMock} from "../../mocks/NftMock.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_Initialize_Unit_Test is Unit_Test {
    function setUp() public virtual override {
        Unit_Test.setUp();

        nft = new NftMock();
    }

    modifier initializeNft() {
        vm.prank(admin);
        nft.initialize(
            "Wealth of Wisdom",
            "WOW",
            vesting,
            DEFAULT_VESTING_PID,
            MAX_LEVEL,
            TOTAL_PROJECT_TYPES
        );
        _;
    }

    function test_initialize_RevertIf_NameStringIsEmpty() external {
        vm.expectRevert(Errors.Nft__EmptyString.selector);
        vm.prank(admin);
        nft.initialize(
            "",
            "WOW",
            vesting,
            DEFAULT_VESTING_PID,
            MAX_LEVEL,
            TOTAL_PROJECT_TYPES
        );
    }

    function test_initialize_RevertIf_SymbolStringIsEmpty() external {
        vm.expectRevert(Errors.Nft__EmptyString.selector);
        vm.prank(admin);
        nft.initialize(
            "Wealth of Wisdom",
            "",
            vesting,
            DEFAULT_VESTING_PID,
            MAX_LEVEL,
            TOTAL_PROJECT_TYPES
        );
    }

    function test_initialize_RevertIf_NameAndSymbolStringsAreEmpty() external {
        vm.expectRevert(Errors.Nft__EmptyString.selector);
        vm.prank(admin);
        nft.initialize(
            "",
            "",
            vesting,
            DEFAULT_VESTING_PID,
            MAX_LEVEL,
            TOTAL_PROJECT_TYPES
        );
    }

    function test_initialize_RevertIf_MaxLevelIsZero() external {
        vm.expectRevert(Errors.Nft__ZeroAmount.selector);
        vm.prank(admin);
        nft.initialize(
            "Wealth of Wisdom",
            "WOW",
            vesting,
            DEFAULT_VESTING_PID,
            0,
            TOTAL_PROJECT_TYPES
        );
    }

    function test_initialize_RevertIf_TotalProjectTypesAmountIsZero() external {
        vm.expectRevert(Errors.Nft__ZeroAmount.selector);
        vm.prank(admin);
        nft.initialize(
            "Wealth of Wisdom",
            "WOW",
            vesting,
            DEFAULT_VESTING_PID,
            MAX_LEVEL,
            0
        );
    }

    function test_initialize_GrantsDefaultAdminRoleToDeployer()
        external
        initializeNft
    {
        assertTrue(
            nft.hasRole(DEFAULT_ADMIN_ROLE, admin),
            "Admin role not granted to deployer"
        );
    }

    function test_initialize_GrantsMinterRoleToDeployer()
        external
        initializeNft
    {
        assertTrue(
            nft.hasRole(MINTER_ROLE, admin),
            "Minter role not granted to deployer"
        );
    }

    function test_initialize_GrantsUpgraderRoleToDeployer()
        external
        initializeNft
    {
        assertTrue(
            nft.hasRole(UPGRADER_ROLE, admin),
            "Upgrader role not granted to deployer"
        );
    }

    function test_initialize_GrantsWhitelistedSenderRoleToDeployer()
        external
        initializeNft
    {
        assertTrue(
            nft.hasRole(WHITELISTED_SENDER_ROLE, admin),
            "Whitelisted sender role not granted to deployer"
        );
    }

    function test_initialize_GrantsNftDataManagerRoleToDeployer()
        external
        initializeNft
    {
        assertTrue(
            nft.hasRole(NFT_DATA_MANAGER_ROLE, admin),
            "NFT data manager role not granted to deployer"
        );
    }

    function test_initialize_SetsVestingContractCorrectly()
        external
        initializeNft
    {
        assertEq(
            address(nft.getVestingContract()),
            address(vesting),
            "Vesting contract should be set correctly"
        );
    }

    function test_initialize_SetsPromotionalVestingPIDCorrectly()
        external
        initializeNft
    {
        assertEq(
            nft.getPromotionalPID(),
            DEFAULT_VESTING_PID,
            "Promotional vesting PID should be set correctly"
        );
    }

    function test_initialize_SetsMaxLevelCorrectly() external initializeNft {
        assertEq(
            nft.getMaxLevel(),
            MAX_LEVEL,
            "Max level should be set to 5 by default"
        );
    }

    function test_initialize_SetsTotalProjectTypesCorrectly()
        external
        initializeNft
    {
        assertEq(
            nft.getTotalProjectTypes(),
            TOTAL_PROJECT_TYPES,
            "Total project types should be set correctly"
        );
    }

    function test_initialize_SetsNameCorrectly() external initializeNft {
        assertEq(nft.name(), "Wealth of Wisdom", "Name not set correctly");
    }

    function test_initialize_SetsSymbolCorrectly() external initializeNft {
        assertEq(nft.symbol(), "WOW", "Symbol not set correctly");
    }

    function test_initialize_SetsNextTokenIdToZero() external initializeNft {
        assertEq(nft.getNextTokenId(), 0, "Next token ID not set to zero");
    }

    function test_initialize_RevertIf_ContractAlreadyInitialized()
        external
        initializeNft
    {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        vm.prank(admin);
        nft.initialize(
            "Wealth of Wisdom",
            "WOW",
            vesting,
            DEFAULT_VESTING_PID,
            MAX_LEVEL,
            TOTAL_PROJECT_TYPES
        );
    }

    function test_initialize_EmitInitializedEvent() external {
        vm.expectEmit(true, true, true, true);
        emit Initialized(1);

        vm.prank(admin);
        nft.initialize(
            "Wealth of Wisdom",
            "WOW",
            vesting,
            DEFAULT_VESTING_PID,
            MAX_LEVEL,
            TOTAL_PROJECT_TYPES
        );
    }
}
