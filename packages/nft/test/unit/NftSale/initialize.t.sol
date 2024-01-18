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
import {Nft_Unit_Test} from "@wealth-of-wisdom/nft/test/unit/NftUnit.t.sol";

contract NftSale_Initialize_Unit_Test is Nft_Unit_Test {
    modifier initializeNftSale() {
        vm.prank(admin);
        sale.initialize(tokenUSDT, tokenUSDC, INft(address(nftContract)));
        _;
    }

    function setUp() public virtual override {
        Nft_Unit_Test.setUp();

        vm.startPrank(admin);
        vesting = new VestingMock();
        nftContract = new Nft();
        sale = new NftSaleMock();
        vm.stopPrank();
    }

    function test_initialize_RevertIf_USDTTokenIsZeroAddress() external {
        vm.expectRevert(Errors.Nft__ZeroAddress.selector);
        sale.initialize(
            IERC20(ZERO_ADDRESS),
            tokenUSDC,
            INft(address(nftContract))
        );
    }

    function test_initialize_RevertIf_USDCTokenIsZeroAddress() external {
        vm.expectRevert(Errors.Nft__ZeroAddress.selector);
        sale.initialize(
            tokenUSDT,
            IERC20(ZERO_ADDRESS),
            INft(address(nftContract))
        );
    }

    function test_initialize_RevertIf_NftContractIsZeroAddress() external {
        vm.expectRevert(Errors.Nft__ZeroAddress.selector);
        sale.initialize(tokenUSDT, tokenUSDC, INft(ZERO_ADDRESS));
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

    function test_initialize_RevertIf_AlreadyInitialized()
        external
        initializeNftSale
    {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        sale.initialize(tokenUSDT, tokenUSDC, INft(address(nftContract)));
    }

    function test_initialize_EmitsInitializedEvent() external {
        vm.expectEmit(true, true, true, true);
        emit Initialized(1);

        vm.prank(admin);
        sale.initialize(tokenUSDT, tokenUSDC, INft(address(nftContract)));
    }
}
