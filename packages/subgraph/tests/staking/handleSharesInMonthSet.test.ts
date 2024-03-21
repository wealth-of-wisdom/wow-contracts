import { describe, test, beforeEach, clearStore, assert } from "matchstick-as/assembly/index";
import { initialize, setSharesInMonth } from "./helpers/helper";
import { sharesInMonths, ids } from "../utils/constants";
import { BIGINT_ZERO } from "../../src/utils/constants";

describe("handleInitialized() tests", () => {
    beforeEach(() => {
        clearStore();
    });

    describe("Create StakingContract and Set shares in month", () => {
        beforeEach(() => {
            initialize();
            setSharesInMonth(sharesInMonths);
        });

        test("Should set shares in month array correctly", () => {
            assert.fieldEquals("StakingContract", ids[0], "sharesInMonths", sharesInMonths.toString());
        });

        test("Should set new shares correctly", () => {
            const newSharesInMonth = sharesInMonths;
            sharesInMonths[0] = BIGINT_ZERO;
            setSharesInMonth(newSharesInMonth);
            assert.fieldEquals("StakingContract", ids[0], "sharesInMonths", newSharesInMonth.toString());
        });
    });
});
