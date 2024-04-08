import { BigInt } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, clearStore, assert } from "matchstick-as/assembly/index";
import { initializeAndSetUp, stakeStandardFlexi, upgradeBand } from "./helpers/helper";
import { alice, ids, bandIds } from "../utils/data/constants";
import { initDate } from "../utils/data/dates";
import { bandLevels, bandLevelPrices } from "../utils/data/data";

const starterLevel = 1;
const firstUpgradeLevel = 2;
const secondUpgradeLevel = 4;

describe("Create StakingContract, stake and upgrade band two times", () => {
    beforeEach(() => {
        clearStore();
        initializeAndSetUp();

        stakeStandardFlexi(alice, bandLevels[starterLevel - 1], bandIds[0], initDate);
    });

    describe("Upgrade band once", () => {
        beforeEach(() => {
            upgradeBand(
                alice,
                BigInt.fromString(ids[0]),
                BigInt.fromI32(starterLevel),
                BigInt.fromI32(firstUpgradeLevel),
                initDate,
            );
        });

        test("Should change band level", () => {
            assert.fieldEquals("Band", ids[0], "bandLevel", firstUpgradeLevel.toString());
            assert.entityCount("Band", 1);
        });

        test("Should change total staked amount", () => {
            assert.fieldEquals(
                "StakingContract",
                ids[0],
                "totalStakedAmount",
                bandLevelPrices[firstUpgradeLevel - 1].toString(),
            );
        });

        test("Should change staker's staked amount", () => {
            assert.fieldEquals(
                "Staker",
                alice.toHex(),
                "stakedAmount",
                bandLevelPrices[firstUpgradeLevel - 1].toString(),
            );
            assert.entityCount("Staker", 1);
        });
    });

    describe("Upgrade band twice", () => {
        beforeEach(() => {
            upgradeBand(
                alice,
                BigInt.fromString(ids[0]),
                BigInt.fromI32(starterLevel),
                BigInt.fromI32(firstUpgradeLevel),
                initDate,
            );
            upgradeBand(
                alice,
                BigInt.fromString(ids[0]),
                BigInt.fromI32(firstUpgradeLevel),
                BigInt.fromI32(secondUpgradeLevel),
                initDate,
            );
        });

        test("Should change band level", () => {
            assert.fieldEquals("Band", ids[0], "bandLevel", secondUpgradeLevel.toString());
            assert.entityCount("Band", 1);
        });

        test("Should change total staked amount", () => {
            assert.fieldEquals(
                "StakingContract",
                ids[0],
                "totalStakedAmount",
                bandLevelPrices[secondUpgradeLevel - 1].toString(),
            );
        });

        test("Should change staker's staked amount", () => {
            assert.fieldEquals(
                "Staker",
                alice.toHex(),
                "stakedAmount",
                bandLevelPrices[secondUpgradeLevel - 1].toString(),
            );
            assert.entityCount("Staker", 1);
        });
    });
});
