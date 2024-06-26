import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { initialize, setUsdtTokenAddress } from "../helpers/helper";
import { usdtToken, ids, newToken } from "../../utils/data/constants";

describe("handleUsdtTokenSet() tests", () => {
    beforeEach(() => {
        clearStore();
        initialize();

        setUsdtTokenAddress(usdtToken);
    });

    test("Should set USDT token address correctly", () => {
        assert.fieldEquals("StakingContract", ids[0], "usdtToken", usdtToken.toHex());
    });

    test("Should set new USDT token address correctly", () => {
        const newUsdtToken = newToken;
        setUsdtTokenAddress(newUsdtToken);

        assert.fieldEquals("StakingContract", ids[0], "usdtToken", newUsdtToken.toHex());
    });
});
