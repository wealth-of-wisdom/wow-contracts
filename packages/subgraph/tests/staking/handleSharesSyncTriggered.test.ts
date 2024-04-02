import { BigInt } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { initializeAndSetUp, stakeStandardFlexi, createDistribution, distributeRewards } from "./helpers/helper";
import {
    alice,
    bandLevels,
    bandIds,
    preInitDate,
    initDate,
    usdtToken,
    usd100k,
    ids,
    totalPools,
} from "../utils/constants";
import { convertBigIntArrayToString, createEmptyArray } from "../utils/arrays";
import { syncFlexiSharesEvery12Hours } from "../../src/utils/staking/sharesSync";

let flexiStakerShares: BigInt[] = createEmptyArray(totalPools);
let isolatedFlexiStakerShares: BigInt[] = createEmptyArray(totalPools);

describe("handleSharesSyncTriggered() tests", () => {
    beforeEach(() => {
        clearStore();
    });
    describe("Create StakingContract, create reward distributions, distribute rewards, stake and sync shares", () => {
        beforeEach(() => {
            initializeAndSetUp();
            createDistribution(usdtToken, usd100k, preInitDate);
            distributeRewards(usdtToken, preInitDate);
            stakeStandardFlexi(alice, bandLevels[1], bandIds[0], initDate);

            syncFlexiSharesEvery12Hours(initDate);
        });

        test("Should set shares sync data", () => {
            assert.fieldEquals("StakingContract", ids[0], "lastSharesSyncDate", initDate.toString());
            assert.fieldEquals(
                "Staker",
                alice.toHex(),
                "flexiSharesPerPool",
                convertBigIntArrayToString(flexiStakerShares),
            );
            assert.fieldEquals(
                "Staker",
                alice.toHex(),
                "isolatedFlexiSharesPerPool",
                convertBigIntArrayToString(isolatedFlexiStakerShares),
            );
        });
    });
});
