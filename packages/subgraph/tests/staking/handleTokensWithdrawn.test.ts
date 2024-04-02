import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { initializeAndSetUp, stakeStandardFlexi, withdrawTokens } from "./helpers/helper";
import { ids, alice, bob, bandLevels, bandIds, initDate, bandLevelPrices, wowToken } from "../utils/constants";

describe("handleTokensWithdrawn() tests", () => {
    beforeEach(() => {
        clearStore();
    });
    describe("Create StakingContract, stake and withdraw tokens", () => {
        beforeEach(() => {
            initializeAndSetUp();
            stakeStandardFlexi(alice, bandLevels[1], bandIds[0], initDate);
            withdrawTokens(wowToken, bob, bandLevelPrices[1]);
        });

        test("Should transfered tokens to bob, no data changes", () => {
            assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", bandLevelPrices[1].toString());
            assert.fieldEquals("Staker", alice.toHex(), "stakedAmount", bandLevelPrices[1].toString());
        });

        test(
            "Should throw error for trying to withdraw again (empty contract)",
            () => {
                withdrawTokens(wowToken, bob, bandLevelPrices[1]);
                throw new Error();
            },
            true,
        );
    });
});
