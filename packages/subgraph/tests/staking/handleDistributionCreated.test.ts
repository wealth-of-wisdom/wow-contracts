import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { initialize, createDistribution } from "./helpers/helper";
import { ids, usdtToken, usd100k, oneInt, initDate, zeroStr } from "../utils/constants";

describe("handleDistributionCreated() tests", () => {
    describe("Create StakingContract and create reward distribution", () => {
        beforeEach(() => {
            clearStore();
            initialize();
            createDistribution(usdtToken, usd100k, initDate);
        });

        test("Should have created distribution", () => {
            assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
            assert.fieldEquals("FundsDistribution", ids[0], "amount", usd100k.toString());
            assert.fieldEquals("FundsDistribution", ids[0], "createdAt", initDate.toString());
            assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", zeroStr);
            assert.fieldEquals("FundsDistribution", ids[0], "stakers", "[]");
            assert.fieldEquals("FundsDistribution", ids[0], "rewards", "[]");

            assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[1].toString());
            assert.fieldEquals("StakingContract", ids[0], "isDistributionInProgress", false.toString());

            assert.entityCount("FundsDistribution", oneInt);
        });
    });
});
