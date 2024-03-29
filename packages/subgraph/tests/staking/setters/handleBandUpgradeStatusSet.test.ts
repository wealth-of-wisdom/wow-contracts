import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { initialize, setBandUpgradesEnabled } from "../helpers/helper";
import { ids } from "../../utils/constants";

describe("handleBandUpgradeStatusSet() tests", () => {
    beforeEach(() => {
        clearStore();
    });
    describe("Create StakingContract and band upgrade status", () => {
        beforeEach(() => {
            initialize();
        });

        test("Should affirm correct upgrade status", () => {
            assert.fieldEquals("StakingContract", ids[0], "areUpgradesEnabled", false.toString());
        });

        test("Should set upgrade status correctly", () => {
            setBandUpgradesEnabled(true);
            assert.fieldEquals("StakingContract", ids[0], "areUpgradesEnabled", true.toString());
        });
    });
});
