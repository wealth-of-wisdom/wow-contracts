// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IVesting} from "@wealth-of-wisdom/vesting/contracts/interfaces/IVesting.sol";
import {INft, INftEvents} from "../../contracts/interfaces/INft.sol";
import {INftSaleEvents} from "../../contracts/interfaces/INftSale.sol";
import {NftMock} from "../mocks/NftMock.sol";
import {NftSaleMock} from "../mocks/NftSaleMock.sol";
import {VestingMock} from "../mocks/VestingMock.sol";
import {Base_Test} from "../Base.t.sol";

contract Unit_Test is Base_Test, INftSaleEvents, INftEvents {
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

        nft = new NftMock();
        nft.initialize(
            "Wealth of Wisdom",
            "WOW",
            vesting,
            LEVEL_5_SUPPLY_CAP,
            DEFAULT_VESTING_PID,
            MAX_LEVEL,
            TOTAL_PROJECT_TYPES
        );

        sale = new NftSaleMock();
        sale.initialize(tokenUSDT, tokenUSDC, INft(address(nft)));

        nft.grantRole(MINTER_ROLE, address(sale));
        nft.grantRole(NFT_DATA_MANAGER_ROLE, address(sale));
        vesting.grantRole(BENEFICIARIES_MANAGER_ROLE, address(nft));

        vm.stopPrank();
    }
}
