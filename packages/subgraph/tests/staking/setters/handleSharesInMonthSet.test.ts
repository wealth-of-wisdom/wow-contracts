import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { initialize, setSharesInMonth } from "../helpers/helper";
import { convertBigIntArrayToString } from "../../utils/arrays";
import { ids } from "../../utils/data/constants";
import { sharesInMonths } from "../../utils/data/data";

describe("handleInitialized() tests", () => {
    beforeEach(() => {
        clearStore();
        initialize();

        setSharesInMonth(sharesInMonths);
    });

    test("Should set shares in month array correctly", () => {
        assert.fieldEquals("StakingContract", ids[0], "sharesInMonths", convertBigIntArrayToString(sharesInMonths));
    });

    test("Should update shares in month array correctly", () => {
        const newSharesInMonth = sharesInMonths;
        newSharesInMonth[11] = sharesInMonths[11].plus(sharesInMonths[11]);

        setSharesInMonth(newSharesInMonth);

        assert.fieldEquals("StakingContract", ids[0], "sharesInMonths", convertBigIntArrayToString(newSharesInMonth));
    });
});
