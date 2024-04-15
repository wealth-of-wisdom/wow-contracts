import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { initialize } from "./helpers/helper";
import {
    stakingAddress,
    usdtToken,
    usdcToken,
    wowToken,
    percentagePrecision,
    sharePrecision,
    totalPools,
    totalBandLevels,
    ids,
} from "../utils/data/constants";
import { initDate } from "../utils/data/dates";

describe("handleInitialized() tests", () => {
    beforeEach(() => {
        clearStore();
        initialize();
    });

    test("Should create a new StakingContract entity", () => {
        assert.fieldEquals("StakingContract", ids[0], "id", ids[0]);
        assert.entityCount("StakingContract", 1);
    });

    test("Should set values correctly", () => {
        assert.fieldEquals("StakingContract", ids[0], "stakingContractAddress", stakingAddress.toHex());
        assert.fieldEquals("StakingContract", ids[0], "usdtToken", usdtToken.toHex());
        assert.fieldEquals("StakingContract", ids[0], "usdcToken", usdcToken.toHex());
        assert.fieldEquals("StakingContract", ids[0], "wowToken", wowToken.toHex());
        assert.fieldEquals("StakingContract", ids[0], "percentagePrecision", percentagePrecision.toString());
        assert.fieldEquals("StakingContract", ids[0], "sharePrecision", sharePrecision.toString());
        assert.fieldEquals("StakingContract", ids[0], "totalPools", totalPools.toString());
        assert.fieldEquals("StakingContract", ids[0], "totalBandLevels", totalBandLevels.toString());
        assert.fieldEquals("StakingContract", ids[0], "lastSharesSyncDate", initDate.toString());
        assert.fieldEquals("StakingContract", ids[0], "sharesInMonths", "[]");
        assert.fieldEquals("StakingContract", ids[0], "nextBandId", ids[0]);
        assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[0]);
        assert.fieldEquals("StakingContract", ids[0], "areUpgradesEnabled", "false");
        assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", "false");
        assert.fieldEquals("StakingContract", ids[0], "stakers", "[]");
    });
});
