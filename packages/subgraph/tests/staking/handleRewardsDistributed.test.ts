import { describe, test, beforeEach, assert } from "matchstick-as/assembly/index";
import {
    initialize,
    stakeStandardFlexi,
    createDistribution,
    distributeRewards,
    concatAndNormalizeToArray,
} from "./helpers/helper";
import {
    ids,
    alice,
    bandLevels,
    bandIds,
    initDate,
    usdtToken,
    usdcToken,
    usd100k,
    zeroStr,
    oneStr,
} from "../utils/constants";
import { BigInt } from "@graphprotocol/graph-ts";

describe("handleRewardsDistributed() tests", () => {
    describe("Create StakingContract, create reward distributions and distribute rewards", () => {
        beforeEach(() => {
            initialize();
            createDistribution(usdtToken, usd100k, BigInt.fromString(oneStr));
            distributeRewards(usdtToken, BigInt.fromString(oneStr));
        });

        test("Should have rewards distributed", () => {
            assert.fieldEquals("FundsDistribution", ids[0], "token", usdtToken.toHex());
            assert.fieldEquals("FundsDistribution", ids[0], "amount", usd100k.toString());
            assert.fieldEquals("FundsDistribution", ids[0], "createdAt", oneStr);
            assert.fieldEquals("FundsDistribution", ids[0], "distributedAt", oneStr);
            assert.fieldEquals("FundsDistribution", ids[0], "stakers", "[]");
            assert.fieldEquals("FundsDistribution", ids[0], "rewards", "[]");
            assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[1].toString());
        });

        test("Should stake and distribute rewards again", () => {
            stakeStandardFlexi(alice, bandLevels[1], bandIds[0], initDate);
            createDistribution(usdtToken, usd100k, initDate);
            distributeRewards(usdtToken, initDate);

            assert.fieldEquals("FundsDistribution", ids[2], "token", usdtToken.toHex());
            assert.fieldEquals("FundsDistribution", ids[2], "amount", usd100k.toString());
            assert.fieldEquals("FundsDistribution", ids[2], "createdAt", initDate.toString());
            assert.fieldEquals("FundsDistribution", ids[2], "distributedAt", initDate.toString());
            assert.fieldEquals("FundsDistribution", ids[2], "stakers", concatAndNormalizeToArray(alice.toHex()));
            assert.fieldEquals("FundsDistribution", ids[2], "rewards", concatAndNormalizeToArray(zeroStr));
            assert.fieldEquals("StakingContract", ids[0], "nextDistributionId", ids[3].toString());

            assert.fieldEquals("Staker", alice.toHex(), "totalUnclaimedRewards", zeroStr);

            const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
            assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", zeroStr);
        });
    });
});
