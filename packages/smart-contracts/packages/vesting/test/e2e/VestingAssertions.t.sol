// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IVesting} from "../../contracts/interfaces/IVesting.sol";
import {Errors} from "../../contracts/libraries/Errors.sol";
import {VestingMock} from "../mocks/VestingMock.sol";
import {StakingMock} from "../mocks/StakingMock.sol";
import {VestingMock} from "../mocks/VestingMock.sol";
import {Base_Test} from "../Base.t.sol";

contract VestingAssertions is Base_Test {
    struct Balances {
        uint256 vestingBalanceBefore;
        uint256 vestingBalanceAfter;
        uint256 adminBalanceBefore;
        uint256 adminBalanceAfter;
        uint256 aliceBalanceBefore;
        uint256 bobBalanceBefore;
    }
    struct PoolData {
        uint16 pid;
        string name;
        uint16 listingPercentageDividend;
        uint16 listingPercentageDivisor;
        uint16 cliffInDays;
        uint16 cliffPercentageDividend;
        uint16 cliffPercentageDivisor;
        uint16 vestingDurationInMonths;
        IVesting.UnlockTypes unlockType;
        uint256 totalPoolTokenAmount;
        uint256 vestingBalanceBefore;
        uint256 adminBalanceBefore;
    }

    function setUp() public virtual override {
        Base_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function assertPoolData(PoolData memory poolData) internal {
        Balances memory balances;

        balances.vestingBalanceAfter = wowToken.balanceOf(address(vesting));
        balances.adminBalanceAfter = wowToken.balanceOf(admin);
        (
            string memory nameSet,
            IVesting.UnlockTypes unlockTypeSet,
            uint256 totalAmountSet,

        ) = vesting.getGeneralPoolData(poolData.pid);
        (uint16 listingDividendSet, uint16 listingDivisorSet) = vesting
            .getPoolListingData(poolData.pid);
        (
            ,
            uint16 cliffInDaysSet,
            uint16 cliffDividendSet,
            uint16 cliffDivisorSet
        ) = vesting.getPoolCliffData(poolData.pid);
        (, uint16 vestingDurationInMonthsSet, ) = vesting.getPoolVestingData(
            poolData.pid
        );

        assertEq(poolData.name, nameSet, "Pool name incorrect");
        assertEq(
            poolData.listingPercentageDividend,
            listingDividendSet,
            "Listing percentage dividend incorrect"
        );
        assertEq(
            poolData.listingPercentageDivisor,
            listingDivisorSet,
            "Listing percentage divisor incorrect"
        );
        assertEq(
            poolData.cliffInDays,
            cliffInDaysSet,
            "Cliff in days incorrect"
        );
        assertEq(
            poolData.cliffPercentageDivisor,
            cliffDivisorSet,
            "Cliff percentage divisor incorrect"
        );
        assertEq(
            poolData.cliffPercentageDividend,
            cliffDividendSet,
            "Cliff percentage dividend incorrect"
        );
        assertEq(
            poolData.vestingDurationInMonths,
            vestingDurationInMonthsSet,
            "Vesting duration in months incorrect"
        );
        assertEq(
            uint8(poolData.unlockType),
            uint8(unlockTypeSet),
            "Unlock type incorrect"
        );
        assertEq(
            poolData.totalPoolTokenAmount,
            totalAmountSet,
            "Total pool token amount incorrect"
        );

        assertEq(
            poolData.vestingBalanceBefore + totalAmountSet,
            balances.vestingBalanceAfter,
            "Vesting contract balance incorrect"
        );
        assertEq(
            poolData.adminBalanceBefore - totalAmountSet,
            balances.adminBalanceAfter,
            "Admin account balance incorrect"
        );
    }

    function assertBeneficiaryData(
        uint16 pid,
        address staker,
        uint256 stakedAmount,
        uint256 claimedAmount,
        uint256 beneficiaryTokenAmounts,
        uint256 lockedAmount,
        uint16 listingPercentageDividend,
        uint16 listingPercentageDivisor,
        uint16 cliffPercentageDividend,
        uint16 cliffPercentageDivisor
    ) internal {
        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            pid,
            staker
        );
        (, , , uint256 lockedAmountSet) = vesting.getGeneralPoolData(pid);

        assertEq(lockedAmountSet, lockedAmount, "Incorrect locked amount");
        assertEq(
            beneficiary.totalTokenAmount,
            beneficiaryTokenAmounts,
            "Incorrect user total token amount"
        );
        assertEq(
            beneficiary.listingTokenAmount,
            (beneficiaryTokenAmounts * listingPercentageDividend) /
                listingPercentageDivisor,
            "Incorrect user listing token amount"
        );
        assertEq(
            beneficiary.cliffTokenAmount,
            (beneficiaryTokenAmounts * cliffPercentageDividend) /
                cliffPercentageDivisor,
            "Incorrect user cliff token amount"
        );
        assertEq(
            beneficiary.vestedTokenAmount,
            beneficiaryTokenAmounts -
                beneficiary.listingTokenAmount -
                beneficiary.cliffTokenAmount,
            "Incorrect user vested token amount"
        );
        assertEq(
            beneficiary.stakedTokenAmount,
            stakedAmount,
            "Incorrect staked token amount"
        );
        assertEq(
            beneficiary.claimedTokenAmount,
            claimedAmount,
            "Incorrect claimed token amount"
        );
    }

    function assertStakerVestedData(
        uint16 pid,
        address staker,
        uint256 beneficiaryTokenAmount
    ) internal {
        IVesting.Beneficiary memory user = vesting.getBeneficiary(pid, staker);
        assertEq(
            user.stakedTokenAmount,
            beneficiaryTokenAmount,
            "Staked tokens not set"
        );
    }

    function assertTokensClaimed(
        uint16 pid,
        address staker,
        uint256 sakerBalanceBefore,
        uint256 vestingBalanceBefore,
        uint256 unlockedTokenAmount
    ) internal {
        uint256 stakerBalanceAfter = wowToken.balanceOf(staker);
        uint256 vestingBalanceAfter = wowToken.balanceOf(address(vesting));
        IVesting.Beneficiary memory beneficiary = vesting.getBeneficiary(
            pid,
            staker
        );
        assertEq(sakerBalanceBefore + unlockedTokenAmount, stakerBalanceAfter);
        assertEq(
            vestingBalanceBefore - unlockedTokenAmount,
            vestingBalanceAfter
        );
        assertEq(beneficiary.claimedTokenAmount, unlockedTokenAmount);
    }
}
