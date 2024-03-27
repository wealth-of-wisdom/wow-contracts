import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { initialize, createDistribution, distributeRewards } from "./helpers/helper";
import { ids, preInitDate, usdtToken, usd100k, oneInt } from "../utils/constants";

describe("handleRewardsDistributed() tests", () => {
    beforeEach(() => {
        clearStore();
    });
    describe("Create StakingContract, create reward distributions and distribute rewards", () => {
        beforeEach(() => {
            initialize();
            createDistribution(usdtToken, usd100k, preInitDate);
            distributeRewards(usdtToken, preInitDate);
        });

        test("Should have rewards distributed", () => {
            assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
            assert.fieldEquals("FundsDistribution", ids[0], "amount", usd100k.toString());
            assert.fieldEquals("FundsDistribution", ids[0], "createdAt", preInitDate.toString());
            assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", preInitDate.toString());
            assert.fieldEquals("FundsDistribution", ids[0], "stakers", "[]");
            assert.fieldEquals("FundsDistribution", ids[0], "rewards", "[]");

            assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[1].toString());
            assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", false.toString());

            assert.entityCount("FundsDistribution", oneInt);
        });
    });
});
