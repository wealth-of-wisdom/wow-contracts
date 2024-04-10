import { BigInt } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { initialize, setPool } from "../helpers/helper";
import { totalPools, ids } from "../../utils/data/constants";
import { poolIds, poolDistributionPercentages } from "../../utils/data/data";
import { BIGINT_ONE } from "../../../src/utils/constants";

let changedPoolId: BigInt;
let newPoolId: BigInt;
let newPoolDistributionPercentages: BigInt;

describe("handlePoolSet() tests", () => {
    beforeEach(() => {
        clearStore();
        initialize();

        for (let i = 0; i < totalPools.toI32(); i++) {
            const poolId: BigInt = BigInt.fromI32(i + 1);
            setPool(poolId, poolDistributionPercentages[i]);
        }
    });

    describe("Create initial 9 pools", () => {
        test("Should create 9 Pool entities", () => {
            for (let i = 0; i < totalPools.toI32(); i++) {
                assert.fieldEquals("Pool", ids[i + 1], "id", ids[i + 1]);
            }

            assert.entityCount("Pool", totalPools.toI32());
        });

        test("Should set pool values correctly", () => {
            for (let i = 0; i < totalPools.toI32(); i++) {
                assert.fieldEquals(
                    "Pool",
                    ids[i + 1],
                    "distributionPercentage",
                    poolDistributionPercentages[i].toString(),
                );
            }
        });
    });

    describe("Add new pool", () => {
        beforeEach(() => {
            newPoolId = totalPools.plus(BIGINT_ONE);
            newPoolDistributionPercentages = poolDistributionPercentages[3].plus(poolDistributionPercentages[4]);

            setPool(newPoolId, newPoolDistributionPercentages);
        });

        test("Should set new pool value correctly", () => {
            assert.fieldEquals(
                "Pool",
                newPoolId.toString(),
                "distributionPercentage",
                newPoolDistributionPercentages.toString(),
            );
        });

        test("Should leave other pool values unchanged", () => {
            for (let i = 0; i < totalPools.toI32(); i++) {
                assert.fieldEquals(
                    "Pool",
                    ids[i + 1],
                    "distributionPercentage",
                    poolDistributionPercentages[i].toString(),
                );
            }
        });
    });

    describe("Update pool", () => {
        beforeEach(() => {
            changedPoolId = poolIds[4];
            newPoolDistributionPercentages = poolDistributionPercentages[3].plus(poolDistributionPercentages[4]);

            setPool(changedPoolId, newPoolDistributionPercentages);
        });

        test("Should update existing pool", () => {
            assert.fieldEquals(
                "Pool",
                changedPoolId.toString(),
                "distributionPercentage",
                newPoolDistributionPercentages.toString(),
            );
        });

        test("Should leave other pool values unchanged", () => {
            for (let i = 0; i < totalPools.toI32(); i++) {
                if (i + 1 == changedPoolId.toI32()) {
                    continue;
                }

                assert.fieldEquals(
                    "Pool",
                    ids[i + 1],
                    "distributionPercentage",
                    poolDistributionPercentages[i].toString(),
                );
            }
        });
    });
});
