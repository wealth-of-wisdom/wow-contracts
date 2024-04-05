import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import { initialize, deleteVestingUser, stakeVestedFlexi, unstake } from "./helpers/helper";
import { ids, bandIds, alice, usdcToken } from "../utils/data/constants";
import { bandLevels } from "../utils/data/data";
import { initDate } from "../utils/data/dates";
import { BIGDEC_ZERO, BIGINT_ZERO } from "../../src/utils/constants";

describe("handleUnstaked() tests", () => {
    beforeEach(() => {
        clearStore();
    });
    describe("Create StakingContract, stake and ustake", () => {
        beforeEach(() => {
            initialize();
            stakeVestedFlexi(alice, bandLevels[1], bandIds[0], initDate);
            unstake(alice, bandIds[0], false, initDate);
        });

        test("Should unstake and update data", () => {
            assert.fieldEquals("StakingContract", ids[0], "stakers", "[]");
            assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", BIGINT_ZERO.toString());
            assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandIds[1].toString());

            assert.notInStore("Staker", alice.toHex());
            assert.notInStore("Band", bandIds[0].toString());
        });
    });
});