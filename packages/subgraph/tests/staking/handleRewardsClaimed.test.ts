import { BigInt } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import {
    initializeAndSetUp,
    stakeStandardFlexi,
    createDistribution,
    distributeRewards,
    claimRewards,
    stakeStandardFixed,
} from "./helpers/helper";
import {
    alice,
    bandIds,
    usdtToken,
    usd100k,
    zeroStr,
    usd200k,
    usd300k,
    usdcToken,
    bob,
    usd500k,
    usd400k,
} from "../utils/data/constants";
import { preInitDate, initDate, monthsAfterInit } from "../utils/data/dates";
import { bandLevels, months } from "../utils/data/data";

const secondaryClaimAmount: BigInt = BigInt.fromI32(200);

describe("handleRewardsClaimed() tests", () => {
    beforeEach(() => {
        clearStore();
        initializeAndSetUp();
    });

    describe("1 Staker", () => {
        beforeEach(() => {
            stakeStandardFixed(alice, bandLevels[1], bandIds[0], months[10], monthsAfterInit[1]);

            createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
            distributeRewards(usdtToken, monthsAfterInit[2]);
            claimRewards(alice, usdtToken, usd100k, monthsAfterInit[3]);
        });

        describe("Claim rewards once", () => {
            test("Should update staker total rewards", () => {
                assert.fieldEquals("Staker", alice.toHex(), "totalClaimedRewards", usd100k.toString());
                assert.fieldEquals("Staker", alice.toHex(), "totalUnclaimedRewards", "0");
            });

            test("Should update staker rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", usd100k.toString());
                assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", "0");
            });
        });

        describe("Claim rewards twice for the same token", () => {
            beforeEach(() => {
                createDistribution(usdtToken, usd200k, monthsAfterInit[4]);
                distributeRewards(usdtToken, monthsAfterInit[4]);
                claimRewards(alice, usdtToken, usd200k, monthsAfterInit[5]);
            });

            test("Should update staker total rewards", () => {
                assert.fieldEquals("Staker", alice.toHex(), "totalClaimedRewards", usd300k.toString());
                assert.fieldEquals("Staker", alice.toHex(), "totalUnclaimedRewards", "0");
            });

            test("Should update staker rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", usd300k.toString());
                assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", "0");
            });
        });

        describe("Claim rewards twice for different tokens", () => {
            beforeEach(() => {
                createDistribution(usdcToken, usd200k, monthsAfterInit[4]);
                distributeRewards(usdcToken, monthsAfterInit[4]);
                claimRewards(alice, usdcToken, usd200k, monthsAfterInit[5]);
            });

            test("Should update staker total rewards", () => {
                assert.fieldEquals("Staker", alice.toHex(), "totalClaimedRewards", usd300k.toString());
                assert.fieldEquals("Staker", alice.toHex(), "totalUnclaimedRewards", "0");
            });

            test("Should update staker rewards", () => {
                const usdcId = `${alice.toHex()}-${usdcToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdcId, "claimedAmount", usd200k.toString());
                assert.fieldEquals("StakerRewards", usdcId, "unclaimedAmount", "0");
            });

            test("Should leave another token rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", usd100k.toString());
                assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", "0");
            });
        });
    });

    describe("2 Stakers", () => {
        beforeEach(() => {
            stakeStandardFixed(alice, bandLevels[1], bandIds[0], months[1], monthsAfterInit[1]);
            stakeStandardFlexi(bob, bandLevels[1], bandIds[0], monthsAfterInit[1]);

            createDistribution(usdtToken, usd200k, monthsAfterInit[2]);
            distributeRewards(usdtToken, monthsAfterInit[2]);
            claimRewards(alice, usdtToken, usd100k, monthsAfterInit[3]);
            claimRewards(bob, usdtToken, usd100k, monthsAfterInit[3]);
        });

        describe("Claim rewards once", () => {
            test("Should update alice staker total rewards", () => {
                assert.fieldEquals("Staker", alice.toHex(), "totalClaimedRewards", usd100k.toString());
                assert.fieldEquals("Staker", alice.toHex(), "totalUnclaimedRewards", "0");
            });

            test("Should update bob staker total rewards", () => {
                assert.fieldEquals("Staker", bob.toHex(), "totalClaimedRewards", usd100k.toString());
                assert.fieldEquals("Staker", bob.toHex(), "totalUnclaimedRewards", "0");
            });

            test("Should update alice staker rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", usd100k.toString());
                assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", "0");
            });

            test("Should update bob staker rewards", () => {
                const usdtId = `${bob.toHex()}-${usdtToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", usd100k.toString());
                assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", "0");
            });
        });

        describe("Claim rewards twice for the same token", () => {
            beforeEach(() => {
                createDistribution(usdtToken, usd500k, monthsAfterInit[4]);
                distributeRewards(usdtToken, monthsAfterInit[4]);

                claimRewards(alice, usdtToken, usd100k, monthsAfterInit[5]);
                claimRewards(bob, usdtToken, usd400k, monthsAfterInit[5]);
            });
            test("Should update alice staker total rewards", () => {
                assert.fieldEquals("Staker", alice.toHex(), "totalClaimedRewards", usd200k.toString());
                assert.fieldEquals("Staker", alice.toHex(), "totalUnclaimedRewards", "0");
            });

            test("Should update bob staker total rewards", () => {
                assert.fieldEquals("Staker", bob.toHex(), "totalClaimedRewards", usd500k.toString());
                assert.fieldEquals("Staker", bob.toHex(), "totalUnclaimedRewards", "0");
            });

            test("Should update alice staker rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", usd200k.toString());
                assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", "0");
            });

            test("Should update bob staker rewards", () => {
                const usdtId = `${bob.toHex()}-${usdtToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", usd500k.toString());
                assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", "0");
            });
        });

        describe("Claim rewards twice for different tokens", () => {
            beforeEach(() => {
                createDistribution(usdcToken, usd500k, monthsAfterInit[4]);
                distributeRewards(usdcToken, monthsAfterInit[4]);

                claimRewards(alice, usdcToken, usd100k, monthsAfterInit[5]);
                claimRewards(bob, usdcToken, usd400k, monthsAfterInit[5]);
            });

            test("Should update alice staker total rewards", () => {
                assert.fieldEquals("Staker", alice.toHex(), "totalClaimedRewards", usd200k.toString());
                assert.fieldEquals("Staker", alice.toHex(), "totalUnclaimedRewards", "0");
            });

            test("Should update bob staker total rewards", () => {
                assert.fieldEquals("Staker", bob.toHex(), "totalClaimedRewards", usd500k.toString());
                assert.fieldEquals("Staker", bob.toHex(), "totalUnclaimedRewards", "0");
            });

            test("Should update alice staker rewards", () => {
                const usdcId = `${alice.toHex()}-${usdcToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdcId, "claimedAmount", usd100k.toString());
                assert.fieldEquals("StakerRewards", usdcId, "unclaimedAmount", "0");
            });

            test("Should update bob staker rewards", () => {
                const usdcId = `${bob.toHex()}-${usdcToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdcId, "claimedAmount", usd400k.toString());
                assert.fieldEquals("StakerRewards", usdcId, "unclaimedAmount", "0");
            });

            test("Should leave alice another token rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", usd100k.toString());
                assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", "0");
            });

            test("Should leave bob another token rewards", () => {
                const usdtId = `${bob.toHex()}-${usdtToken.toHex()}`;
                assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", usd100k.toString());
                assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", "0");
            });
        });
    });
});
