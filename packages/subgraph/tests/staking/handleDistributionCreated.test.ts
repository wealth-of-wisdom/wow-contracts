import { BigInt, log } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import {
    createDistribution,
    distributeRewards,
    initializeAndSetUp,
    stakeStandardFixed,
    stakeStandardFlexi,
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
} from "../utils/data/constants";
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
