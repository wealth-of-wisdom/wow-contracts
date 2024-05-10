import { BigInt } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, clearStore, assert } from "matchstick-as/assembly/index";
import { initializeAndSetUp, stakeStandardFlexi, downgradeBand } from "./helpers/helper";
import { alice, ids, bandIds } from "../utils/data/constants";
import { initDate } from "../utils/data/dates";
import { bandLevels, bandLevelPrices } from "../utils/data/data";

const starterLevel = 5;
const firstDowngradeLevel = 3;
const secondDowngradeLevel = 1;

describe("handleBandDowngraded() tests", () => {
    beforeEach(() => {
        clearStore();
        initializeAndSetUp();

        stakeStandardFlexi(alice, bandLevels[starterLevel - 1], bandIds[0], initDate);
    });

    describe("Downgrade band once", () => {
        beforeEach(() => {
            downgradeBand(
                alice,
                BigInt.fromString(ids[0]),
                BigInt.fromI32(starterLevel),
                BigInt.fromI32(firstDowngradeLevel),
                bandLevelPrices[8],
                initDate,
            );
        });

        test("Should change band level", () => {
            assert.fieldEquals("Band", ids[0], "bandLevel", firstDowngradeLevel.toString());
            assert.entityCount("Band", 1);
        });

        test("Should change total staked amount", () => {
            assert.fieldEquals(
                "StakingContract",
                ids[0],
                "totalStakedAmount",
                bandLevelPrices[firstDowngradeLevel - 1].toString(),
            );
        });

        test("Should change staker's staked amount", () => {
            assert.fieldEquals(
                "Staker",
                alice.toHex(),
                "stakedAmount",
                bandLevelPrices[firstDowngradeLevel - 1].toString(),
            );
            assert.entityCount("Staker", 1);
        });
    });

    describe("Downgrade band twice", () => {
        beforeEach(() => {
            downgradeBand(
                alice,
                BigInt.fromString(ids[0]),
                BigInt.fromI32(starterLevel),
                BigInt.fromI32(firstDowngradeLevel),
                bandLevelPrices[8],
                initDate,
            );
            downgradeBand(
                alice,
                BigInt.fromString(ids[0]),
                BigInt.fromI32(firstDowngradeLevel),
                BigInt.fromI32(secondDowngradeLevel),
                bandLevelPrices[7],
                initDate,
            );
        });

        test("Should change band level", () => {
            assert.fieldEquals("Band", ids[0], "bandLevel", secondDowngradeLevel.toString());
            assert.entityCount("Band", 1);
        });

        test("Should change total staked amount", () => {
            assert.fieldEquals(
                "StakingContract",
                ids[0],
                "totalStakedAmount",
                bandLevelPrices[secondDowngradeLevel - 1].toString(),
            );
        });

        test("Should change staker's staked amount", () => {
            assert.fieldEquals(
                "Staker",
                alice.toHex(),
                "stakedAmount",
                bandLevelPrices[secondDowngradeLevel - 1].toString(),
            );
            assert.entityCount("Staker", 1);
        });
    });
});
