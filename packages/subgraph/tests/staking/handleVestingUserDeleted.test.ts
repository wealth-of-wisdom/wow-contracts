import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { initialize, deleteVestingUser, stakeVestedFlexi } from "./helpers/helper";
import { ids, bandIds, alice, usdcToken } from "../utils/data/constants";
import { bandLevels } from "../utils/data/data";
import { initDate } from "../utils/data/dates";

describe("handleVestingUserDeleted() tests", () => {
    beforeEach(() => {
        clearStore();
    });
    describe("Create StakingContract and stake", () => {
        beforeEach(() => {
            initialize();
            stakeVestedFlexi(alice, bandLevels[1], bandIds[0], initDate);
        });

        test("Should delete vesting user", () => {
            deleteVestingUser(alice);
            assert.fieldEquals("StakingContract", ids[0], "stakers", "[]");
            assert.notInStore("Staker", alice.toHex());
            assert.notInStore("Band", bandIds[0].toString());

            const usdtId = `${alice.toHex()}-${usdcToken.toHex()}`;
            const usdcId = `${alice.toHex()}-${usdcToken.toHex()}`;
            assert.notInStore("StakerRewards", usdtId);
            assert.notInStore("StakerRewards", usdcId);
        });
    });
    describe("Create StakingContract and multi stake", () => {
        beforeEach(() => {
            initialize();
            stakeVestedFlexi(alice, bandLevels[1], bandIds[0], initDate);
            stakeVestedFlexi(alice, bandLevels[2], bandIds[1], initDate);
            stakeVestedFlexi(alice, bandLevels[3], bandIds[2], initDate);
            deleteVestingUser(alice);
        });

        test("Should delete vesting user from all additional staked bands", () => {
            assert.fieldEquals("StakingContract", ids[0], "stakers", "[]");
            assert.notInStore("Staker", alice.toHex());
            assert.notInStore("Band", bandIds[0].toString());
            assert.notInStore("Band", bandIds[1].toString());
            assert.notInStore("Band", bandIds[2].toString());

            const usdtId = `${alice.toHex()}-${usdcToken.toHex()}`;
            const usdcId = `${alice.toHex()}-${usdcToken.toHex()}`;
            assert.notInStore("StakerRewards", usdtId);
            assert.notInStore("StakerRewards", usdcId);
        });
    });
});
