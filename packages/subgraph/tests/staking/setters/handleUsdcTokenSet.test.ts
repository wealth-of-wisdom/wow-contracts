import { describe, test, beforeEach, assert } from "matchstick-as/assembly/index";
import { initialize, setUsdcTokenAddress } from "../helpers/helper";
import { usdcToken, ids, newToken } from "../../utils/constants";

describe("handleUsdcTokenSet() tests", () => {
    describe("Create StakingContract and Set USDC token", () => {
        beforeEach(() => {
            initialize();
            setUsdcTokenAddress(usdcToken);
        });

        test("Should set USDC token address correctly", () => {
            assert.fieldEquals("StakingContract", ids[0], "usdcToken", usdcToken.toHex());
        });

        test("Should set new USDC token address correctly", () => {
            const newUsdcToken = newToken;
            setUsdcTokenAddress(newUsdcToken);

            assert.fieldEquals("StakingContract", ids[0], "usdcToken", newUsdcToken.toHex());
        });
    });
});
