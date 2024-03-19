import { describe, test, beforeEach, clearStore, assert } from "matchstick-as/assembly/index";
import { initialize } from "./helpers/helper";
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
} from "../utils/constants";

describe("handleInitialized() tests", () => {
    beforeEach(() => {
        clearStore();
    });

    describe("Create StakingContract entity", () => {
        beforeEach(() => {
            initialize();
        });

        test("Should create a new StakingContract entity", () => {
            assert.fieldEquals("StakingContract", zeroId, "id", zeroId);
            assert.entityCount("StakingContract", 1);
        });

        test("Should set stakingContractAddress correctly", () => {
            assert.fieldEquals("StakingContract", zeroId, "stakingContractAddress", stakingAddress.toHex());
        });

        test("Should set usdtToken correctly", () => {
            assert.fieldEquals("StakingContract", zeroId, "usdtToken", usdtToken.toHex());
        });

        test("Should set usdcToken correctly", () => {
            assert.fieldEquals("StakingContract", zeroId, "usdcToken", usdcToken.toHex());
        });

        test("Should set wowToken correctly", () => {
            assert.fieldEquals("StakingContract", zeroId, "wowToken", wowToken.toHex());
        });

        test("Should set percentagePrecision correctly", () => {
            assert.fieldEquals("StakingContract", zeroId, "percentagePrecision", percentagePrecision.toString());
        });

        test("Should set totalPools correctly", () => {
            assert.fieldEquals("StakingContract", zeroId, "totalPools", totalPools.toString());
        });

        test("Should set totalBandLevels correctly", () => {
            assert.fieldEquals("StakingContract", zeroId, "totalBandLevels", totalBandLevels.toString());
        });

        test("Should set lastSharesSyncDate correctly", () => {
            assert.fieldEquals("StakingContract", zeroId, "lastSharesSyncDate", initDate.toString());
        });

        test("Should set sharesInMonths correctly", () => {
            assert.fieldEquals("StakingContract", zeroId, "sharesInMonths", "[]");
        });

        test("Should set nextBandId correctly", () => {
            assert.fieldEquals("StakingContract", zeroId, "nextBandId", zeroId);
        });

        test("Should set nextDistributionId correctly", () => {
            assert.fieldEquals("StakingContract", zeroId, "nextDistributionId", zeroId);
        });

        test("Should set areUpgradesEnabled to true", () => {
            assert.fieldEquals("StakingContract", zeroId, "areUpgradesEnabled", "true");
        });

        test("Should set stakers correctly", () => {
            assert.fieldEquals("StakingContract", zeroId, "stakers", "[]");
        });
    });
});
