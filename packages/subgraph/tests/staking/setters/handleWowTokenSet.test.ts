import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { initialize, setWowTokenAddress } from "../helpers/helper";
import { wowToken, ids, newToken } from "../../utils/data/constants";

describe("handleWowTokenSet() tests", () => {
    beforeEach(() => {
        clearStore();
        initialize();

        setWowTokenAddress(wowToken);
    });

    test("Should set WOW token address correctly", () => {
        assert.fieldEquals("StakingContract", ids[0], "wowToken", wowToken.toHex());
    });

    test("Should set new WOW token address correctly", () => {
        const newWowToken = newToken;
        setWowTokenAddress(newWowToken);

        assert.fieldEquals("StakingContract", ids[0], "wowToken", newWowToken.toHex());
    });
});
