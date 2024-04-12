import { Address, BigInt, log } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, assert, clearStore, beforeAll } from "matchstick-as/assembly/index";
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
    percentagePrecision,
    totalPools,
} from "../utils/data/constants";
import { preInitDate, initDate, monthsAfterInit, dayInSeconds } from "../utils/data/dates";
import { sharesInMonths, bandLevels, months, poolDistributionPercentages } from "../utils/data/data";
import { convertAddressArrayToString, convertBigIntArrayToString, createEmptyArray } from "../utils/arrays";
import { BIGINT_ZERO } from "../../src/utils/constants";
import { StakingContract } from "../../generated/schema";

let bandLevel: BigInt;
let fixedMonths: BigInt;

let expectedStakers: Address[];
let expectedStakersCount = 0;
let expectedSharesForStakers: BigInt[][];
let expectedSharesForStakersCount = 0;
let expectedSharesForPools: BigInt[];
let expectedSharesForPoolsCount = 0;
let stakerRewards: BigInt[];
let expectedRewards: BigInt[];

let flexiShares: BigInt;
let fixedShares: BigInt;
let flexiSharesArray: BigInt[];
let fixedSharesArray: BigInt[];

let flexiStakerShares: BigInt[];
let isolatedFlexiStakerShares: BigInt[];
let fixedStakerShares: BigInt[];
let isolatedFixedStakerShares: BigInt[];

let flexiStakersShares: BigInt[][];
let fixedStakersShares: BigInt[][];
let isolatedFlexiStakersShares: BigInt[][];
let isolatedFixedStakersShares: BigInt[][];
let flexiPoolShares: BigInt[];
let fixedPoolShares: BigInt[];
let isolatedFlexiPoolShares: BigInt[];
let isolatedFixedPoolShares: BigInt[];

describe("handleDistributionCreated() tests", () => {
    beforeEach(() => {
        clearStore();
        initializeAndSetUp();
    });

    describe("Simple cases", () => {
        describe("No active stakers and no bands", () => {
            describe("Create 1 distribution with single token", () => {
                beforeEach(() => {
                    createDistribution(usdtToken, usd100k, monthsAfterInit[1]);
                });

                test("Should update distribution status", () => {
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "true");
                });

                test("Should increase next distribution id", () => {
                    assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[1]);
                });

                test("Should create new distribution", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "id", ids[0]);
                    assert.entityCount("FundsDistribution", 1);
                });

                test("Should set distribution values correctly", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[0], "amount", usd100k.toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "createdAt", monthsAfterInit[1].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", "0");
                    assert.fieldEquals("FundsDistribution", ids[0], "stakers", "[]");
                    assert.fieldEquals("FundsDistribution", ids[0], "rewards", "[]");
                });
            });

            describe("Create 2 distributions with single token", () => {
                beforeEach(() => {
                    createDistribution(usdtToken, usd100k, monthsAfterInit[1]);
                    distributeRewards(usdtToken, monthsAfterInit[1]);

                    createDistribution(usdtToken, usd100k, monthsAfterInit[3]);
                });

                test("Should update distribution status", () => {
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "true");
                });

                test("Should increase next distribution id", () => {
                    assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[2]);
                });

                test("Should create new distribution", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "id", ids[0]);
                    assert.fieldEquals("FundsDistribution", ids[1], "id", ids[1]);
                    assert.entityCount("FundsDistribution", 2);
                });

                test("Should set distribution values correctly", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[0], "amount", usd100k.toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "createdAt", monthsAfterInit[1].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", monthsAfterInit[1].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "stakers", "[]");
                    assert.fieldEquals("FundsDistribution", ids[0], "rewards", "[]");

                    assert.fieldEquals("FundsDistribution", ids[1], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[1], "amount", usd100k.toString());
                    assert.fieldEquals("FundsDistribution", ids[1], "createdAt", monthsAfterInit[3].toString());
                    assert.fieldEquals("FundsDistribution", ids[1], "distributedAt", "0");
                    assert.fieldEquals("FundsDistribution", ids[1], "stakers", "[]");
                    assert.fieldEquals("FundsDistribution", ids[1], "rewards", "[]");
                });
            });

            describe("Create 2 distributions with different tokens", () => {
                beforeEach(() => {
                    createDistribution(usdtToken, usd100k, monthsAfterInit[1]);
                    distributeRewards(usdtToken, monthsAfterInit[1]);

                    createDistribution(usdcToken, usd100k, monthsAfterInit[3]);
                });

                test("Should update distribution status", () => {
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "true");
                });

                test("Should increase next distribution id", () => {
                    assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[2]);
                });

                test("Should create new distribution", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "id", ids[0]);
                    assert.fieldEquals("FundsDistribution", ids[1], "id", ids[1]);
                    assert.entityCount("FundsDistribution", 2);
                });

                test("Should set distribution values correctly", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[0], "amount", usd100k.toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "createdAt", monthsAfterInit[1].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", monthsAfterInit[1].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "stakers", "[]");
                    assert.fieldEquals("FundsDistribution", ids[0], "rewards", "[]");

                    assert.fieldEquals("FundsDistribution", ids[1], "token", usdcToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[1], "amount", usd100k.toString());
                    assert.fieldEquals("FundsDistribution", ids[1], "createdAt", monthsAfterInit[3].toString());
                    assert.fieldEquals("FundsDistribution", ids[1], "distributedAt", "0");
                    assert.fieldEquals("FundsDistribution", ids[1], "stakers", "[]");
                    assert.fieldEquals("FundsDistribution", ids[1], "rewards", "[]");
                });
            });
        });

        describe("1 FIXED band", () => {
            beforeEach(() => {
                stakeStandardFixed(alice, bandLevels[8], bandIds[0], months[10], monthsAfterInit[1]);
            });

            describe("Create 1 distribution with single token", () => {
                beforeEach(() => {
                    createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                });

                test("Should update distribution status", () => {
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "true");
                });

                test("Should increase next distribution id", () => {
                    assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[1]);
                });

                test("Should create new distribution", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "id", ids[0]);
                    assert.entityCount("FundsDistribution", 1);
                });

                test("Should set distribution values correctly", () => {
                    const stakers: string = `[${alice.toHex()}]`;
                    const rewards: string = `[${usd100k.toString()}]`;

                    assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[0], "amount", usd100k.toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "createdAt", monthsAfterInit[2].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", "0");
                    assert.fieldEquals("FundsDistribution", ids[0], "stakers", stakers);
                    assert.fieldEquals("FundsDistribution", ids[0], "rewards", rewards);
                });

                test("Should not change band shares", () => {
                    assert.fieldEquals("Band", ids[0], "sharesAmount", sharesInMonths[9].toString());
                });
            });

            describe("Create 2 distributions with single token", () => {
                beforeEach(() => {
                    createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                    distributeRewards(usdtToken, monthsAfterInit[2]);

                    createDistribution(usdtToken, usd100k, monthsAfterInit[3]);
                });

                test("Should update distribution status", () => {
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "true");
                });

                test("Should increase next distribution id", () => {
                    assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[2]);
                });

                test("Should create new distribution", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "id", ids[0]);
                    assert.fieldEquals("FundsDistribution", ids[1], "id", ids[1]);
                    assert.entityCount("FundsDistribution", 2);
                });

                test("Should set distribution values correctly", () => {
                    const stakers: string = `[${alice.toHex()}]`;
                    const rewards: string = `[${usd100k.toString()}]`;

                    assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[0], "amount", usd100k.toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "createdAt", monthsAfterInit[2].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", monthsAfterInit[2].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "stakers", stakers);
                    assert.fieldEquals("FundsDistribution", ids[0], "rewards", rewards);

                    assert.fieldEquals("FundsDistribution", ids[1], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[1], "amount", usd100k.toString());
                    assert.fieldEquals("FundsDistribution", ids[1], "createdAt", monthsAfterInit[3].toString());
                    assert.fieldEquals("FundsDistribution", ids[1], "distributedAt", "0");
                    assert.fieldEquals("FundsDistribution", ids[1], "stakers", stakers);
                    assert.fieldEquals("FundsDistribution", ids[1], "rewards", rewards);
                });

                test("Should not change band shares", () => {
                    assert.fieldEquals("Band", ids[0], "sharesAmount", sharesInMonths[9].toString());
                });
            });

            describe("Create 2 distributions with different tokens", () => {
                beforeEach(() => {
                    createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                    distributeRewards(usdtToken, monthsAfterInit[2]);

                    createDistribution(usdcToken, usd100k, monthsAfterInit[3]);
                });

                test("Should update distribution status", () => {
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "true");
                });

                test("Should increase next distribution id", () => {
                    assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[2]);
                });

                test("Should create new distribution", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "id", ids[0]);
                    assert.fieldEquals("FundsDistribution", ids[1], "id", ids[1]);
                    assert.entityCount("FundsDistribution", 2);
                });

                test("Should set distribution values correctly", () => {
                    const stakers: string = `[${alice.toHex()}]`;
                    const rewards: string = `[${usd100k.toString()}]`;

                    assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[0], "amount", usd100k.toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "createdAt", monthsAfterInit[2].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", monthsAfterInit[2].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "stakers", stakers);
                    assert.fieldEquals("FundsDistribution", ids[0], "rewards", rewards);

                    assert.fieldEquals("FundsDistribution", ids[1], "token", usdcToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[1], "amount", usd100k.toString());
                    assert.fieldEquals("FundsDistribution", ids[1], "createdAt", monthsAfterInit[3].toString());
                    assert.fieldEquals("FundsDistribution", ids[1], "distributedAt", "0");
                    assert.fieldEquals("FundsDistribution", ids[1], "stakers", stakers);
                    assert.fieldEquals("FundsDistribution", ids[1], "rewards", rewards);
                });

                test("Should not change band shares", () => {
                    assert.fieldEquals("Band", ids[0], "sharesAmount", sharesInMonths[9].toString());
                });
            });
        });

        describe("1 FLEXI band", () => {
            beforeEach(() => {
                stakeStandardFlexi(alice, bandLevels[8], bandIds[0], monthsAfterInit[1]);
            });

            describe("Create 1 distribution with single token", () => {
                beforeEach(() => {
                    createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                });

                test("Should update distribution status", () => {
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "true");
                });

                test("Should increase next distribution id", () => {
                    assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[1]);
                });

                test("Should create new distribution", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "id", ids[0]);
                    assert.entityCount("FundsDistribution", 1);
                });

                test("Should set distribution values correctly", () => {
                    const stakers: string = `[${alice.toHex()}]`;
                    const rewards: string = `[${usd100k.toString()}]`;

                    assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[0], "amount", usd100k.toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "createdAt", monthsAfterInit[2].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", "0");
                    assert.fieldEquals("FundsDistribution", ids[0], "stakers", stakers);
                    assert.fieldEquals("FundsDistribution", ids[0], "rewards", rewards);
                });

                test("Should change band shares", () => {
                    assert.fieldEquals("Band", ids[0], "sharesAmount", sharesInMonths[0].toString());
                });
            });

            describe("Create 2 distributions with single token", () => {
                beforeEach(() => {
                    createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                    distributeRewards(usdtToken, monthsAfterInit[2]);

                    createDistribution(usdtToken, usd100k, monthsAfterInit[3]);
                });

                test("Should update distribution status", () => {
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "true");
                });

                test("Should increase next distribution id", () => {
                    assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[2]);
                });

                test("Should create new distribution", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "id", ids[0]);
                    assert.fieldEquals("FundsDistribution", ids[1], "id", ids[1]);
                    assert.entityCount("FundsDistribution", 2);
                });

                test("Should set distribution values correctly", () => {
                    const stakers: string = `[${alice.toHex()}]`;
                    const rewards: string = `[${usd100k.toString()}]`;

                    assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[0], "amount", usd100k.toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "createdAt", monthsAfterInit[2].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", monthsAfterInit[2].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "stakers", stakers);
                    assert.fieldEquals("FundsDistribution", ids[0], "rewards", rewards);

                    assert.fieldEquals("FundsDistribution", ids[1], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[1], "amount", usd100k.toString());
                    assert.fieldEquals("FundsDistribution", ids[1], "createdAt", monthsAfterInit[3].toString());
                    assert.fieldEquals("FundsDistribution", ids[1], "distributedAt", "0");
                    assert.fieldEquals("FundsDistribution", ids[1], "stakers", stakers);
                    assert.fieldEquals("FundsDistribution", ids[1], "rewards", rewards);
                });

                test("Should change band shares", () => {
                    assert.fieldEquals("Band", ids[0], "sharesAmount", sharesInMonths[1].toString());
                });
            });

            describe("Create 2 distributions with different tokens", () => {
                beforeEach(() => {
                    createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                    distributeRewards(usdtToken, monthsAfterInit[2]);

                    createDistribution(usdcToken, usd100k, monthsAfterInit[3]);
                });

                test("Should update distribution status", () => {
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "true");
                });

                test("Should increase next distribution id", () => {
                    assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[2]);
                });

                test("Should create new distribution", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "id", ids[0]);
                    assert.fieldEquals("FundsDistribution", ids[1], "id", ids[1]);
                    assert.entityCount("FundsDistribution", 2);
                });

                test("Should set distribution values correctly", () => {
                    const stakers: string = `[${alice.toHex()}]`;
                    const rewards: string = `[${usd100k.toString()}]`;

                    assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[0], "amount", usd100k.toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "createdAt", monthsAfterInit[2].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", monthsAfterInit[2].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "stakers", stakers);
                    assert.fieldEquals("FundsDistribution", ids[0], "rewards", rewards);

                    assert.fieldEquals("FundsDistribution", ids[1], "token", usdcToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[1], "amount", usd100k.toString());
                    assert.fieldEquals("FundsDistribution", ids[1], "createdAt", monthsAfterInit[3].toString());
                    assert.fieldEquals("FundsDistribution", ids[1], "distributedAt", "0");
                    assert.fieldEquals("FundsDistribution", ids[1], "stakers", stakers);
                    assert.fieldEquals("FundsDistribution", ids[1], "rewards", rewards);
                });

                test("Should change band shares", () => {
                    assert.fieldEquals("Band", ids[0], "sharesAmount", sharesInMonths[1].toString());
                });
            });
        });

        describe("1 FIXED band and 1 FLEXI band", () => {
            beforeEach(() => {
                stakeStandardFixed(alice, bandLevels[8], bandIds[0], months[2], monthsAfterInit[1]);
                stakeStandardFlexi(bob, bandLevels[8], bandIds[1], monthsAfterInit[1]);
            });

            describe("Create 1 distribution with single token", () => {
                beforeEach(() => {
                    createDistribution(usdtToken, usd200k, monthsAfterInit[3]);
                });

                test("Should update distribution status", () => {
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "true");
                });

                test("Should increase next distribution id", () => {
                    assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[1]);
                });

                test("Should create new distribution", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "id", ids[0]);
                    assert.entityCount("FundsDistribution", 1);
                });

                test("Should set distribution values correctly", () => {
                    const stakers: string = `[${alice.toHex()}, ${bob.toHex()}]`;
                    const rewards: string = `[${usd100k.toString()}, ${usd100k.toString()}]`;

                    assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[0], "amount", usd200k.toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "createdAt", monthsAfterInit[3].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", "0");
                    assert.fieldEquals("FundsDistribution", ids[0], "stakers", stakers);
                    assert.fieldEquals("FundsDistribution", ids[0], "rewards", rewards);
                });

                test("Should not change fixed band shares", () => {
                    assert.fieldEquals("Band", ids[0], "sharesAmount", sharesInMonths[1].toString());
                });

                test("Should change flexi band shares", () => {
                    assert.fieldEquals("Band", ids[1], "sharesAmount", sharesInMonths[1].toString());
                });
            });

            describe("Create 2 distributions with single token", () => {
                beforeEach(() => {
                    createDistribution(usdtToken, usd200k, monthsAfterInit[3]);
                    distributeRewards(usdtToken, monthsAfterInit[3]);

                    createDistribution(usdtToken, usd500k, monthsAfterInit[5]);
                });

                test("Should update distribution status", () => {
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "true");
                });

                test("Should increase next distribution id", () => {
                    assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[2]);
                });

                test("Should create new distribution", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "id", ids[0]);
                    assert.fieldEquals("FundsDistribution", ids[1], "id", ids[1]);
                    assert.entityCount("FundsDistribution", 2);
                });

                test("Should set distribution 1 values correctly", () => {
                    const stakers: string = `[${alice.toHex()}, ${bob.toHex()}]`;
                    const rewards: string = `[${usd100k.toString()}, ${usd100k.toString()}]`;

                    assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[0], "amount", usd200k.toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "createdAt", monthsAfterInit[3].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", monthsAfterInit[3].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "stakers", stakers);
                    assert.fieldEquals("FundsDistribution", ids[0], "rewards", rewards);
                });

                test("Should set distribution 2 values correctly", () => {
                    const stakers: string = `[${alice.toHex()}, ${bob.toHex()}]`;
                    const rewards: string = `[${usd200k.toString()}, ${usd300k.toString()}]`;

                    assert.fieldEquals("FundsDistribution", ids[1], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[1], "amount", usd500k.toString());
                    assert.fieldEquals("FundsDistribution", ids[1], "createdAt", monthsAfterInit[5].toString());
                    assert.fieldEquals("FundsDistribution", ids[1], "distributedAt", "0");
                    assert.fieldEquals("FundsDistribution", ids[1], "stakers", stakers);
                    assert.fieldEquals("FundsDistribution", ids[1], "rewards", rewards);
                });

                test("Should not change fixed band shares", () => {
                    assert.fieldEquals("Band", ids[0], "sharesAmount", sharesInMonths[1].toString());
                });

                test("Should change flexi band shares", () => {
                    assert.fieldEquals("Band", ids[1], "sharesAmount", sharesInMonths[3].toString());
                });
            });

            describe("Create 2 distributions with different tokens", () => {
                beforeEach(() => {
                    createDistribution(usdtToken, usd200k, monthsAfterInit[3]);
                    distributeRewards(usdtToken, monthsAfterInit[3]);

                    createDistribution(usdcToken, usd500k, monthsAfterInit[5]);
                });

                test("Should update distribution status", () => {
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "true");
                });

                test("Should increase next distribution id", () => {
                    assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[2]);
                });

                test("Should create new distribution", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "id", ids[0]);
                    assert.fieldEquals("FundsDistribution", ids[1], "id", ids[1]);
                    assert.entityCount("FundsDistribution", 2);
                });

                test("Should set distribution 1 values correctly", () => {
                    const stakers: string = `[${alice.toHex()}, ${bob.toHex()}]`;
                    const rewards: string = `[${usd100k.toString()}, ${usd100k.toString()}]`;

                    assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[0], "amount", usd200k.toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "createdAt", monthsAfterInit[3].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", monthsAfterInit[3].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "stakers", stakers);
                    assert.fieldEquals("FundsDistribution", ids[0], "rewards", rewards);
                });

                test("Should set distribution 2 values correctly", () => {
                    const stakers: string = `[${alice.toHex()}, ${bob.toHex()}]`;
                    const rewards: string = `[${usd200k.toString()}, ${usd300k.toString()}]`;

                    assert.fieldEquals("FundsDistribution", ids[1], "token", usdcToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[1], "amount", usd500k.toString());
                    assert.fieldEquals("FundsDistribution", ids[1], "createdAt", monthsAfterInit[5].toString());
                    assert.fieldEquals("FundsDistribution", ids[1], "distributedAt", "0");
                    assert.fieldEquals("FundsDistribution", ids[1], "stakers", stakers);
                    assert.fieldEquals("FundsDistribution", ids[1], "rewards", rewards);
                });

                test("Should not change fixed band shares", () => {
                    assert.fieldEquals("Band", ids[0], "sharesAmount", sharesInMonths[1].toString());
                });

                test("Should change flexi band shares", () => {
                    assert.fieldEquals("Band", ids[1], "sharesAmount", sharesInMonths[3].toString());
                });
            });
        });
    });

    describe("Complex cases", () => {
        beforeAll(() => {
            expectedStakers = [alice];
            expectedStakersCount = expectedStakers.length;
        });

        describe("1 staker, 1 FIXED and 1 FLEXI", () => {
            describe("More than 2 months", () => {
                beforeEach(() => {
                    stakeStandardFixed(alice, bandLevels[4], bandIds[0], months[10], monthsAfterInit[1]);
                    stakeStandardFlexi(alice, bandLevels[7], bandIds[1], monthsAfterInit[1].plus(dayInSeconds));
                    createDistribution(usdtToken, usd100k, monthsAfterInit[2].plus(dayInSeconds));

                    fixedShares = sharesInMonths[9];
                    flexiShares = sharesInMonths[0];

                    const aliceRewards = usd100k.minus(
                        usd100k.times(poolDistributionPercentages[8]).div(percentagePrecision),
                    );

                    expectedRewards = [aliceRewards];

                    flexiStakerShares = createEmptyArray(totalPools).fill(flexiShares, 0, 8);
                    isolatedFlexiStakerShares = createEmptyArray(totalPools).fill(flexiShares, 7, 8);
                    fixedStakerShares = createEmptyArray(totalPools).fill(fixedShares, 0, 5);
                    isolatedFixedStakerShares = createEmptyArray(totalPools).fill(fixedShares, 4, 5);
                });

                /*//////////////////////////////////////////////////////////////////////////
                                                ASSERT MAIN DATA
                //////////////////////////////////////////////////////////////////////////*/

                test("Should update staking contract details", () => {
                    assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[1]);
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "true");
                });

                test("Should update band flexi shares", () => {
                    assert.fieldEquals("Band", ids[1], "sharesAmount", flexiShares.toString());
                });

                test("Should not update band fixed shares", () => {
                    assert.fieldEquals("Band", ids[0], "sharesAmount", fixedShares.toString());
                });

                test("Should update staker flexi shares", () => {
                    assert.fieldEquals(
                        "Staker",
                        alice.toHex(),
                        "flexiSharesPerPool",
                        convertBigIntArrayToString(flexiStakerShares),
                    );
                    assert.fieldEquals(
                        "Staker",
                        alice.toHex(),
                        "isolatedFlexiSharesPerPool",
                        convertBigIntArrayToString(isolatedFlexiStakerShares),
                    );
                });

                test("Should not update staker fixed shares", () => {
                    assert.fieldEquals(
                        "Staker",
                        alice.toHex(),
                        "fixedSharesPerPool",
                        convertBigIntArrayToString(fixedStakerShares),
                    );
                    assert.fieldEquals(
                        "Staker",
                        alice.toHex(),
                        "isolatedFixedSharesPerPool",
                        convertBigIntArrayToString(isolatedFixedStakerShares),
                    );
                });

                test("Should update pool flexi shares", () => {
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        assert.fieldEquals(
                            "Pool",
                            ids[i],
                            "totalFlexiSharesAmount",
                            flexiStakerShares[i - 1].toString(),
                        );
                        assert.fieldEquals(
                            "Pool",
                            ids[i],
                            "isolatedFlexiSharesAmount",
                            isolatedFlexiStakerShares[i - 1].toString(),
                        );
                    }
                });

                test("Should no update pool fixed shares", () => {
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        assert.fieldEquals(
                            "Pool",
                            ids[i],
                            "totalFixedSharesAmount",
                            fixedStakerShares[i - 1].toString(),
                        );
                        assert.fieldEquals(
                            "Pool",
                            ids[i],
                            "isolatedFixedSharesAmount",
                            isolatedFixedStakerShares[i - 1].toString(),
                        );
                    }
                });

                test("Should create new distribution", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "id", ids[0]);
                    assert.entityCount("FundsDistribution", 1);
                });

                test("Should set distribution values correctly", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[0], "amount", usd100k.toString());
                    assert.fieldEquals(
                        "FundsDistribution",
                        ids[0],
                        "createdAt",
                        monthsAfterInit[2].plus(dayInSeconds).toString(),
                    );
                    assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", "0");
                    assert.fieldEquals(
                        "FundsDistribution",
                        ids[0],
                        "stakers",
                        convertAddressArrayToString(expectedStakers),
                    );
                    assert.fieldEquals(
                        "FundsDistribution",
                        ids[0],
                        "rewards",
                        convertBigIntArrayToString(expectedRewards),
                    );
                });
            });

            describe("2 months", () => {
                beforeEach(() => {
                    stakeStandardFixed(alice, bandLevels[4], bandIds[0], months[10], monthsAfterInit[1]);
                    stakeStandardFlexi(alice, bandLevels[7], bandIds[1], monthsAfterInit[1].plus(dayInSeconds));
                    createDistribution(usdtToken, usd100k, monthsAfterInit[2]);

                    fixedShares = sharesInMonths[9];
                    flexiShares = BIGINT_ZERO;

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

                    flexiStakerShares = createEmptyArray(totalPools).fill(flexiShares, 0, 8);
                    isolatedFlexiStakerShares = createEmptyArray(totalPools).fill(flexiShares, 7, 8);
                    fixedStakerShares = createEmptyArray(totalPools).fill(fixedShares, 0, 5);
                    isolatedFixedStakerShares = createEmptyArray(totalPools).fill(fixedShares, 4, 5);
                });

                /*//////////////////////////////////////////////////////////////////////////
                                                ASSERT MAIN DATA
                //////////////////////////////////////////////////////////////////////////*/

                test("Should update staking contract details", () => {
                    assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[1]);
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "true");
                });

                test("Should update band flexi shares", () => {
                    assert.fieldEquals("Band", ids[1], "sharesAmount", flexiShares.toString());
                });

                test("Should not update band fixed shares", () => {
                    assert.fieldEquals("Band", ids[0], "sharesAmount", fixedShares.toString());
                });

                test("Should update staker flexi shares", () => {
                    assert.fieldEquals(
                        "Staker",
                        alice.toHex(),
                        "flexiSharesPerPool",
                        convertBigIntArrayToString(flexiStakerShares),
                    );
                    assert.fieldEquals(
                        "Staker",
                        alice.toHex(),
                        "isolatedFlexiSharesPerPool",
                        convertBigIntArrayToString(isolatedFlexiStakerShares),
                    );
                });

                test("Should not update staker fixed shares", () => {
                    assert.fieldEquals(
                        "Staker",
                        alice.toHex(),
                        "fixedSharesPerPool",
                        convertBigIntArrayToString(fixedStakerShares),
                    );
                    assert.fieldEquals(
                        "Staker",
                        alice.toHex(),
                        "isolatedFixedSharesPerPool",
                        convertBigIntArrayToString(isolatedFixedStakerShares),
                    );
                });

                test("Should update pool flexi shares", () => {
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        assert.fieldEquals(
                            "Pool",
                            ids[i],
                            "totalFlexiSharesAmount",
                            flexiStakerShares[i - 1].toString(),
                        );
                        assert.fieldEquals(
                            "Pool",
                            ids[i],
                            "isolatedFlexiSharesAmount",
                            isolatedFlexiStakerShares[i - 1].toString(),
                        );
                    }
                });

                test("Should no update pool fixed shares", () => {
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        assert.fieldEquals(
                            "Pool",
                            ids[i],
                            "totalFixedSharesAmount",
                            fixedStakerShares[i - 1].toString(),
                        );
                        assert.fieldEquals(
                            "Pool",
                            ids[i],
                            "isolatedFixedSharesAmount",
                            isolatedFixedStakerShares[i - 1].toString(),
                        );
                    }
                });

                test("Should create new distribution", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "id", ids[0]);
                    assert.entityCount("FundsDistribution", 1);
                });

                test("Should set distribution values correctly", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[0], "amount", usd100k.toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "createdAt", monthsAfterInit[2].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", "0");
                    assert.fieldEquals(
                        "FundsDistribution",
                        ids[0],
                        "stakers",
                        convertAddressArrayToString(expectedStakers),
                    );
                    assert.fieldEquals(
                        "FundsDistribution",
                        ids[0],
                        "rewards",
                        convertBigIntArrayToString(expectedRewards),
                    );
                });
            });
        });

        describe("2 staker, 2 FIXED and 2 FLEXI", () => {
            beforeAll(() => {
                expectedStakers = [alice, bob];
                expectedStakersCount = expectedStakers.length;
            });

            describe("More than 5 months", () => {
                beforeEach(() => {
                    stakeStandardFixed(alice, bandLevels[0], bandIds[0], months[10], monthsAfterInit[1]);
                    stakeVestedFixed(bob, bandLevels[4], bandIds[1], months[24], monthsAfterInit[2]);
                    stakeVestedFlexi(alice, bandLevels[2], bandIds[2], monthsAfterInit[3].plus(dayInSeconds));
                    stakeStandardFlexi(bob, bandLevels[6], bandIds[3], monthsAfterInit[4]);
                    createDistribution(usdtToken, usd100k, monthsAfterInit[5].plus(dayInSeconds));

                    const fixedShares1 = sharesInMonths[9];
                    const flexiShares1 = sharesInMonths[1];
                    const totalShares1 = fixedShares1.plus(flexiShares1);
                    const fixedShares2 = sharesInMonths[23];
                    const flexiShares2 = sharesInMonths[0];
                    const totalShares2 = fixedShares2.plus(flexiShares2);

                    flexiSharesArray = [flexiShares1, flexiShares2];
                    fixedSharesArray = [fixedShares1, fixedShares2];

                    const aliceRewards = usd100k
                        .times(poolDistributionPercentages[0])
                        .div(percentagePrecision)
                        .times(totalShares1)
                        .div(totalShares1.plus(totalShares2))
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[1])
                                .div(percentagePrecision)
                                .times(flexiShares1)
                                .div(flexiShares1.plus(totalShares2)),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[2])
                                .div(percentagePrecision)
                                .times(flexiShares1)
                                .div(flexiShares1.plus(totalShares2)),
                        );
                    const bobRewards = usd100k
                        .times(poolDistributionPercentages[0])
                        .div(percentagePrecision)
                        .times(totalShares2)
                        .div(totalShares1.plus(totalShares2))
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[1])
                                .div(percentagePrecision)
                                .times(totalShares2)
                                .div(flexiShares1.plus(totalShares2)),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[2])
                                .div(percentagePrecision)
                                .times(totalShares2)
                                .div(flexiShares1.plus(totalShares2)),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[3])
                                .div(percentagePrecision)
                                .times(totalShares2)
                                .div(totalShares2),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[4])
                                .div(percentagePrecision)
                                .times(totalShares2)
                                .div(totalShares2),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[5])
                                .div(percentagePrecision)
                                .times(flexiShares2)
                                .div(flexiShares2),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[6])
                                .div(percentagePrecision)
                                .times(flexiShares2)
                                .div(flexiShares2),
                        );

                    expectedRewards = [aliceRewards, bobRewards];

                    flexiStakersShares = [
                        createEmptyArray(totalPools).fill(flexiShares1, 0, 3),
                        createEmptyArray(totalPools).fill(flexiShares2, 0, 7),
                    ];
                    isolatedFlexiStakersShares = [
                        createEmptyArray(totalPools).fill(flexiShares1, 2, 3),
                        createEmptyArray(totalPools).fill(flexiShares2, 6, 7),
                    ];
                    fixedStakersShares = [
                        createEmptyArray(totalPools).fill(fixedShares1, 0, 1),
                        createEmptyArray(totalPools).fill(fixedShares2, 0, 5),
                    ];
                    isolatedFixedStakersShares = [
                        createEmptyArray(totalPools).fill(fixedShares1, 0, 1),
                        createEmptyArray(totalPools).fill(fixedShares2, 4, 5),
                    ];
                    flexiPoolShares = createEmptyArray(totalPools)
                        .fill(flexiShares1.plus(flexiShares2), 0, 3)
                        .fill(flexiShares2, 3, 7);
                    isolatedFlexiPoolShares = createEmptyArray(totalPools);
                    isolatedFlexiPoolShares[2] = flexiShares1;
                    isolatedFlexiPoolShares[6] = flexiShares2;
                    fixedPoolShares = createEmptyArray(totalPools)
                        .fill(fixedShares1.plus(fixedShares2), 0, 1)
                        .fill(fixedShares2, 1, 5);
                    isolatedFixedPoolShares = createEmptyArray(totalPools);
                    isolatedFixedPoolShares[0] = fixedShares1;
                    isolatedFixedPoolShares[4] = fixedShares2;
                });

                /*//////////////////////////////////////////////////////////////////////////
                                                ASSERT MAIN DATA
                //////////////////////////////////////////////////////////////////////////*/

                test("Should update staking contract details", () => {
                    assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[1]);
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "true");
                });

                test("Should update band flexi shares", () => {
                    assert.fieldEquals("Band", ids[2], "sharesAmount", flexiSharesArray[0].toString());
                    assert.fieldEquals("Band", ids[3], "sharesAmount", flexiSharesArray[1].toString());
                });

                test("Should not update band fixed shares", () => {
                    assert.fieldEquals("Band", ids[0], "sharesAmount", fixedSharesArray[0].toString());
                    assert.fieldEquals("Band", ids[1], "sharesAmount", fixedSharesArray[1].toString());
                });

                test("Should update staker flexi shares", () => {
                    for (let i = 0; i < expectedStakersCount; i++) {
                        const staker = expectedStakers[i].toHex();
                        assert.fieldEquals(
                            "Staker",
                            staker,
                            "flexiSharesPerPool",
                            convertBigIntArrayToString(flexiStakersShares[i]),
                        );
                        assert.fieldEquals(
                            "Staker",
                            staker,
                            "isolatedFlexiSharesPerPool",
                            convertBigIntArrayToString(isolatedFlexiStakersShares[i]),
                        );
                    }
                });

                test("Should not update staker fixed shares", () => {
                    for (let i = 0; i < expectedStakersCount; i++) {
                        const staker = expectedStakers[i].toHex();
                        assert.fieldEquals(
                            "Staker",
                            staker,
                            "fixedSharesPerPool",
                            convertBigIntArrayToString(fixedStakersShares[i]),
                        );
                        assert.fieldEquals(
                            "Staker",
                            staker,
                            "isolatedFixedSharesPerPool",
                            convertBigIntArrayToString(isolatedFixedStakersShares[i]),
                        );
                    }
                });

                test("Should update pool flexi shares", () => {
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", flexiPoolShares[i - 1].toString());
                        assert.fieldEquals(
                            "Pool",
                            ids[i],
                            "isolatedFlexiSharesAmount",
                            isolatedFlexiPoolShares[i - 1].toString(),
                        );
                    }
                });

                test("Should not update pool fixed shares", () => {
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", fixedPoolShares[i - 1].toString());
                        assert.fieldEquals(
                            "Pool",
                            ids[i],
                            "isolatedFixedSharesAmount",
                            isolatedFixedPoolShares[i - 1].toString(),
                        );
                    }
                });

                test("Should create new distribution", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "id", ids[0]);
                    assert.entityCount("FundsDistribution", 1);
                });

                test("Should set distribution values correctly", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[0], "amount", usd100k.toString());
                    assert.fieldEquals(
                        "FundsDistribution",
                        ids[0],
                        "createdAt",
                        monthsAfterInit[5].plus(dayInSeconds).toString(),
                    );
                    assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", "0");
                    assert.fieldEquals(
                        "FundsDistribution",
                        ids[0],
                        "stakers",
                        convertAddressArrayToString(expectedStakers),
                    );
                    assert.fieldEquals(
                        "FundsDistribution",
                        ids[0],
                        "rewards",
                        convertBigIntArrayToString(expectedRewards),
                    );
                });
            });

            describe("5 months", () => {
                beforeEach(() => {
                    stakeStandardFixed(alice, bandLevels[0], bandIds[0], months[10], monthsAfterInit[1]);
                    stakeVestedFixed(bob, bandLevels[4], bandIds[1], months[24], monthsAfterInit[2]);
                    stakeVestedFlexi(alice, bandLevels[2], bandIds[2], monthsAfterInit[3].plus(dayInSeconds));
                    stakeStandardFlexi(bob, bandLevels[6], bandIds[3], monthsAfterInit[4]);
                    createDistribution(usdtToken, usd100k, monthsAfterInit[5]);

                    const fixedShares1 = sharesInMonths[9];
                    const flexiShares1 = sharesInMonths[0];
                    const totalShares1 = fixedShares1.plus(flexiShares1);
                    const fixedShares2 = sharesInMonths[23];
                    const flexiShares2 = sharesInMonths[0];
                    const totalShares2 = fixedShares2.plus(flexiShares2);

                    flexiSharesArray = [flexiShares1, flexiShares2];
                    fixedSharesArray = [fixedShares1, fixedShares2];

                    const aliceRewards = usd100k
                        .times(poolDistributionPercentages[0])
                        .div(percentagePrecision)
                        .times(totalShares1)
                        .div(totalShares1.plus(totalShares2))
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[1])
                                .div(percentagePrecision)
                                .times(flexiShares1)
                                .div(flexiShares1.plus(totalShares2)),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[2])
                                .div(percentagePrecision)
                                .times(flexiShares1)
                                .div(flexiShares1.plus(totalShares2)),
                        );
                    const bobRewards = usd100k
                        .times(poolDistributionPercentages[0])
                        .div(percentagePrecision)
                        .times(totalShares2)
                        .div(totalShares1.plus(totalShares2))
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[1])
                                .div(percentagePrecision)
                                .times(totalShares2)
                                .div(flexiShares1.plus(totalShares2)),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[2])
                                .div(percentagePrecision)
                                .times(totalShares2)
                                .div(flexiShares1.plus(totalShares2)),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[3])
                                .div(percentagePrecision)
                                .times(totalShares2)
                                .div(totalShares2),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[4])
                                .div(percentagePrecision)
                                .times(totalShares2)
                                .div(totalShares2),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[5])
                                .div(percentagePrecision)
                                .times(flexiShares2)
                                .div(flexiShares2),
                        )
                        .plus(
                            usd100k
                                .times(poolDistributionPercentages[6])
                                .div(percentagePrecision)
                                .times(flexiShares2)
                                .div(flexiShares2),
                        );

                    expectedRewards = [aliceRewards, bobRewards];

                    flexiStakersShares = [
                        createEmptyArray(totalPools).fill(flexiShares1, 0, 3),
                        createEmptyArray(totalPools).fill(flexiShares2, 0, 7),
                    ];
                    isolatedFlexiStakersShares = [
                        createEmptyArray(totalPools).fill(flexiShares1, 2, 3),
                        createEmptyArray(totalPools).fill(flexiShares2, 6, 7),
                    ];
                    fixedStakersShares = [
                        createEmptyArray(totalPools).fill(fixedShares1, 0, 1),
                        createEmptyArray(totalPools).fill(fixedShares2, 0, 5),
                    ];
                    isolatedFixedStakersShares = [
                        createEmptyArray(totalPools).fill(fixedShares1, 0, 1),
                        createEmptyArray(totalPools).fill(fixedShares2, 4, 5),
                    ];
                    flexiPoolShares = createEmptyArray(totalPools)
                        .fill(flexiShares1.plus(flexiShares2), 0, 3)
                        .fill(flexiShares2, 3, 7);
                    isolatedFlexiPoolShares = createEmptyArray(totalPools);
                    isolatedFlexiPoolShares[2] = flexiShares1;
                    isolatedFlexiPoolShares[6] = flexiShares2;
                    fixedPoolShares = createEmptyArray(totalPools)
                        .fill(fixedShares1.plus(fixedShares2), 0, 1)
                        .fill(fixedShares2, 1, 5);
                    isolatedFixedPoolShares = createEmptyArray(totalPools);
                    isolatedFixedPoolShares[0] = fixedShares1;
                    isolatedFixedPoolShares[4] = fixedShares2;
                });

                /*//////////////////////////////////////////////////////////////////////////
                                                ASSERT MAIN DATA
                //////////////////////////////////////////////////////////////////////////*/

                test("Should update staking contract details", () => {
                    assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[1]);
                    assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "true");
                });

                test("Should update band flexi shares", () => {
                    assert.fieldEquals("Band", ids[2], "sharesAmount", flexiSharesArray[0].toString());
                    assert.fieldEquals("Band", ids[3], "sharesAmount", flexiSharesArray[1].toString());
                });

                test("Should not update band fixed shares", () => {
                    assert.fieldEquals("Band", ids[0], "sharesAmount", fixedSharesArray[0].toString());
                    assert.fieldEquals("Band", ids[1], "sharesAmount", fixedSharesArray[1].toString());
                });

                test("Should update staker flexi shares", () => {
                    for (let i = 0; i < expectedStakersCount; i++) {
                        const staker = expectedStakers[i].toHex();
                        assert.fieldEquals(
                            "Staker",
                            staker,
                            "flexiSharesPerPool",
                            convertBigIntArrayToString(flexiStakersShares[i]),
                        );
                        assert.fieldEquals(
                            "Staker",
                            staker,
                            "isolatedFlexiSharesPerPool",
                            convertBigIntArrayToString(isolatedFlexiStakersShares[i]),
                        );
                    }
                });

                test("Should not update staker fixed shares", () => {
                    for (let i = 0; i < expectedStakersCount; i++) {
                        const staker = expectedStakers[i].toHex();
                        assert.fieldEquals(
                            "Staker",
                            staker,
                            "fixedSharesPerPool",
                            convertBigIntArrayToString(fixedStakersShares[i]),
                        );
                        assert.fieldEquals(
                            "Staker",
                            staker,
                            "isolatedFixedSharesPerPool",
                            convertBigIntArrayToString(isolatedFixedStakersShares[i]),
                        );
                    }
                });

                test("Should update pool flexi shares", () => {
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", flexiPoolShares[i - 1].toString());
                        assert.fieldEquals(
                            "Pool",
                            ids[i],
                            "isolatedFlexiSharesAmount",
                            isolatedFlexiPoolShares[i - 1].toString(),
                        );
                    }
                });

                test("Should not update pool fixed shares", () => {
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", fixedPoolShares[i - 1].toString());
                        assert.fieldEquals(
                            "Pool",
                            ids[i],
                            "isolatedFixedSharesAmount",
                            isolatedFixedPoolShares[i - 1].toString(),
                        );
                    }
                });

                test("Should create new distribution", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "id", ids[0]);
                    assert.entityCount("FundsDistribution", 1);
                });

                test("Should set distribution values correctly", () => {
                    assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
                    assert.fieldEquals("FundsDistribution", ids[0], "amount", usd100k.toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "createdAt", monthsAfterInit[5].toString());
                    assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", "0");
                    assert.fieldEquals(
                        "FundsDistribution",
                        ids[0],
                        "stakers",
                        convertAddressArrayToString(expectedStakers),
                    );
                    assert.fieldEquals(
                        "FundsDistribution",
                        ids[0],
                        "rewards",
                        convertBigIntArrayToString(expectedRewards),
                    );
                });
            });
        });
    });
});
