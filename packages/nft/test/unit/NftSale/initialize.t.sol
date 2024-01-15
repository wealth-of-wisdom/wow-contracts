// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
import {VestingMock} from "@wealth-of-wisdom/vesting/test/mocks/VestingMock.sol";
import {Nft} from "@wealth-of-wisdom/nft/contracts/Nft.sol";
import {INft} from "@wealth-of-wisdom/nft/contracts/interfaces/INft.sol";
import {Errors} from "@wealth-of-wisdom/nft/contracts/libraries/Errors.sol";
import {NftSaleMock} from "@wealth-of-wisdom/nft/test/mocks/NftSaleMock.sol";
import {NftSale_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftSaleUnit.t.sol";

contract NftSale_Initialize_Unit_Test is NftSale_Unit_Test {
    modifier initializeNftSale() {
        vm.prank(admin);
        sale.initialize(
            tokenUSDT,
            tokenUSDC,
            INft(address(nftContract)),
            vesting,
            DEFAULT_VESTING_PID
        );
        _;
    }

    function setUp() public virtual override {
        NftSale_Unit_Test.setUp();

        vm.startPrank(admin);
        vesting = new VestingMock();
        nftContract = new Nft();
        sale = new NftSaleMock();
        vm.stopPrank();
    }

    function test_initialize_RevertIf_USDTTokenIsZeroAddress() external {
        vm.expectRevert(Errors.NftSale__ZeroAddress.selector);
        sale.initialize(
            IERC20(ZERO_ADDRESS),
            tokenUSDC,
            INft(address(nftContract)),
            vesting,
            DEFAULT_VESTING_PID
        );
    }

    function test_initialize_RevertIf_USDCTokenIsZeroAddress() external {
        vm.expectRevert(Errors.NftSale__ZeroAddress.selector);
        sale.initialize(
            tokenUSDT,
            IERC20(ZERO_ADDRESS),
            INft(address(nftContract)),
            vesting,
            DEFAULT_VESTING_PID
        );
    }

    function test_initialize_RevertIf_NftContractIsZeroAddress() external {
        vm.expectRevert(Errors.NftSale__ZeroAddress.selector);
        sale.initialize(
            tokenUSDT,
            tokenUSDC,
            INft(ZERO_ADDRESS),
            vesting,
            DEFAULT_VESTING_PID
        );
    }

    function test_initialize_RevertIf_VestingContractIsZeroAddress() external {
        vm.expectRevert(Errors.NftSale__ZeroAddress.selector);
        sale.initialize(
            tokenUSDT,
            tokenUSDC,
            INft(address(nftContract)),
            IVesting(ZERO_ADDRESS),
            DEFAULT_VESTING_PID
        );
    }

    function test_initialize_GrantsDefaultAdminRoleToDeployer()
        external
        initializeNftSale
    {
        assertTrue(
            sale.hasRole(DEFAULT_ADMIN_ROLE, admin),
            "Admin should have default admin role"
        );
    }

    function test_initialize_GrantsUpgraderRoleToDeployer()
        external
        initializeNftSale
    {
        assertTrue(
            sale.hasRole(UPGRADER_ROLE, admin),
            "Admin should have default admin role"
        );
    }

    function test_initialize_SetsMaxLevelCorrectly()
        external
        initializeNftSale
    {
        assertEq(
            sale.getMaxLevel(),
            5,
            "Max level should be set to 5 by default"
        );
    }

    function test_initialize_SetsPromotionalVestingPIDCorrectly() external {
        uint16 pid = 10;

        vm.prank(admin);
        sale.initialize(
            tokenUSDT,
            tokenUSDC,
            INft(address(nftContract)),
            vesting,
            pid
        );

        assertEq(
            sale.getPromotionalPID(),
            pid,
            "Promotional vesting PID should be set correctly"
        );
    }

    function test_initialize_SetsNftLevelPricesCorrectly()
        external
        initializeNftSale
    {
        assertEq(
            sale.getLevelPriceInUSD(1),
            1_000 * USD_DECIMALS,
            "Level 1 price should be set to 1_000 USD"
        );
        assertEq(
            sale.getLevelPriceInUSD(2),
            5_000 * USD_DECIMALS,
            "Level 2 price should be set to 5_000 USD"
        );
        assertEq(
            sale.getLevelPriceInUSD(3),
            10_000 * USD_DECIMALS,
            "Level 3 price should be set to 10_000 USD"
        );
        assertEq(
            sale.getLevelPriceInUSD(4),
            33_000 * USD_DECIMALS,
            "Level 4 price should be set to 33_000 USD"
        );
        assertEq(
            sale.getLevelPriceInUSD(5),
            100_000 * USD_DECIMALS,
            "Level 5 price should be set to 100_000 USD"
        );
    }

    function test_initialize_SetsNftLevelVestingRewardWOWTokensCorrectly()
        external
        initializeNftSale
    {
        assertEq(
            sale.getVestingRewardWOWTokens(1),
            1_000 * WOW_DECIMALS,
            "Level 1 vesting reward should be set to 1_000 WOW"
        );
        assertEq(
            sale.getVestingRewardWOWTokens(2),
            25_000 * WOW_DECIMALS,
            "Level 2 vesting reward should be set to 25_000 WOW"
        );
        assertEq(
            sale.getVestingRewardWOWTokens(3),
            100_000 * WOW_DECIMALS,
            "Level 3 vesting reward should be set to 100_000 WOW"
        );
        assertEq(
            sale.getVestingRewardWOWTokens(4),
            660_000 * WOW_DECIMALS,
            "Level 4 vesting reward should be set to 660_000 WOW"
        );
        assertEq(
            sale.getVestingRewardWOWTokens(5),
            3_000_000 * WOW_DECIMALS,
            "Level 5 vesting reward should be set to 3_000_000 WOW"
        );
    }

    function test_initialize_SetsUSDTTokenCorrectly()
        external
        initializeNftSale
    {
        assertEq(
            address(sale.getTokenUSDT()),
            address(tokenUSDT),
            "USDT token should be set correctly"
        );
    }

    function test_initialize_SetsUSDCTokenCorrectly()
        external
        initializeNftSale
    {
        assertEq(
            address(sale.getTokenUSDC()),
            address(tokenUSDC),
            "USDC token should be set correctly"
        );
    }

    function test_initialize_SetsNftContractCorrectly()
        external
        initializeNftSale
    {
        assertEq(
            address(sale.getNftContract()),
            address(nftContract),
            "NFT contract should be set correctly"
        );
    }

    function test_initialize_SetsVestingContractCorrectly()
        external
        initializeNftSale
    {
        assertEq(
            address(sale.getVestingContract()),
            address(vesting),
            "Vesting contract should be set correctly"
        );
    }

    function test_initialize_RevertIf_AlreadyInitialized() external initializeNftSale {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        sale.initialize(
            tokenUSDT,
            tokenUSDC,
            INft(address(nftContract)),
            vesting,
            DEFAULT_VESTING_PID
        );
    }

    function test_initialize_EmitsInitializedEvent() external {
        vm.expectEmit(true, true, true, true);
        emit Initialized(1);

        vm.prank(admin);
        sale.initialize(
            tokenUSDT,
            tokenUSDC,
            INft(address(nftContract)),
            vesting,
            DEFAULT_VESTING_PID
        );
    }
}
