import { Address, BigInt, bigInt, log } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, assert, clearStore, beforeAll } from "matchstick-as/assembly/index";
import {
    initialize,
    stakeStandardFlexi,
    createDistribution,
    distributeRewards,
    initializeAndSetUp,
    stakeStandardFixed,
} from "./helpers/helper";
import { convertBigIntArrayToString, convertStringToWrappedArray } from "../utils/arrays";
import {
    ids,
    bandIds,
    alice,
    usdtToken,
    usd100k,
    zeroStr,
    percentagePrecision,
    bob,
    charlie,
} from "../utils/data/constants";
import { bandLevels, months, poolDistributionPercentages } from "../utils/data/data";
import { preInitDate, initDate, monthsAfterInit, dayInSeconds } from "../utils/data/dates";
import { BIGINT_ONE, BIGINT_TWO, BIGINT_ZERO } from "../../src/utils/constants";
import { getOrInitFundsDistribution, getOrInitStakingContract } from "../../src/helpers/staking.helpers";
import { StakerAndPoolShares } from "../../src/utils/utils";
import { StakingContract } from "../../generated/schema";
import { syncAndCalculateAllShares } from "../../src/utils/staking/sharesSync";
import { calculateRewards } from "../../src/utils/staking/rewardsCalculation";

let stakers: Address[];
let stakersCount = 0;
let rewards: BigInt;
let bandLevel = 0;

describe("handleRewardsDistributed() tests", () => {
    beforeEach(() => {
        clearStore();
        initializeAndSetUp();
    });

    describe("Single distribution", () => {
        describe("1 Staker", () => {
            beforeEach(() => {
                stakeStandardFixed(alice, bandLevels[bandLevel - 1], bandIds[0], months[10], monthsAfterInit[1]);
                createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdtToken, monthsAfterInit[2].plus(BIGINT_ONE));
            });

            describe("Band Level 1", () => {
                beforeAll(() => {
                    bandLevel = 1;
                    rewards = usd100k.times(poolDistributionPercentages[0]).div(percentagePrecision);
                });

                test("Should update staking contract details", () => {
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "false");
                });

                test("Should update distribution details", () => {
                    assert.fieldEquals(
                        "FundsDistribution",
                        ids[0],
                        "distributedAt",
                        monthsAfterInit[2].plus(BIGINT_ONE).toString(),
                    );
                });

                test("Should update staker total unclaimed rewards", () => {
                    assert.fieldEquals("Staker", alice.toHex(), "totalUnclaimedRewards", rewards.toString());
                });

                test("Should update staker single token unclaimed rewards", () => {
                    const id = `${alice.toHex()}-${usdtToken.toHex()}`;
                    assert.fieldEquals("StakerRewards", id, "unclaimedAmount", rewards.toString());
                });
            });

            describe("Band Level 9", () => {
                beforeAll(() => {
                    bandLevel = 9;
                    rewards = usd100k;
                });

                test("Should update staking contract details", () => {
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "false");
                });

                test("Should update distribution details", () => {
                    assert.fieldEquals(
                        "FundsDistribution",
                        ids[0],
                        "distributedAt",
                        monthsAfterInit[2].plus(BIGINT_ONE).toString(),
                    );
                });

                test("Should update staker total unclaimed rewards", () => {
                    assert.fieldEquals("Staker", alice.toHex(), "totalUnclaimedRewards", rewards.toString());
                });

                test("Should update staker single token unclaimed rewards", () => {
                    const id = `${alice.toHex()}-${usdtToken.toHex()}`;
                    assert.fieldEquals("StakerRewards", id, "unclaimedAmount", rewards.toString());
                });
            });
        });

        describe("3 Stakers", () => {
            beforeAll(() => {
                stakers = [alice, bob, charlie];
                stakersCount = stakers.length;
            });

            beforeEach(() => {
                for (let i = 0; i < stakers.length; i++) {
                    stakeStandardFixed(
                        stakers[i],
                        bandLevels[bandLevel - 1],
                        bandIds[i],
                        months[10],
                        monthsAfterInit[1],
                    );
                }
                createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdtToken, monthsAfterInit[2].plus(BIGINT_ONE));

                const stakingContract: StakingContract = getOrInitStakingContract();
                const sharesData: StakerAndPoolShares = syncAndCalculateAllShares(
                    stakingContract,
                    monthsAfterInit[2].plus(dayInSeconds),
                );
                const stakerRewards = calculateRewards(stakingContract, usd100k, sharesData);
            });

            describe("Band Level 1", () => {
                beforeAll(() => {
                    bandLevel = 1;
                    rewards = usd100k
                        .times(poolDistributionPercentages[0])
                        .div(percentagePrecision)
                        .div(BigInt.fromI32(3));
                });

                test("Should update staking contract details", () => {
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "false");
                });

                test("Should update distribution details", () => {
                    assert.fieldEquals(
                        "FundsDistribution",
                        ids[0],
                        "distributedAt",
                        monthsAfterInit[2].plus(BIGINT_ONE).toString(),
                    );
                });

                test("Should update staker total unclaimed rewards", () => {
                    for (let i = 0; i < stakers.length; i++) {
                        assert.fieldEquals("Staker", stakers[i].toHex(), "totalUnclaimedRewards", rewards.toString());
                    }
                });

                test("Should update staker single token unclaimed rewards", () => {
                    for (let i = 0; i < stakers.length; i++) {
                        const id = `${stakers[i].toHex()}-${usdtToken.toHex()}`;
                        assert.fieldEquals("StakerRewards", id, "unclaimedAmount", rewards.toString());
                    }
                });
            });

            describe("Band Level 9", () => {
                beforeAll(() => {
                    bandLevel = 9;
                    // IF we divide 100k by 3 (we would get the wrong amount (dust amount is added))
                    // rewards = usd100k.div(BigInt.fromI32(3));

                    const stakersLength = BigInt.fromI32(stakersCount);
                    rewards = usd100k
                        .times(poolDistributionPercentages[0])
                        .div(percentagePrecision)
                        .div(stakersLength)
                        .plus(usd100k.times(poolDistributionPercentages[1]).div(percentagePrecision).div(stakersLength))
                        .plus(usd100k.times(poolDistributionPercentages[2]).div(percentagePrecision).div(stakersLength))
                        .plus(usd100k.times(poolDistributionPercentages[3]).div(percentagePrecision).div(stakersLength))
                        .plus(usd100k.times(poolDistributionPercentages[4]).div(percentagePrecision).div(stakersLength))
                        .plus(usd100k.times(poolDistributionPercentages[5]).div(percentagePrecision).div(stakersLength))
                        .plus(usd100k.times(poolDistributionPercentages[6]).div(percentagePrecision).div(stakersLength))
                        .plus(usd100k.times(poolDistributionPercentages[7]).div(percentagePrecision).div(stakersLength))
                        .plus(
                            usd100k.times(poolDistributionPercentages[8]).div(percentagePrecision).div(stakersLength),
                        );
                });

                test("Should update staking contract details", () => {
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "false");
                });

                test("Should update distribution details", () => {
                    assert.fieldEquals(
                        "FundsDistribution",
                        ids[0],
                        "distributedAt",
                        monthsAfterInit[2].plus(BIGINT_ONE).toString(),
                    );
                    const distro = getOrInitFundsDistribution(BIGINT_ZERO);
                });

                test("Should update staker total unclaimed rewards", () => {
                    for (let i = 0; i < stakers.length; i++) {
                        assert.fieldEquals("Staker", stakers[i].toHex(), "totalUnclaimedRewards", rewards.toString());
                    }
                });

                test("Should update staker single token unclaimed rewards", () => {
                    for (let i = 0; i < stakers.length; i++) {
                        const id = `${stakers[i].toHex()}-${usdtToken.toHex()}`;
                        assert.fieldEquals("StakerRewards", id, "unclaimedAmount", rewards.toString());
                    }
                });
            });
        });
    });
});
