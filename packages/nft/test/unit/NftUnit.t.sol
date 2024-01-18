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

        vesting = new VestingMock();
        vesting.initialize(tokenUSDT, staking, LISTING_DATE);
        tokenUSDT.approve(address(vesting), TOTAL_POOL_TOKEN_AMOUNT);
        vesting.addVestingPool(
            POOL_NAME,
            LISTING_PERCENTAGE_DIVIDEND,
            LISTING_PERCENTAGE_DIVISOR,
            CLIFF_IN_DAYS,
            CLIFF_PERCENTAGE_DIVIDEND,
            CLIFF_PERCENTAGE_DIVISOR,
            VESTING_DURATION_IN_MONTHS,
            VESTING_UNLOCK_TYPE,
            TOTAL_POOL_TOKEN_AMOUNT
        );

        nftContract = new Nft();
        nftContract.initialize(
            "Wealth of Wisdom",
            "WOW",
            vesting,
            MAXIMUM_LEVEL_AMOUNT,
            DEFAULT_VESTING_PID,
            GENESIS_TOKEN_DIVISOR
        );
        vm.stopPrank();
    }
}
