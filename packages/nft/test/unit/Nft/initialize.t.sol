// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
import {Nft} from "../../../contracts/Nft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Nft_Initialize_Unit_Test is Unit_Test {
    function setUp() public virtual override {
        Unit_Test.setUp();

        nftContract = new Nft();
    }

    modifier initializeNft() {
        vm.startPrank(admin);
        nftContract.initialize(
            "Wealth of Wisdom",
            "WOW",
            vesting,
            MAX_LEVEL,
            DEFAULT_VESTING_PID,
            GENESIS_TOKEN_DIVISOR
        );
        _;
    }

    function test_initialize_RevertIf_NameStringIsEmpty() external {
        vm.expectRevert(Errors.Nft__EmptyString.selector);
        vm.prank(admin);
        nftContract.initialize(
            "",
            "WOW",
            vesting,
            MAX_LEVEL,
            DEFAULT_VESTING_PID,
            GENESIS_TOKEN_DIVISOR
        );
    }

    function test_initialize_RevertIf_SymbolStringIsEmpty() external {
        vm.expectRevert(Errors.Nft__EmptyString.selector);
        vm.prank(admin);
        nftContract.initialize(
            "Wealth of Wisdom",
            "",
            vesting,
            MAX_LEVEL,
            DEFAULT_VESTING_PID,
            GENESIS_TOKEN_DIVISOR
        );
    }

    function test_initialize_RevertIf_VestingContractIsZeroAddress() external {
        vm.expectRevert(Errors.Nft__ZeroAddress.selector);
        nftContract.initialize(
            "Wealth of Wisdom",
            "WOW",
            IVesting(ZERO_ADDRESS),
            MAX_LEVEL,
            DEFAULT_VESTING_PID,
            GENESIS_TOKEN_DIVISOR
        );
    }

    function test_initialize_RevertIf_NameAndSymbolStringsAreEmpty() external {
        vm.expectRevert(Errors.Nft__EmptyString.selector);
        vm.prank(admin);
        nftContract.initialize(
            "",
            "",
            vesting,
            MAX_LEVEL,
            DEFAULT_VESTING_PID,
            GENESIS_TOKEN_DIVISOR
        );
    }

    function test_initialize_SetsPromotionalVestingPIDCorrectly()
        external
        initializeNft
        setNftDataForContract
    {
        assertEq(
            nftContract.getPromotionalPID(),
            DEFAULT_VESTING_PID,
            "Promotional vesting PID should be set correctly"
        );
    }

    function test_initialize_SetsNftLevelPricesCorrectly()
        external
        initializeNft
        setNftDataForContract
    {
        assertEq(
            nftContract.getLevelData(1).price,
            LEVEL_1_PRICE,
            "Level 1 price should be set to 1_000 USD"
        );
        assertEq(
            nftContract.getLevelData(2).price,
            LEVEL_2_PRICE,
            "Level 2 price should be set to 5_000 USD"
        );
        assertEq(
            nftContract.getLevelData(3).price,
            LEVEL_3_PRICE,
            "Level 3 price should be set to 10_000 USD"
        );
        assertEq(
            nftContract.getLevelData(4).price,
            LEVEL_4_PRICE,
            "Level 0 price should be set to 50 USD"
        );
    }

    function test_initialize_SetsNftLevelVestingRewardWOWTokensCorrectly()
        external
        initializeNft
        setNftDataForContract
    {
        assertEq(
            nftContract.getLevelData(1).vestingRewardWOWTokens,
            LEVEL_1_VESTING_REWARD,
            "Level 1 vesting reward should be set to 1_000 WOW"
        );
        assertEq(
            nftContract.getLevelData(2).vestingRewardWOWTokens,
            LEVEL_2_VESTING_REWARD,
            "Level 2 vesting reward should be set to 25_000 WOW"
        );
        assertEq(
            nftContract.getLevelData(3).vestingRewardWOWTokens,
            LEVEL_3_VESTING_REWARD,
            "Level 3 vesting reward should be set to 100_000 WOW"
        );
        assertEq(
            nftContract.getLevelData(4).vestingRewardWOWTokens,
            LEVEL_4_VESTING_REWARD,
            "Level 1 vesting reward should be set to 50 WOW"
        );
    }

    function test_initialize_SetsMaxLevelCorrectly() external initializeNft {
        assertEq(
            nftContract.getMaxLevel(),
            5,
            "Max level should be set to 5 by default"
        );
    }

    function test_initialize_SetsVestingContractCorrectly()
        external
        initializeNft
        setNftDataForContract
    {
        assertEq(
            address(nftContract.getVestingContract()),
            address(vesting),
            "Vesting contract should be set correctly"
        );
    }

    function test_initialize_SetsNameCorrectly() external initializeNft {
        assertEq(
            nftContract.name(),
            "Wealth of Wisdom",
            "Name not set correctly"
        );
    }

    function test_initialize_SetsSymbolCorrectly() external initializeNft {
        assertEq(nftContract.symbol(), "WOW", "Symbol not set correctly");
    }

    function test_initialize_GrantsDefaultAdminRoleToDeployer()
        external
        initializeNft
        setNftDataForContract
    {
        assertTrue(
            nftContract.hasRole(DEFAULT_ADMIN_ROLE, admin),
            "Admin role not granted to deployer"
        );
    }

    function test_initialize_GrantsMinterRoleToDeployer()
        external
        initializeNft
        setNftDataForContract
    {
        assertTrue(
            nftContract.hasRole(MINTER_ROLE, admin),
            "Minter role not granted to deployer"
        );
    }

    function test_initialize_GrantsUpgraderRoleToDeployer()
        external
        initializeNft
        setNftDataForContract
    {
        assertTrue(
            nftContract.hasRole(UPGRADER_ROLE, admin),
            "Upgrader role not granted to deployer"
        );
    }

    function test_initialize_GrantsWhitelistedSenderRoleToDeployer()
        external
        initializeNft
        setNftDataForContract
    {
        assertTrue(
            nftContract.hasRole(WHITELISTED_SENDER_ROLE, admin),
            "Whitelisted sender role not granted to deployer"
        );
    }

    function test_initialize_SetsNextTokenIdToZero() external initializeNft {
        assertEq(
            nftContract.getNextTokenId(),
            0,
            "Next token ID not set to zero"
        );
    }

    function test_initialize_RevertIf_ContractAlreadyInitialized()
        external
        initializeNft
        setNftDataForContract
    {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        nftContract.initialize(
            "Wealth of Wisdom",
            "WOW",
            vesting,
            MAX_LEVEL,
            DEFAULT_VESTING_PID,
            GENESIS_TOKEN_DIVISOR
        );
        vm.stopPrank();
    }

    function test_initialize_EmitInitializedEvent() external {
        vm.expectEmit(true, true, true, true);
        emit Initialized(1);

        vm.prank(admin);
        nftContract.initialize(
            "Wealth of Wisdom",
            "WOW",
            vesting,
            MAX_LEVEL,
            DEFAULT_VESTING_PID,
            GENESIS_TOKEN_DIVISOR
        );
    }
}
