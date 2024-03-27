import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { initialize, deleteVestingUser, stakeVestedFlexi } from "./helpers/helper";
import { ids, alice, bandLevels, bandIds, initDate, usdcToken } from "../utils/constants";

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
});
