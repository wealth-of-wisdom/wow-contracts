import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { initialize, setTotalBandLevels } from "../helpers/helper";
import { totalBandLevels, ids } from "../../utils/data/constants";
import { BIGINT_ONE } from "../../../src/utils/constants";

describe("handleTotalBandLevelsAmountSet() tests", () => {
    beforeEach(() => {
        clearStore();
        initialize();

        setTotalBandLevels(totalBandLevels);
    });

    test("Should set total band levels correctly", () => {
        assert.fieldEquals("StakingContract", ids[0], "totalBandLevels", totalBandLevels.toString());
    });

    test("Should set new total band levels correctly", () => {
        const newTotalBandLevels = totalBandLevels.plus(BIGINT_ONE);
        setTotalBandLevels(newTotalBandLevels);

        assert.fieldEquals("StakingContract", ids[0], "totalBandLevels", newTotalBandLevels.toString());
    });
});
