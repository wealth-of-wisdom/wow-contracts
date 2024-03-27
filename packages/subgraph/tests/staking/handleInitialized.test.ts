import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
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
    zeroStr,
    ids,
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
            assert.fieldEquals("StakingContract", ids[0], "id", zeroStr);
            assert.entityCount("StakingContract", 1);
        });

        test("Should set values correctly", () => {
            assert.fieldEquals("StakingContract", ids[0], "stakingContractAddress", stakingAddress.toHex());
            assert.fieldEquals("StakingContract", ids[0], "usdtToken", usdtToken.toHex());
            assert.fieldEquals("StakingContract", ids[0], "usdcToken", usdcToken.toHex());
            assert.fieldEquals("StakingContract", ids[0], "wowToken", wowToken.toHex());
            assert.fieldEquals("StakingContract", ids[0], "percentagePrecision", percentagePrecision.toString());
            assert.fieldEquals("StakingContract", ids[0], "totalPools", totalPools.toString());
            assert.fieldEquals("StakingContract", ids[0], "totalBandLevels", totalBandLevels.toString());
            assert.fieldEquals("StakingContract", ids[0], "lastSharesSyncDate", initDate.toString());
            assert.fieldEquals("StakingContract", ids[0], "sharesInMonths", "[]");
            assert.fieldEquals("StakingContract", ids[0], "nextBandId", zeroStr);
            assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", zeroStr);
            assert.fieldEquals("StakingContract", ids[0], "areUpgradesEnabled", "false");
            assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "false");
            assert.fieldEquals("StakingContract", ids[0], "stakers", "[]");
        });
    });
});
