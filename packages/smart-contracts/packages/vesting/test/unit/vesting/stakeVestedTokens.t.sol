// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IVesting, IVestingEvents} from "../../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";
import {Unit_Test} from "../Unit.t.sol";

contract Vesting_StakeVestedTokens_Unit_Test is Unit_Test {
    function test_stakeVestedTokens_RevertIf_PoolDoesNotExist() external {
        vm.expectRevert(Errors.Vesting__PoolDoesNotExist.selector);
        vm.prank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FIX,
            BAND_LEVEL_2,
            MONTH_1,
            PRIMARY_POOL
        );
    }

    function test_stakeVestedTokens_RevertIf_NotBeneficiary()
        external
        approveAndAddPool
    {
        vm.expectRevert(Errors.Vesting__NotBeneficiary.selector);
        vm.prank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FIX,
            BAND_LEVEL_2,
            MONTH_1,
            PRIMARY_POOL
        );
    }

    function test_stakeVestedTokens_RevertIf_NotEnoughVestedTokensForStaking()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.expectRevert(
            Errors.Vesting__NotEnoughVestedTokensForStaking.selector
        );
        vm.prank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FIX,
            BAND_LEVEL_4,
            MONTH_1,
            PRIMARY_POOL
        );
    }

    function test_stakeVestedTokens_UpdatesTokensData()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.prank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FIX,
            BAND_LEVEL_3,
            MONTH_1,
            PRIMARY_POOL
        );

        IVesting.Beneficiary memory user = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            user.stakedTokenAmount,
            BENEFICIARY_TOKEN_AMOUNT,
            "Staked tokens not set"
        );
        assertEq(
            user.totalTokenAmount,
            BENEFICIARY_TOKEN_AMOUNT,
            "Token amount changed"
        );
    }

    function test_stakeVestedTokens_UpdatesTokensData_AfterPriceChanges()
        external
        approveAndAddPool
    {
        uint16[] memory emptyArray;

        vm.startPrank(admin);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BAND_9_PRICE);
        staking.setBandLevel(BAND_LEVEL_1, BAND_2_PRICE, emptyArray);
        vm.stopPrank();

        vm.prank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FIX,
            BAND_LEVEL_1,
            MONTH_1,
            PRIMARY_POOL
        );

        IVesting.Beneficiary memory user = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(user.stakedTokenAmount, BAND_2_PRICE, "Staked tokens not set");
        assertEq(user.totalTokenAmount, BAND_9_PRICE, "Token amount changed");
    }

    function test_stakeVestedTokens_UpdatesTokensData_BeforeAndAfterPriceChanges()
        external
        approveAndAddPool
    {
        uint16[] memory emptyArray;
        vm.prank(admin);
        vesting.addBeneficiary(PRIMARY_POOL, alice, BAND_9_PRICE);

        vm.prank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FIX,
            BAND_LEVEL_1,
            MONTH_1,
            PRIMARY_POOL
        );

        vm.prank(admin);
        staking.setBandLevel(BAND_LEVEL_1, BAND_2_PRICE, emptyArray);

        vm.prank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FIX,
            BAND_LEVEL_1,
            MONTH_1,
            PRIMARY_POOL
        );

        IVesting.Beneficiary memory user = vesting.getBeneficiary(
            PRIMARY_POOL,
            alice
        );
        assertEq(
            user.stakedTokenAmount,
            BAND_1_PRICE + BAND_2_PRICE,
            "Staked tokens not set"
        );
        assertEq(user.totalTokenAmount, BAND_9_PRICE, "Token amount changed");
    }

    function test_stakeVestedTokens_CallsStakingContractToStakeVestedTokens()
        external
        approveAndAddPool
        addBeneficiary(alice)
    {
        vm.expectCall(
            address(vesting),
            abi.encodeWithSelector(
                IVesting.stakeVestedTokens.selector,
                STAKING_TYPE_FIX,
                BAND_LEVEL_1,
                MONTH_1,
                PRIMARY_POOL
            )
        );
        vm.prank(alice);
        vesting.stakeVestedTokens(
            STAKING_TYPE_FIX,
            BAND_LEVEL_1,
            MONTH_1,
            PRIMARY_POOL
        );
    }
}
