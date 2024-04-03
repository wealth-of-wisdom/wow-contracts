import { BigInt } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import {
    initializeAndSetUp,
    stakeStandardFlexi,
    createDistribution,
    distributeRewards,
    claimRewards,
} from "./helpers/helper";
import { alice, bandLevels, bandIds, preInitDate, initDate, usdtToken, usd100k, zeroStr } from "../utils/constants";

const initialClaimAmount: BigInt = BigInt.fromI32(100);
const initialUnclaimedAmount: BigInt = BigInt.fromI32(0).minus(initialClaimAmount);
const secondaryClaimAmount: BigInt = BigInt.fromI32(200);

describe("handleRewardsClaimed() tests", () => {
    beforeEach(() => {
        clearStore();
    });
    describe("Create StakingContract, create reward distributions, distribute rewards, stake and claim rewards", () => {
        beforeEach(() => {
            initializeAndSetUp();
            createDistribution(usdtToken, usd100k, preInitDate);
            distributeRewards(usdtToken, preInitDate);
            stakeStandardFlexi(alice, bandLevels[1], bandIds[0], initDate);

            claimRewards(alice, usdtToken, initialClaimAmount, initDate);
        });

        test("Should transfered tokens to alice", () => {
            assert.fieldEquals("Staker", alice.toHex(), "totalClaimedRewards", initialClaimAmount.toString());
            assert.fieldEquals("Staker", alice.toHex(), "totalUnclaimedRewards", initialUnclaimedAmount.toString());

            const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
            assert.fieldEquals("StakerRewards", usdtId, "claimedAmount", initialClaimAmount.toString());
            assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", zeroStr);
        });
    });

    describe("Create StakingContract, create reward distributions, distribute rewards, stake and claim rewards", () => {
        beforeEach(() => {
            initializeAndSetUp();
            createDistribution(usdtToken, usd100k, preInitDate);
            distributeRewards(usdtToken, preInitDate);
            stakeStandardFlexi(alice, bandLevels[1], bandIds[0], initDate);

            claimRewards(alice, usdtToken, initialClaimAmount, initDate);
            claimRewards(alice, usdtToken, secondaryClaimAmount, initDate);
        });

        test("Should be able to claim again and transfered tokens to alice", () => {
            assert.fieldEquals(
                "Staker",
                alice.toHex(),
                "totalClaimedRewards",
                initialClaimAmount.plus(secondaryClaimAmount).toString(),
            );
            assert.fieldEquals(
                "Staker",
                alice.toHex(),
                "totalUnclaimedRewards",
                initialUnclaimedAmount.minus(secondaryClaimAmount).toString(),
            );

            const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
            assert.fieldEquals(
                "StakerRewards",
                usdtId,
                "claimedAmount",
                initialClaimAmount.plus(secondaryClaimAmount).toString(),
            );
            assert.fieldEquals("StakerRewards", usdtId, "unclaimedAmount", zeroStr);
        });
    });
});
