// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {INftSaleEvents} from "../../contracts/interfaces/INftSale.sol";
import {NftSaleMock} from "../mocks/NftSaleMock.sol";
import {NftMock} from "../mocks/NftMock.sol";
import {Base_Test} from "../Base.t.sol";

contract NftSale_Unit_Test is Base_Test, INftSaleEvents {
    constructor() Base_Test() {}

    function setUp() public virtual override {
        Base_Test.setUp();

        vm.startPrank(admin);
        nftContract = new NftMock();
        nftContract.initialize("WOW nft", "NFT");

        sale = new NftSaleMock();
        sale.initialize(tokenUSDT, tokenUSDC, nftContract);

        nftContract.grantRole(MINTER_ROLE, address(sale));

        vm.stopPrank();
    }
}
