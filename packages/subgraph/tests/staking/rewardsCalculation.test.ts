import { BigInt } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, clearStore, assert } from "matchstick-as/assembly/index";
import { initialize, setPool, setBandLevel, setSharesInMonth } from "./helpers/helper";
import {
    stakingAddress,
    usdtToken,
    usdcToken,
    wowToken,
    percentagePrecision,
    totalPools,
    totalBandLevels,
    initDate,
    zeroId,
    poolDistributionPercentages,
    bandLevelPrices,
    bandLevelAccessiblePools,
} from "../utils/constants";

describe("tests", () => {
    beforeEach(() => {
        clearStore();
    });

    describe("-", () => {
        beforeEach(() => {
            initialize();

            for (let i = 0; i < totalPools.toI32(); i++) {
                const poolId: BigInt = BigInt.fromI32(i + 1);
                setPool(poolId, poolDistributionPercentages[i]);
            }

            for (let i = 0; i < totalBandLevels.toI32(); i++) {
                const bandLevel: BigInt = BigInt.fromI32(i + 1);
                setBandLevel(bandLevel, bandLevelPrices[i], bandLevelAccessiblePools[i]);
            }

            // setSharesInMonth([BigInt.fromI32(0)]);
        });

        test("Should create a new StakingContract entity", () => {
            assert.fieldEquals("StakingContract", zeroId, "id", zeroId);
            assert.entityCount("StakingContract", 1);
        });
    });
});
