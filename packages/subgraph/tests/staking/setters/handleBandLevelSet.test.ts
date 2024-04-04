import { BigInt } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, clearStore, assert } from "matchstick-as/assembly/index";
import { initialize, setBandLevel } from "../helpers/helper";
import { convertBigIntArrayToString } from "../../utils/arrays";
import { totalBandLevels, totalPools, ids } from "../../utils/data/constants";
import { bandLevels, bandLevelPrices, bandLevelAccessiblePools } from "../../utils/data/data";
import { BIGINT_ONE } from "../../../src/utils/constants";

let changedBandLevel: BigInt;
let newBandLevel: BigInt;
let newPrice: BigInt;
let newAccessiblePools: BigInt[];

describe("handleBandLevelSet() tests", () => {
    beforeEach(() => {
        clearStore();
        initialize();

        for (let i = 0; i < totalBandLevels.toI32(); i++) {
            const bandLevel: BigInt = BigInt.fromI32(i + 1);
            setBandLevel(bandLevel, bandLevelPrices[i], bandLevelAccessiblePools[i]);
        }
    });

    describe("Create initial 9 band levels", () => {
        test("Should create 9 BandLevel entities", () => {
            for (let i = 0; i < totalBandLevels.toI32(); i++) {
                assert.fieldEquals("BandLevel", ids[i + 1], "id", ids[i + 1]);
            }

            assert.entityCount("BandLevel", totalBandLevels.toI32());
        });

        test("Should set band level values correctly", () => {
            for (let i = 0; i < totalBandLevels.toI32(); i++) {
                assert.fieldEquals("BandLevel", ids[i + 1], "price", bandLevelPrices[i].toString());
                assert.fieldEquals(
                    "BandLevel",
                    ids[i + 1],
                    "accessiblePools",
                    convertBigIntArrayToString(bandLevelAccessiblePools[i]),
                );
            }
        });

        test("Should create 9 Pool entities", () => {
            for (let i = 0; i < totalPools.toI32(); i++) {
                assert.fieldEquals("BandLevel", ids[i + 1], "id", ids[i + 1]);
            }

            assert.entityCount("Pool", totalPools.toI32());
        });
    });

    describe("Add new band level", () => {
        beforeEach(() => {
            newBandLevel = totalBandLevels.plus(BIGINT_ONE);
            newPrice = bandLevelPrices[4];
            newAccessiblePools = bandLevelAccessiblePools[3];

            setBandLevel(newBandLevel, newPrice, newAccessiblePools);
        });

        test("Should set new band level value correctly", () => {
            assert.fieldEquals("BandLevel", ids[newBandLevel.toI32()], "price", newPrice.toString());
            assert.fieldEquals(
                "BandLevel",
                ids[newBandLevel.toI32()],
                "accessiblePools",
                convertBigIntArrayToString(newAccessiblePools),
            );
        });

        test("Should leave old band levels untouched", () => {
            for (let i = 0; i < totalBandLevels.toI32(); i++) {
                assert.fieldEquals("BandLevel", ids[i + 1], "price", bandLevelPrices[i].toString());
                assert.fieldEquals(
                    "BandLevel",
                    ids[i + 1],
                    "accessiblePools",
                    convertBigIntArrayToString(bandLevelAccessiblePools[i]),
                );
            }
        });
    });

    describe("Update band level", () => {
        beforeEach(() => {
            changedBandLevel = bandLevels[2];
            newPrice = bandLevelPrices[5];
            newAccessiblePools = bandLevelAccessiblePools[5];

            setBandLevel(changedBandLevel, newPrice, newAccessiblePools);
        });

        test("Should update existing band level", () => {
            assert.fieldEquals("BandLevel", changedBandLevel.toString(), "price", newPrice.toString());
            assert.fieldEquals(
                "BandLevel",
                changedBandLevel.toString(),
                "accessiblePools",
                convertBigIntArrayToString(newAccessiblePools),
            );
        });

        test("Should leave old band levels untouched", () => {
            for (let i = 0; i < totalBandLevels.toI32(); i++) {
                if (i + 1 == changedBandLevel.toI32()) {
                    continue;
                }

                assert.fieldEquals("BandLevel", ids[i + 1], "price", bandLevelPrices[i].toString());
                assert.fieldEquals(
                    "BandLevel",
                    ids[i + 1],
                    "accessiblePools",
                    convertBigIntArrayToString(bandLevelAccessiblePools[i]),
                );
            }
        });
    });
});
