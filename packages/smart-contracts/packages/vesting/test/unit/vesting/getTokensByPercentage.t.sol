// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Vesting_GetTokensByPercentage_Unit_Test is Unit_Test {
    uint256 internal totalAmount = 1 ether;

    function test_getTokensByPercentage_ReturnsZeroIfDividendIsZero() external {
        uint16 dividend = 0;
        uint16 divisor = 100;

        uint256 result = vesting.exposed_getTokensByPercentage(
            totalAmount,
            dividend,
            divisor
        );

        assertEq(result, 0, "Should return zero");
    }

    function test_getTokensByPercentage_RevertIf_DivisorIsZero() external {
        uint16 dividend = 100;
        uint16 divisor = 0;

        vm.expectRevert(Errors.Vesting__PercentageDivisorZero.selector);
        vesting.exposed_getTokensByPercentage(totalAmount, dividend, divisor);
    }

    function test_getTokensByPercentage_ReturnsTotalAmountIfDividendIs100()
        external
    {
        uint16 dividend = 100;
        uint16 divisor = 100;

        uint256 result = vesting.exposed_getTokensByPercentage(
            totalAmount,
            dividend,
            divisor
        );

        assertEq(result, totalAmount, "Should return total amount");
    }

    function test_getTokensByPercentage_ReturnsHalfOfTotalAmountIfDividendIs50()
        external
    {
        uint16 dividend = 50;
        uint16 divisor = 100;

        uint256 result = vesting.exposed_getTokensByPercentage(
            totalAmount,
            dividend,
            divisor
        );

        assertEq(result, totalAmount / 2, "Should return half of total amount");
    }
}
