import { describe, test, beforeEach, clearStore, assert } from "matchstick-as/assembly/index";
import { initialize, setDistributionInProgress } from "./helpers/helper";
import { ids } from "../utils/constants";

describe("handleDistributionStatusSetEvent() tests", () => {
    describe("Create StakingContract and enable distribution", () => {
        beforeEach(() => {
            initialize();
            setDistributionInProgress(true);
        });

        test("Should set distribution status correctly", () => {
            assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", true.toString());
        });

        test("Should set new distribution status correctly", () => {
            setDistributionInProgress(false);
            assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", false.toString());
        });
    });
});
