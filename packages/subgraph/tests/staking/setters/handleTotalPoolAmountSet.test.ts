import { describe, test, beforeEach, assert } from "matchstick-as/assembly/index";
import { initialize, setTotalPools } from "../helpers/helper";
import { totalPools, ids } from "../../utils/constants";
import { BIGINT_ONE } from "../../../src/utils/constants";

describe("handleTotalPoolAmountSet() tests", () => {
    describe("Create StakingContract and Set total pools", () => {
        beforeEach(() => {
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
});
