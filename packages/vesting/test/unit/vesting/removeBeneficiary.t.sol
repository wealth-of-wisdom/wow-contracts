// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVesting} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Vesting_Unit_Test} from "./VestingUnit.t.sol";

contract Vesting_RemoveBeneficiary_Unit_Test is Vesting_Unit_Test {
    uint256 calculatedUnlockedPoolTokens =
        TOTAL_POOL_TOKEN_AMOUNT -
            (BENEFICIARY_TOKEN_AMOUNT * CLIFF_PERCENTAGE_DIVIDEND) /
            CLIFF_PERCENTAGE_DIVISOR -
            (BENEFICIARY_TOKEN_AMOUNT * LISTING_PERCENTAGE_DIVIDEND) /
            LISTING_PERCENTAGE_DIVISOR;

    function test_removeBeneficiary_RevertIf_NotAdmin() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                alice,
                DEFAULT_ADMIN_ROLE
            )
        );
        vm.prank(alice);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);
    }

    function test_removeBeneficiary_RevertIf_PoolDoesNotExist() external {
        vm.expectRevert(Errors.Vesting__PoolDoesNotExist.selector);
        vm.prank(admin);
        vesting.removeBeneficiary(PRIMARY_POOL, alice);
    }

    function test_removeBeneficiary_RevertIf_BeneficiaryDoesNotExist()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__BeneficiaryDoesNotExist.selector);
        vm.prank(admin);
        vesting.removeBeneficiary(PRIMARY_POOL, bob);
    }

    /// @todo update tests when we have decided on the behavior of removing a beneficiary
    // function test_removeBeneficiary_RemovesDuringCliffPeriod_WhenNoTokensWereClaimed()
    //     external
    //     approveAndAddPool
    // {
    //     vm.startPrank(admin);
    //     vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);

    //     vm.warp(1000001);
    //     vesting.removeBeneficiary(PRIMARY_POOL, alice);
    //     vm.stopPrank();

    //     IVesting.Beneficiary memory aliceBeneficiary = vesting.getBeneficiary(
    //         PRIMARY_POOL,
    //         alice
    //     );

    //     assertBeneficiaryData(aliceBeneficiary, 0, 0);
    //     assertGeneralPoolData(
    //         vesting,
    //         PRIMARY_POOL,
    //         calculatedUnlockedPoolTokens
    //     );
    // }

    // function test_removeBeneficiary_RemovesDuringCliffPeriod_WhenTokensWereClaimedDuringCliff()
    //     external
    // {
    //     _addDefaultVestingPool();
    //     checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
    //     vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
    //     vm.warp(1000001);
    //     vm.prank(alice);
    //     vesting.claimTokens(PRIMARY_POOL);
    //     vesting.removeBeneficiary(PRIMARY_POOL, alice);
    //     _validateBeneficiaryData(PRIMARY_POOL, alice, 0, 0);
    //     checkPoolState(PRIMARY_POOL, calculatedUnlockedPoolTokens);
    // }

    // function test_removeBeneficiary_RemoveDuringBegginingOfVesting_WhenNoTokensWereClaimed()
    //     external
    // {
    //     _addDefaultVestingPool();
    //     checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
    //     vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
    //     vm.warp(1000000);
    //     vesting.removeBeneficiary(PRIMARY_POOL, alice);
    //     _validateBeneficiaryData(PRIMARY_POOL, alice, 0, 0);
    //     checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
    // }

    // function test_removeBeneficiary_RemoveDuringBegginingOfVesting_WhenTokensWereClaimedDuringCliff()
    //     external
    // {
    //     _addDefaultVestingPool();
    //     checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
    //     vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
    //     vm.warp(1000001);
    //     vm.prank(alice);
    //     vesting.claimTokens(PRIMARY_POOL);
    //     vesting.removeBeneficiary(PRIMARY_POOL, alice);
    //     _validateBeneficiaryData(PRIMARY_POOL, alice, 0, 0);
    //     checkPoolState(PRIMARY_POOL, calculatedUnlockedPoolTokens);
    // }

    // function test_removeBeneficiary_RemoveDuringVesting_WhenNoTokensWereClaimed()
    //     external
    // {
    //     _addDefaultVestingPool();
    //     checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
    //     vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
    //     vesting.removeBeneficiary(PRIMARY_POOL, alice);
    //     _validateBeneficiaryData(PRIMARY_POOL, alice, 0, 0);
    //     checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
    // }

    // function test_removeBeneficiary_RemoveDuringVesting_WhenTokensWereClaimedDuringCliff()
    //     external
    // {
    //     _addDefaultVestingPool();
    //     checkPoolState(PRIMARY_POOL, TOTAL_POOL_TOKEN_AMOUNT);
    //     vesting.addBeneficiary(PRIMARY_POOL, alice, BENEFICIARY_TOKEN_AMOUNT);
    //     vm.warp(1000001);
    //     vm.prank(alice);
    //     vesting.claimTokens(PRIMARY_POOL);
    //     vm.warp(2);
    //     vesting.removeBeneficiary(PRIMARY_POOL, alice);
    //     _validateBeneficiaryData(PRIMARY_POOL, alice, 0, 0);
    //     checkPoolState(PRIMARY_POOL, calculatedUnlockedPoolTokens);
    // }
}
