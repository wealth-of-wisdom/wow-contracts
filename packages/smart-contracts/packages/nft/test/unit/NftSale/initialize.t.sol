// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {INft} from "../../../contracts/interfaces/INft.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {NftMock} from "../../mocks/NftMock.sol";
import {NftSaleMock} from "../../mocks/NftSaleMock.sol";
import {Unit_Test} from "../Unit.t.sol";

contract NftSale_Initialize_Unit_Test is Unit_Test {
    modifier initializeNftSale() {
        vm.prank(admin);
        sale.initialize(tokenUSDT, tokenUSDC, INft(address(nft)));
        _;
    }

    function setUp() public virtual override {
        Unit_Test.setUp();

        vm.startPrank(admin);
        nft = new NftMock();
        sale = new NftSaleMock();
        vm.stopPrank();
    }

    function test_initialize_RevertIf_USDTTokenIsZeroAddress() external {
        vm.expectRevert(Errors.NftSale__ZeroAddress.selector);
        sale.initialize(IERC20(ZERO_ADDRESS), tokenUSDC, INft(address(nft)));
    }

    function test_initialize_RevertIf_USDCTokenIsZeroAddress() external {
        vm.expectRevert(Errors.NftSale__ZeroAddress.selector);
        sale.initialize(tokenUSDT, IERC20(ZERO_ADDRESS), INft(address(nft)));
    }

    function test_initialize_RevertIf_NftContractIsZeroAddress() external {
        vm.expectRevert(Errors.NftSale__ZeroAddress.selector);
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
            address(nft),
            "NFT contract should be set correctly"
        );
    }

    function test_initialize_RevertIf_AlreadyInitialized()
        external
        initializeNftSale
    {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        sale.initialize(tokenUSDT, tokenUSDC, INft(address(nft)));
    }

    function test_initialize_EmitsInitializedEvent() external {
        vm.expectEmit(true, true, true, true);
        emit Initialized(1);

        vm.prank(admin);
        sale.initialize(tokenUSDT, tokenUSDC, INft(address(nft)));
    }
}
