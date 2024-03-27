import { describe, test, beforeEach, assert } from "matchstick-as/assembly/index";
import { initialize, createDistribution } from "./helpers/helper";
import { ids, usdtToken, usd100k, oneInt, initDate, usdcToken, preInitDate, zeroStr } from "../utils/constants";

describe("handleMultiDistributionCreations() tests", () => {
    describe("Create StakingContract and create reward distribution", () => {
        beforeEach(() => {
            initialize();
            createDistribution(usdcToken, usd100k, preInitDate);
            createDistribution(usdtToken, usd100k, initDate);
        });

        test("Should have multi distributions created", () => {
            const totalFundDistributionAmount = 2;
            assert.fieldEquals("FundsDistribution", ids[0], "token", usdcToken.toHex());
            assert.fieldEquals("FundsDistribution", ids[0], "amount", usd100k.toString());
            assert.fieldEquals("FundsDistribution", ids[0], "createdAt", preInitDate.toString());
            assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", zeroStr);
            assert.fieldEquals("FundsDistribution", ids[0], "stakers", "[]");
            assert.fieldEquals("FundsDistribution", ids[0], "rewards", "[]");

            assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[2].toString());
            assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", false.toString());

            assert.fieldEquals("FundsDistribution", ids[1], "token", usdtToken.toHex());
            assert.fieldEquals("FundsDistribution", ids[1], "amount", usd100k.toString());
            assert.fieldEquals("FundsDistribution", ids[1], "createdAt", initDate.toString());
            assert.fieldEquals("FundsDistribution", ids[1], "distributedAt", zeroStr);
            assert.fieldEquals("FundsDistribution", ids[1], "stakers", "[]");
            assert.fieldEquals("FundsDistribution", ids[1], "rewards", "[]");

            assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[2].toString());
            assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", false.toString());

            assert.entityCount("FundsDistribution", totalFundDistributionAmount);
        });
    });
});
