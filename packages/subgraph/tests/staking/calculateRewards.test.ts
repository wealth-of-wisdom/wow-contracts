import { Address, BigInt, log } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, beforeAll, assert, clearStore, afterEach } from "matchstick-as/assembly/index";
import {
    createDistribution,
    distributeRewards,
    initializeAndSetUp,
    stakeStandardFixed,
    stakeStandardFlexi,
    stakeVestedFixed,
    stakeVestedFlexi,
} from "./helpers/helper";
import {
    ids,
    bandIds,
    usdtToken,
    alice,
    bob,
    usdcToken,
    zeroStr,
    usd100k,
    usd200k,
    usd300k,
    usd400k,
    usd500k,
    totalPools,
    charlie,
    percentagePrecision,
} from "../utils/data/constants";
import { preInitDate, initDate, monthsAfterInit, dayInSeconds } from "../utils/data/dates";
import { sharesInMonths, bandLevels, months, poolDistributionPercentages } from "../utils/data/data";
import { convertAddressArrayToString, convertBigIntArrayToString, createEmptyArray } from "../utils/arrays";
import { BIGINT_ZERO } from "../../src/utils/constants";
import { StakerAndPoolShares } from "../../src/utils/utils";
import { syncAndCalculateAllShares } from "../../src/utils/staking/sharesSync";
import { StakingContract } from "../../generated/schema";
import { getOrInitStakingContract } from "../../src/helpers/staking.helpers";
import { calculateRewards } from "../../src/utils/staking/rewardsCalculation";

let expectedStakers: Address[];
let expectedStakersCount = 0;
let expectedSharesForStakers: BigInt[][];
let expectedSharesForStakersCount = 0;
let expectedSharesForPools: BigInt[];
let expectedSharesForPoolsCount = 0;
let stakerRewards: BigInt[];
let expectedRewards: BigInt[];

describe("calculateRewards", () => {
    beforeEach(() => {
        clearStore();
        initializeAndSetUp();
    });

    describe("FIXED bands and FLEXI bands", () => {
        describe("1 staker, 1 FIXED and 1 FLEXI", () => {
            describe("More than 2 months", () => {
                beforeEach(() => {
                    stakeStandardFixed(alice, bandLevels[4], bandIds[0], months[10], monthsAfterInit[1]);
                    stakeStandardFlexi(alice, bandLevels[7], bandIds[1], monthsAfterInit[1].plus(dayInSeconds));

                    const fixedShares = sharesInMonths[9];
                    const flexiShares = sharesInMonths[0];
                    const totalShares = fixedShares.plus(flexiShares);

                    expectedStakers = [alice];
                    expectedStakersCount = expectedStakers.length;
                    expectedSharesForStakers = [
                        [
                            totalShares,
                            totalShares,
                            totalShares,
                            totalShares,
                            totalShares,
                            flexiShares,
                            flexiShares,
                            flexiShares,
                            BIGINT_ZERO,
                        ],
                    ];
                    expectedSharesForStakersCount = expectedSharesForStakers.length;
                    expectedSharesForPools = expectedSharesForStakers[0];
                    expectedSharesForPoolsCount = expectedSharesForPools.length;

                    const aliceRewards = usd100k.minus(
                        usd100k.times(poolDistributionPercentages[8]).div(percentagePrecision),
                    );

                    expectedRewards = [aliceRewards];

                    const stakingContract: StakingContract = getOrInitStakingContract();
                    const sharesData: StakerAndPoolShares = syncAndCalculateAllShares(
                        stakingContract,
                        monthsAfterInit[2].plus(dayInSeconds),
                    );
                    stakerRewards = calculateRewards(stakingContract, usd100k, sharesData);
                });

                /*//////////////////////////////////////////////////////////////////////////
                                                ASSERT MAIN DATA
                //////////////////////////////////////////////////////////////////////////*/

                test("Should return the correct amount of rewards", () => {
                    assert.i32Equals(stakerRewards.length, expectedStakersCount);
                });

                test("Should return stakers' rewards", () => {
                    for (let i = 0; i < expectedStakersCount; i++) {
                        assert.bigIntEquals(stakerRewards[i], expectedRewards[i]);
                    }
                });
            });

            describe("2 months", () => {
                beforeEach(() => {
                    stakeStandardFixed(alice, bandLevels[4], bandIds[0], months[10], monthsAfterInit[1]);
                    stakeStandardFlexi(alice, bandLevels[7], bandIds[1], monthsAfterInit[1].plus(dayInSeconds));

                    const fixedShares = sharesInMonths[9];
                    const flexiShares = BIGINT_ZERO;
                    const totalShares = fixedShares.plus(flexiShares);

                    expectedStakers = [alice];
                    expectedStakersCount = expectedStakers.length;
                    expectedSharesForStakers = [
                        [
                            totalShares,
                            totalShares,
                            totalShares,
                            totalShares,
                            totalShares,
                            flexiShares,
                            flexiShares,
                            flexiShares,
                            BIGINT_ZERO,
                        ],
                    ];
                    expectedSharesForStakersCount = expectedSharesForStakers.length;
                    expectedSharesForPools = expectedSharesForStakers[0];
                    expectedSharesForPoolsCount = expectedSharesForPools.length;

                    const aliceRewards = usd100k
                        .times(
                            poolDistributionPercentages[0]
                                .plus(poolDistributionPercentages[1])
                                .plus(poolDistributionPercentages[2])
                                .plus(poolDistributionPercentages[3])
                                .plus(poolDistributionPercentages[4]),
                        )
                        .div(percentagePrecision);

                    expectedRewards = [aliceRewards];

                    const stakingContract: StakingContract = getOrInitStakingContract();
                    const sharesData: StakerAndPoolShares = syncAndCalculateAllShares(
                        stakingContract,
                        monthsAfterInit[2],
                    );
                    stakerRewards = calculateRewards(stakingContract, usd100k, sharesData);
                });

                /*//////////////////////////////////////////////////////////////////////////
                                                ASSERT MAIN DATA
                //////////////////////////////////////////////////////////////////////////*/

                test("Should return the correct amount of rewards", () => {
                    assert.i32Equals(stakerRewards.length, expectedStakersCount);
                });

                test("Should return stakers' rewards", () => {
                    for (let i = 0; i < expectedStakersCount; i++) {
                        assert.bigIntEquals(stakerRewards[i], expectedRewards[i]);
                    }
                });
            });
        });

        describe("2 staker, 2 FIXED and 2 FLEXI", () => {
            describe("More than 5 months", () => {
                beforeEach(() => {
                    stakeStandardFixed(alice, bandLevels[0], bandIds[0], months[10], monthsAfterInit[1]);
                    stakeVestedFixed(bob, bandLevels[4], bandIds[1], months[24], monthsAfterInit[2]);
                    stakeVestedFlexi(alice, bandLevels[2], bandIds[2], monthsAfterInit[3].plus(dayInSeconds));
                    stakeStandardFlexi(bob, bandLevels[6], bandIds[3], monthsAfterInit[4]);

                    const fixedShares1 = sharesInMonths[9];
                    const flexiShares1 = sharesInMonths[1];
                    const totalShares1 = fixedShares1.plus(flexiShares1);
                    const fixedShares2 = sharesInMonths[23];
                    const flexiShares2 = sharesInMonths[0];
                    const totalShares2 = fixedShares2.plus(flexiShares2);

                    expectedStakers = [alice, bob];
                    expectedStakersCount = expectedStakers.length;
                    expectedSharesForStakers = [
                        [
                            totalShares1,
                            flexiShares1,
                            flexiShares1,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                        ],
                        [
                            totalShares2,
                            totalShares2,
                            totalShares2,
                            totalShares2,
                            totalShares2,
                            flexiShares2,
                            flexiShares2,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                        ],
                    ];
                    expectedSharesForStakersCount = expectedSharesForStakers.length;

                    expectedSharesForPools = createEmptyArray(totalPools);
                    for (let i = 0; i < totalPools.toI32(); i++) {
                        for (let j = 0; j < expectedStakersCount; j++) {
                            expectedSharesForPools[i] = expectedSharesForPools[i].plus(expectedSharesForStakers[j][i]);
                        }
                    }
                    expectedSharesForPoolsCount = expectedSharesForPools.length;

                    const aliceRewards = usd100k
                        .times(poolDistributionPercentages[0])
                        .div(percentagePrecision)
                        .times(totalShares1)
                        .div(expectedSharesForPools[0])
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[1])
                                .div(percentagePrecision)
                                .times(flexiShares1)
                                .div(expectedSharesForPools[1]),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[2])
                                .div(percentagePrecision)
                                .times(flexiShares1)
                                .div(expectedSharesForPools[2]),
                        );
                    const bobRewards = usd100k
                        .times(poolDistributionPercentages[0])
                        .div(percentagePrecision)
                        .times(totalShares2)
                        .div(expectedSharesForPools[0])
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[1])
                                .div(percentagePrecision)
                                .times(totalShares2)
                                .div(expectedSharesForPools[1]),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[2])
                                .div(percentagePrecision)
                                .times(totalShares2)
                                .div(expectedSharesForPools[2]),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[3])
                                .div(percentagePrecision)
                                .times(totalShares2)
                                .div(expectedSharesForPools[3]),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[4])
                                .div(percentagePrecision)
                                .times(totalShares2)
                                .div(expectedSharesForPools[4]),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[5])
                                .div(percentagePrecision)
                                .times(flexiShares2)
                                .div(expectedSharesForPools[5]),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[6])
                                .div(percentagePrecision)
                                .times(flexiShares2)
                                .div(expectedSharesForPools[6]),
                        );

                    expectedRewards = [aliceRewards, bobRewards];

                    const stakingContract: StakingContract = getOrInitStakingContract();
                    const sharesData: StakerAndPoolShares = syncAndCalculateAllShares(
                        stakingContract,
                        monthsAfterInit[5].plus(dayInSeconds),
                    );
                    stakerRewards = calculateRewards(stakingContract, usd100k, sharesData);
                });

                /*//////////////////////////////////////////////////////////////////////////
                                                ASSERT MAIN DATA
                //////////////////////////////////////////////////////////////////////////*/

                test("Should return the correct amount of rewards", () => {
                    assert.i32Equals(stakerRewards.length, expectedStakersCount);
                });

                test("Should return stakers' rewards", () => {
                    for (let i = 0; i < expectedStakersCount; i++) {
                        assert.bigIntEquals(stakerRewards[i], expectedRewards[i]);
                    }
                });
            });

            describe("5 months", () => {
                beforeEach(() => {
                    stakeStandardFixed(alice, bandLevels[0], bandIds[0], months[10], monthsAfterInit[1]);
                    stakeVestedFixed(bob, bandLevels[4], bandIds[1], months[24], monthsAfterInit[2]);
                    stakeVestedFlexi(alice, bandLevels[2], bandIds[2], monthsAfterInit[3].plus(dayInSeconds));
                    stakeStandardFlexi(bob, bandLevels[6], bandIds[3], monthsAfterInit[4]);

                    const fixedShares1 = sharesInMonths[9];
                    const flexiShares1 = sharesInMonths[0];
                    const totalShares1 = fixedShares1.plus(flexiShares1);
                    const fixedShares2 = sharesInMonths[23];
                    const flexiShares2 = sharesInMonths[0];
                    const totalShares2 = fixedShares2.plus(flexiShares2);

                    expectedStakers = [alice, bob];
                    expectedStakersCount = expectedStakers.length;
                    expectedSharesForStakers = [
                        [
                            totalShares1,
                            flexiShares1,
                            flexiShares1,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                        ],
                        [
                            totalShares2,
                            totalShares2,
                            totalShares2,
                            totalShares2,
                            totalShares2,
                            flexiShares2,
                            flexiShares2,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                        ],
                    ];
                    expectedSharesForStakersCount = expectedSharesForStakers.length;

                    expectedSharesForPools = createEmptyArray(totalPools);
                    for (let i = 0; i < totalPools.toI32(); i++) {
                        for (let j = 0; j < expectedStakersCount; j++) {
                            expectedSharesForPools[i] = expectedSharesForPools[i].plus(expectedSharesForStakers[j][i]);
                        }
                    }
                    expectedSharesForPoolsCount = expectedSharesForPools.length;

                    const aliceRewards = usd100k
                        .times(poolDistributionPercentages[0])
                        .div(percentagePrecision)
                        .times(totalShares1)
                        .div(expectedSharesForPools[0])
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[1])
                                .div(percentagePrecision)
                                .times(flexiShares1)
                                .div(expectedSharesForPools[1]),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[2])
                                .div(percentagePrecision)
                                .times(flexiShares1)
                                .div(expectedSharesForPools[2]),
                        );
                    const bobRewards = usd100k
                        .times(poolDistributionPercentages[0])
                        .div(percentagePrecision)
                        .times(totalShares2)
                        .div(expectedSharesForPools[0])
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[1])
                                .div(percentagePrecision)
                                .times(totalShares2)
                                .div(expectedSharesForPools[1]),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[2])
                                .div(percentagePrecision)
                                .times(totalShares2)
                                .div(expectedSharesForPools[2]),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[3])
                                .div(percentagePrecision)
                                .times(totalShares2)
                                .div(expectedSharesForPools[3]),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[4])
                                .div(percentagePrecision)
                                .times(totalShares2)
                                .div(expectedSharesForPools[4]),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[5])
                                .div(percentagePrecision)
                                .times(flexiShares2)
                                .div(expectedSharesForPools[5]),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[6])
                                .div(percentagePrecision)
                                .times(flexiShares2)
                                .div(expectedSharesForPools[6]),
                        );

                    expectedRewards = [aliceRewards, bobRewards];

                    const stakingContract: StakingContract = getOrInitStakingContract();
                    const sharesData: StakerAndPoolShares = syncAndCalculateAllShares(
                        stakingContract,
                        monthsAfterInit[5],
                    );
                    stakerRewards = calculateRewards(stakingContract, usd100k, sharesData);
                });

                /*//////////////////////////////////////////////////////////////////////////
                                                ASSERT MAIN DATA
                //////////////////////////////////////////////////////////////////////////*/

                test("Should return the correct amount of rewards", () => {
                    assert.i32Equals(stakerRewards.length, expectedStakersCount);
                });

                test("Should return stakers' rewards", () => {
                    for (let i = 0; i < expectedStakersCount; i++) {
                        assert.bigIntEquals(stakerRewards[i], expectedRewards[i]);
                    }
                });
            });
        });
    });
});
