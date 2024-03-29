import { BigInt } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { initialize, setPool } from "../helpers/helper";
import { poolDistributionPercentages, totalPools, ids } from "../../utils/constants";
import { BIGINT_ZERO, BIGINT_ONE } from "../../../src/utils/constants";

let totalShares: BigInt = BIGINT_ZERO;

describe("handlePoolSet() tests", () => {
    beforeEach(() => {
        clearStore();
    });
    describe("Create StakingContract and Set Pools", () => {
        beforeEach(() => {
            initialize();

            for (let i = 0; i < totalPools.toI32(); i++) {
                const poolId: BigInt = BigInt.fromI32(i + 1);
                setPool(poolId, poolDistributionPercentages[i]);
            }
        });

        test("Should create new Pool entity", () => {
            for (let i = 0; i < totalPools.toI32(); i++) {
                const poolId: BigInt = BigInt.fromI32(i + 1);
                assert.fieldEquals("Pool", ids[i + 1], "id", poolId.toString());
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

        test("Should new set pool value correctly and old ones are untouched", () => {
            const newPoolId = totalPools.plus(BIGINT_ONE);
            const newPoolDistributionPercentages = poolDistributionPercentages[3].plus(poolDistributionPercentages[4]);

            setPool(newPoolId, newPoolDistributionPercentages);

            for (let i = 0; i < totalPools.toI32(); i++) {
                assert.fieldEquals(
                    "Pool",
                    ids[i + 1],
                    "distributionPercentage",
                    poolDistributionPercentages[i].toString(),
                );
            }

            assert.fieldEquals(
                "Pool",
                ids[newPoolId.toI32()],
                "distributionPercentage",
                newPoolDistributionPercentages.toString(),
            );
        });
    });
});
