import { BigInt } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import {
    initializeAndSetUp,
    stakeStandardFlexi,
    createDistribution,
    distributeRewards,
    claimRewards,
    stakeStandardFixed,
    getPoolAllocation,
} from "./helpers/helper";
import {
    alice,
    bandIds,
    usdtToken,
    usd100k,
    usd200k,
    usd300k,
    usdcToken,
    bob,
    usd400k,
    ids,
} from "../utils/data/constants";
import { monthsAfterInit } from "../utils/data/dates";
import { bandLevels, months } from "../utils/data/data";

let rewards: BigInt[];

describe("handleRewardsClaimed() tests", () => {
    beforeEach(() => {
        clearStore();
        initializeAndSetUp();
    });

    describe("1 Staker", () => {
        describe("Claim rewards once", () => {
            beforeEach(() => {
                stakeStandardFixed(alice, bandLevels[0], bandIds[0], months[10], monthsAfterInit[1]);

                createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdtToken, monthsAfterInit[2]);

                rewards = [getPoolAllocation(usd100k, ids[0])];
                claimRewards(alice, usdtToken, rewards[0], monthsAfterInit[3]);
            });

            test("Should update staker total rewards", () => {
                assert.fieldEquals("Staker", alice.toHex(), "totalClaimedRewards", rewards[0].toString());
                assert.fieldEquals("Staker", alice.toHex(), "totalUnclaimedRewards", "0");
            });

            test("Should update staker rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", rewards[0].toString());
                assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", "0");
            });
        });

        describe("Claim rewards twice for the same token", () => {
            beforeEach(() => {
                stakeStandardFixed(alice, bandLevels[0], bandIds[0], months[10], monthsAfterInit[1]);

                createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdtToken, monthsAfterInit[2]);
                claimRewards(alice, usdtToken, getPoolAllocation(usd100k, ids[0]), monthsAfterInit[3]);

                createDistribution(usdtToken, usd200k, monthsAfterInit[4]);
                distributeRewards(usdtToken, monthsAfterInit[4]);
                claimRewards(alice, usdtToken, getPoolAllocation(usd200k, ids[0]), monthsAfterInit[5]);

                rewards = [getPoolAllocation(usd300k, ids[0])];
            });

            test("Should update staker total rewards", () => {
                assert.fieldEquals("Staker", alice.toHex(), "totalClaimedRewards", rewards[0].toString());
                assert.fieldEquals("Staker", alice.toHex(), "totalUnclaimedRewards", "0");
            });

            test("Should update staker rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", rewards[0].toString());
                assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", "0");
            });
        });

        describe("Claim rewards twice for different tokens", () => {
            beforeEach(() => {
                stakeStandardFixed(alice, bandLevels[0], bandIds[0], months[10], monthsAfterInit[1]);

                createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdtToken, monthsAfterInit[2]);

                createDistribution(usdcToken, usd200k, monthsAfterInit[4]);
                distributeRewards(usdcToken, monthsAfterInit[4]);

                rewards = [getPoolAllocation(usd100k, ids[0]), getPoolAllocation(usd200k, ids[0])];
                claimRewards(alice, usdtToken, rewards[0], monthsAfterInit[5]);
                claimRewards(alice, usdcToken, rewards[1], monthsAfterInit[5]);
            });

            test("Should update staker total rewards", () => {
                assert.fieldEquals(
                    "Staker",
                    alice.toHex(),
                    "totalClaimedRewards",
                    getPoolAllocation(usd300k, ids[0]).toString(),
                );
                assert.fieldEquals("Staker", alice.toHex(), "totalUnclaimedRewards", "0");
            });

            test("Should update staker rewards", () => {
                const usdcId = `${alice.toHex()}-${usdcToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdcId, "claimedAmount", rewards[1].toString());
                assert.fieldEquals("StakerRewards", usdcId, "unclaimedAmount", "0");
            });

            test("Should leave another token rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", rewards[0].toString());
                assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", "0");
            });
        });
    });

    describe("2 Stakers", () => {
        describe("Claim rewards once", () => {
            beforeEach(() => {
                stakeStandardFixed(alice, bandLevels[0], bandIds[0], months[1], monthsAfterInit[1]);
                stakeStandardFlexi(bob, bandLevels[0], bandIds[0], monthsAfterInit[1]);

                createDistribution(usdtToken, usd200k, monthsAfterInit[2]);
                distributeRewards(usdtToken, monthsAfterInit[2]);

                rewards = [getPoolAllocation(usd100k, ids[0])];
                claimRewards(alice, usdtToken, rewards[0], monthsAfterInit[3]);
                claimRewards(bob, usdtToken, rewards[0], monthsAfterInit[3]);
            });

            test("Should update alice staker total rewards", () => {
                assert.fieldEquals("Staker", alice.toHex(), "totalClaimedRewards", rewards[0].toString());
                assert.fieldEquals("Staker", alice.toHex(), "totalUnclaimedRewards", "0");
            });

            test("Should update bob staker total rewards", () => {
                assert.fieldEquals("Staker", bob.toHex(), "totalClaimedRewards", rewards[0].toString());
                assert.fieldEquals("Staker", bob.toHex(), "totalUnclaimedRewards", "0");
            });

            test("Should update alice staker rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", rewards[0].toString());
                assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", "0");
            });

            test("Should update bob staker rewards", () => {
                const usdtId = `${bob.toHex()}-${usdtToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", rewards[0].toString());
                assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", "0");
            });
        });

        describe("Claim rewards twice for the same token", () => {
            beforeEach(() => {
                stakeStandardFixed(alice, bandLevels[0], bandIds[0], months[1], monthsAfterInit[1]);
                stakeStandardFlexi(bob, bandLevels[0], bandIds[0], monthsAfterInit[1]);

                rewards = [
                    getPoolAllocation(usd100k, ids[0]),
                    getPoolAllocation(usd100k, ids[0]),
                    getPoolAllocation(usd100k, ids[0]),
                    getPoolAllocation(usd300k, ids[0]),
                ];

                createDistribution(usdtToken, usd200k, monthsAfterInit[2]);
                distributeRewards(usdtToken, monthsAfterInit[2]);

                claimRewards(alice, usdtToken, rewards[0], monthsAfterInit[3]);
                claimRewards(bob, usdtToken, rewards[1], monthsAfterInit[3]);

                createDistribution(usdtToken, usd400k, monthsAfterInit[5]);
                distributeRewards(usdtToken, monthsAfterInit[5]);

                claimRewards(alice, usdtToken, rewards[2], monthsAfterInit[6]);
                claimRewards(bob, usdtToken, rewards[3], monthsAfterInit[6]);
            });

            test("Should update alice staker total rewards", () => {
                assert.fieldEquals(
                    "Staker",
                    alice.toHex(),
                    "totalClaimedRewards",
                    rewards[0].plus(rewards[2]).toString(),
                );
                assert.fieldEquals("Staker", alice.toHex(), "totalUnclaimedRewards", "0");
            });

            test("Should update bob staker total rewards", () => {
                assert.fieldEquals(
                    "Staker",
                    bob.toHex(),
                    "totalClaimedRewards",
                    rewards[1].plus(rewards[3]).toString(),
                );
                assert.fieldEquals("Staker", bob.toHex(), "totalUnclaimedRewards", "0");
            });

            test("Should update alice staker rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", rewards[0].plus(rewards[2]).toString());
                assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", "0");
            });

            test("Should update bob staker rewards", () => {
                const usdtId = `${bob.toHex()}-${usdtToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", rewards[1].plus(rewards[3]).toString());
                assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", "0");
            });
        });

        describe("Claim rewards twice for different tokens", () => {
            beforeEach(() => {
                stakeStandardFixed(alice, bandLevels[0], bandIds[0], months[1], monthsAfterInit[1]);
                stakeStandardFlexi(bob, bandLevels[0], bandIds[0], monthsAfterInit[1]);

                rewards = [
                    getPoolAllocation(usd100k, ids[0]),
                    getPoolAllocation(usd100k, ids[0]),
                    getPoolAllocation(usd100k, ids[0]),
                    getPoolAllocation(usd300k, ids[0]),
                ];

                createDistribution(usdtToken, usd200k, monthsAfterInit[2]);
                distributeRewards(usdtToken, monthsAfterInit[2]);

                claimRewards(alice, usdtToken, rewards[0], monthsAfterInit[3]);
                claimRewards(bob, usdtToken, rewards[1], monthsAfterInit[3]);

                createDistribution(usdcToken, usd400k, monthsAfterInit[5]);
                distributeRewards(usdcToken, monthsAfterInit[5]);

                claimRewards(alice, usdcToken, rewards[2], monthsAfterInit[6]);
                claimRewards(bob, usdcToken, rewards[3], monthsAfterInit[6]);
            });

            test("Should update alice staker total rewards", () => {
                assert.fieldEquals(
                    "Staker",
                    alice.toHex(),
                    "totalClaimedRewards",
                    rewards[0].plus(rewards[2]).toString(),
                );
                assert.fieldEquals("Staker", alice.toHex(), "totalUnclaimedRewards", "0");
            });

            test("Should update bob staker total rewards", () => {
                assert.fieldEquals(
                    "Staker",
                    bob.toHex(),
                    "totalClaimedRewards",
                    rewards[1].plus(rewards[3]).toString(),
                );
                assert.fieldEquals("Staker", bob.toHex(), "totalUnclaimedRewards", "0");
            });

            test("Should update alice staker rewards", () => {
                const usdcId = `${alice.toHex()}-${usdcToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdcId, "claimedAmount", rewards[2].toString());
                assert.fieldEquals("StakerRewards", usdcId, "unclaimedAmount", "0");
            });

            test("Should update bob staker rewards", () => {
                const usdcId = `${bob.toHex()}-${usdcToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdcId, "claimedAmount", rewards[3].toString());
                assert.fieldEquals("StakerRewards", usdcId, "unclaimedAmount", "0");
            });

            test("Should leave alice another token rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", rewards[0].toString());
                assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", "0");
            });

            test("Should leave bob another token rewards", () => {
                const usdtId = `${bob.toHex()}-${usdtToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", rewards[1].toString());
                assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", "0");
            });
        });
    });
});
