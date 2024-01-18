// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {INftSaleEvents} from "@wealth-of-wisdom/nft/contracts/interfaces/INftSale.sol";
import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
import {NftSaleMock} from "@wealth-of-wisdom/nft/test/mocks/NftSaleMock.sol";
import {VestingMock} from "@wealth-of-wisdom/vesting/test/mocks/VestingMock.sol";
import {Nft} from "@wealth-of-wisdom/nft/contracts/Nft.sol";
import {INft} from "@wealth-of-wisdom/nft/contracts/interfaces/INft.sol";
import {Base_Test} from "@wealth-of-wisdom/nft/test/Base.t.sol";

contract Nft_Unit_Test is Base_Test {
    constructor() Base_Test() {}

    function setUp() public virtual override {
        Base_Test.setUp();

        vm.startPrank(admin);
        nftContract = new Nft();
        nftContract.initialize("WOW nft", "NFT");
        vm.stopPrank();
    }
}
