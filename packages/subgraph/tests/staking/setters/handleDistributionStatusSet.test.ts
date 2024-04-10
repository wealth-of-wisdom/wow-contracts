import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { initialize, setDistributionInProgress } from "../helpers/helper";
import { ids } from "../../utils/data/constants";

describe("handleDistributionStatusSet() tests", () => {
    beforeEach(() => {
        clearStore();
        initialize();
    });

    describe("Create StakingContract and enable distribution", () => {
        test("Should affirm correct distribution status", () => {
            assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", false.toString());
        });

        test("Should set distribution status correctly", () => {
            setDistributionInProgress(true);
            assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", true.toString());
        });
    });
});
