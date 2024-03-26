import { describe, test, beforeEach, clearStore, assert } from "matchstick-as/assembly/index";
import { initialize, setBandUpgradesEnabled, setUsdtTokenAddress } from "./helpers/helper";
import { ids } from "../utils/constants";

describe("handleBandUpgradeStatusSet() tests", () => {
    describe("Create StakingContract and band upgrade status", () => {
        beforeEach(() => {
            initialize();
            setBandUpgradesEnabled(true);
        });

        test("Should set band upgrade status correctly", () => {
            assert.fieldEquals("StakingContract", ids[0], "areUpgradesEnabled", true.toString());
        });

        test("Should set new band upgrade status correctly", () => {
            setBandUpgradesEnabled(false);
            assert.fieldEquals("StakingContract", ids[0], "areUpgradesEnabled", false.toString());
        });
    });
});
