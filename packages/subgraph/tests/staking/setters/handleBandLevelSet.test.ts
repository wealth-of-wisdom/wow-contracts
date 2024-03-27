import { BigInt } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, clearStore, assert } from "matchstick-as/assembly/index";
import { initialize, setBandLevel } from "../helpers/helper";
import { convertBigIntArrayToString } from "../../utils/arrays";
import { totalBandLevels, bandLevelPrices, bandLevelAccessiblePools, ids, bandLevels } from "../../utils/constants";
import { BIGINT_ONE } from "../../../src/utils/constants";

describe("handleBandLevelSet() tests", () => {
    beforeEach(() => {
        clearStore();
    });

    describe("Create StakingContract and Set Band Levels", () => {
        beforeEach(() => {
            initialize();

            for (let i = 0; i < totalBandLevels.toI32(); i++) {
                const bandLevel: BigInt = BigInt.fromI32(i + 1);
                setBandLevel(bandLevel, bandLevelPrices[i], bandLevelAccessiblePools[i]);
            }
        });

        test("Should create new BandLevel entity", () => {
            for (let i = 0; i < totalBandLevels.toI32(); i++) {
                const bandLevel: BigInt = BigInt.fromI32(i + 1);
                assert.fieldEquals("BandLevel", ids[i + 1], "id", bandLevel.toString());
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

        test("Should set new band level value correctly and old ones are untouched", () => {
            const newBandLevel = totalBandLevels.plus(BIGINT_ONE);
            const newPrice = bandLevelPrices[4];
            const newBandLevelAccessiblePools = bandLevelAccessiblePools[3];

            setBandLevel(newBandLevel, newPrice, newBandLevelAccessiblePools);

            for (let i = 0; i < totalBandLevels.toI32(); i++) {
                assert.fieldEquals("BandLevel", ids[i + 1], "price", bandLevelPrices[i].toString());
                assert.fieldEquals(
                    "BandLevel",
                    ids[i + 1],
                    "accessiblePools",
                    convertBigIntArrayToString(bandLevelAccessiblePools[i]),
                );
            }

            assert.fieldEquals("BandLevel", ids[newBandLevel.toI32()], "price", newPrice.toString());
            assert.fieldEquals(
                "BandLevel",
                ids[newBandLevel.toI32()],
                "accessiblePools",
                convertBigIntArrayToString(newBandLevelAccessiblePools),
            );
        });

        test("Should update existing band level", () => {
            const changedBandLevel = bandLevels[2];
            const newPrice = bandLevelPrices[3];
            const newBandLevelAccessiblePools = bandLevelAccessiblePools[3];

            setBandLevel(changedBandLevel, newPrice, newBandLevelAccessiblePools);

            assert.fieldEquals("BandLevel", changedBandLevel.toString(), "price", newPrice.toString());
            assert.fieldEquals(
                "BandLevel",
                changedBandLevel.toString(),
                "accessiblePools",
                convertBigIntArrayToString(newBandLevelAccessiblePools),
            );
        });
    });
});
