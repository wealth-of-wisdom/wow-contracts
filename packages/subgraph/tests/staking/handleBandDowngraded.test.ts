import { BigInt } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, clearStore, assert } from "matchstick-as/assembly/index";
import { initialize, initializeAndSetUp, stakeStandardFlexi, downgradeBand } from "./helpers/helper";
import { alice, initDate, bandLevelPrices, bandLevels, ids, bandIds } from "../utils/constants";

const starterLevel = 5;
const firstDowngradeLevel = 3;
const secondDowngradeLevel = 1;

describe("handleBandDowngraded() tests", () => {
    beforeEach(() => {
        clearStore();
    });
    //NOTE: share functionality for downgrade bands - incomplete
    describe("Create StakingContract, stake and downgrade band", () => {
        beforeEach(() => {
            clearStore();
            initialize();

            initializeAndSetUp();
            stakeStandardFlexi(alice, bandLevels[starterLevel - 1], bandIds[0], initDate);
            downgradeBand(
                alice,
                BigInt.fromString(ids[0]),
                BigInt.fromI32(starterLevel),
                BigInt.fromI32(firstDowngradeLevel),
                initDate,
            );
        });

        test("Should downgrade band and change band level", () => {
            //Assert changed field
            assert.fieldEquals("Band", ids[0], "bandLevel", firstDowngradeLevel.toString());
            assert.fieldEquals(
                "StakingContract",
                ids[0],
                "totalStakedAmount",
                bandLevelPrices[firstDowngradeLevel - 1].toString(),
            );
            assert.fieldEquals(
                "Staker",
                alice.toHex(),
                "stakedAmount",
                bandLevelPrices[firstDowngradeLevel - 1].toString(),
            );
            assert.entityCount("Band", 1);
            assert.entityCount("Staker", 1);
        });
    });

    describe("Create StakingContract, stake and downgrade band two times", () => {
        beforeEach(() => {
            clearStore();
            initialize();

            initializeAndSetUp();
            stakeStandardFlexi(alice, bandLevels[starterLevel - 1], bandIds[0], initDate);
            downgradeBand(
                alice,
                BigInt.fromString(ids[0]),
                BigInt.fromI32(starterLevel),
                BigInt.fromI32(firstDowngradeLevel),
                initDate,
            );
            downgradeBand(
                alice,
                BigInt.fromString(bandIds[0].toString()),
                BigInt.fromI32(firstDowngradeLevel),
                BigInt.fromI32(secondDowngradeLevel),
                initDate,
            );
        });

        test("Should allow another downgrade and change band level", () => {
            //Assert changed field
            assert.fieldEquals("Band", bandIds[0].toString(), "bandLevel", secondDowngradeLevel.toString());
            assert.fieldEquals(
                "StakingContract",
                ids[0],
                "totalStakedAmount",
                bandLevelPrices[secondDowngradeLevel - 1].toString(),
            );
            assert.fieldEquals(
                "Staker",
                alice.toHex(),
                "stakedAmount",
                bandLevelPrices[secondDowngradeLevel - 1].toString(),
            );

            assert.entityCount("Band", 1);
            assert.entityCount("Staker", 1);
        });
    });
});
