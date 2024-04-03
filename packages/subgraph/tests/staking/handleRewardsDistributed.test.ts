import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { initialize, stakeStandardFlexi, createDistribution, distributeRewards } from "./helpers/helper";
import { convertStringToWrappedArray } from "../utils/arrays";
import {
    ids,
    alice,
    bandLevels,
    bandIds,
    initDate,
    preInitDate,
    usdtToken,
    usd100k,
    zeroStr,
} from "../utils/constants";

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

            assert.entityCount("FundsDistribution", 1);
        });
    });

    describe("Create StakingContract, create reward distributions and distribute rewards", () => {
        beforeEach(() => {
            initialize();
            createDistribution(usdtToken, usd100k, preInitDate);
            distributeRewards(usdtToken, preInitDate);
            stakeStandardFlexi(alice, bandLevels[1], bandIds[0], initDate);
            createDistribution(usdtToken, usd100k, initDate);
            distributeRewards(usdtToken, initDate);
        });

        test("Should stake and distribute rewards again", () => {
            const totalDistributions = 2;
            assert.fieldEquals("FundsDistribution", ids[1], "token", usdtToken.toHex());
            assert.fieldEquals("FundsDistribution", ids[1], "amount", usd100k.toString());
            assert.fieldEquals("FundsDistribution", ids[1], "createdAt", initDate.toString());
            assert.fieldEquals("FundsDistribution", ids[1], "distributedAt", initDate.toString());
            assert.fieldEquals("FundsDistribution", ids[1], "stakers", convertStringToWrappedArray(alice.toHex()));
            assert.fieldEquals("FundsDistribution", ids[1], "rewards", convertStringToWrappedArray(zeroStr));
            assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[2].toString());

            assert.fieldEquals("Staker", alice.toHex(), "totalUnclaimedRewards", zeroStr);

            const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
            assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", zeroStr);

            assert.entityCount("FundsDistribution", totalDistributions);
        });
    });
});
