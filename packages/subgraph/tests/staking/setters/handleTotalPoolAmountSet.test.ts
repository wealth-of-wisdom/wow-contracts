import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { initialize, setTotalPools } from "../helpers/helper";
import { totalPools, ids } from "../../utils/data/constants";
import { BIGINT_ONE } from "../../../src/utils/constants";

describe("handleTotalPoolAmountSet() tests", () => {
    beforeEach(() => {
        clearStore();
        initialize();

        setTotalPools(totalPools);
    });

    test("Should set total pools correctly", () => {
        assert.fieldEquals("StakingContract", ids[0], "totalPools", totalPools.toString());
    });

    test("Should set new total pools correctly", () => {
        const newTotalPools = totalPools.plus(BIGINT_ONE);
        setTotalPools(newTotalPools);

        assert.fieldEquals("StakingContract", ids[0], "totalPools", newTotalPools.toString());
    });
});
