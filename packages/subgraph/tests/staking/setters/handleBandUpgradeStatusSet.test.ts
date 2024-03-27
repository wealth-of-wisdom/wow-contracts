import { describe, test, beforeEach, assert } from "matchstick-as/assembly/index";
import { initialize, setBandUpgradesEnabled } from "../helpers/helper";
import { ids } from "../../utils/constants";

describe("handleBandUpgradeStatusSet() tests", () => {
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
