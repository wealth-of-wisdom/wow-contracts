// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {StdAssertions} from "forge-std/Test.sol";
import {IVesting} from "../../contracts/interfaces/IVesting.sol";
import {Constants} from "./Constants.sol";

abstract contract Assertions is StdAssertions, Constants {
    function assertUnlockType(
        IVesting.UnlockTypes expected,
        IVesting.UnlockTypes actual
    ) internal {
        assertEq(uint8(expected), uint8(actual));
    }

    function assertBeneficiaryData(
        IVesting.Beneficiary memory beneficiary,
        uint256 totalAmount,
        uint256 stakedAmount,
        uint256 claimedAmount
    ) internal {
        uint256 calculatedListingTokenAmount = (totalAmount *
            LISTING_PERCENTAGE_DIVIDEND) / LISTING_PERCENTAGE_DIVISOR;
        uint256 calculateCliffTokenAmount = (totalAmount *
            CLIFF_PERCENTAGE_DIVIDEND) / CLIFF_PERCENTAGE_DIVISOR;
        uint256 calculatedVestedTokenAmount = totalAmount -
            beneficiary.listingTokenAmount -
            beneficiary.cliffTokenAmount;

        assertEq(
            beneficiary.totalTokenAmount,
            totalAmount,
            "totalTokens is incorrect."
        );
        assertEq(
            beneficiary.listingTokenAmount,
            calculatedListingTokenAmount,
            "listingTokenAmount is incorrect"
        );
        assertEq(
            beneficiary.cliffTokenAmount,
            calculateCliffTokenAmount,
            "cliffTokenAmount is incorrect"
        );
        assertEq(
            beneficiary.vestedTokenAmount,
            calculatedVestedTokenAmount,
            "vestedTokenAmount is incorrect"
        );
        assertEq(
            beneficiary.stakedTokenAmount,
            stakedAmount,
            "stakedTokenAmount is incorrect"
        );
        assertEq(
            beneficiary.claimedTokenAmount,
            claimedAmount,
            "claimedTokenAmount is incorrect"
        );
    }

    function assertGeneralPoolData(
        IVesting vesting,
        uint16 poolIndex,
        uint256 expectedDedicatedAmount
    ) internal {
        (
            string memory name,
            IVesting.UnlockTypes unlockType,
            uint256 totalAmount,
            uint256 dedicatedAmount
        ) = vesting.getGeneralPoolData(poolIndex);

        assertEq(POOL_NAME, name, "Pool name is incorrect");
        assertUnlockType(VESTING_UNLOCK_TYPE, unlockType);
        assertEq(
            TOTAL_POOL_TOKEN_AMOUNT,
            totalAmount,
            "Total amount is incorrect"
        );
        assertEq(
            expectedDedicatedAmount,
            dedicatedAmount,
            "Dedicated amount is incorrect"
        );
    }
}
