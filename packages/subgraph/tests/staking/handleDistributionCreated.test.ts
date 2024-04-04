import { BigInt, log } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { createDistribution, distributeRewards, initializeAndSetUp, stakeStandardFixed } from "./helpers/helper";
import { ids, bandIds, usdtToken, alice, bob, usd100k, usdcToken, zeroStr } from "../utils/data/constants";
import { preInitDate, initDate, monthsAfterInit } from "../utils/data/dates";
import { sharesInMonths, bandLevels, months } from "../utils/data/data";
import { convertAddressArrayToString, convertBigIntArrayToString, createEmptyArray } from "../utils/arrays";
import { BIGINT_ZERO } from "../../src/utils/constants";

let bandLevel: BigInt;
let fixedMonths: BigInt;

describe("handleDistributionCreated() tests", () => {
    beforeEach(() => {
        clearStore();
        initializeAndSetUp();
    });

    describe("No active stakers and no bands", () => {
        describe("Create distribution once", () => {
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

        describe("Create distribution twice", () => {
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

        describe("Create distribution once", () => {
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

        describe("Create distribution twice", () => {
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
        // @todo Add tests
    });

    describe("1 FIXED band and 1 FLEXI band", () => {
        // @todo Add tests
    });
});
