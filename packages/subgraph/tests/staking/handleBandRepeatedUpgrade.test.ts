import { BigInt } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, clearStore, assert } from "matchstick-as/assembly/index";
import { initialize, initializeAndSetUp, stakeStandardFlexi, upgradeBand } from "./helpers/helper";
import { alice, initDate, bandLevelPrices, bandLevels, ids, bandIds } from "../utils/constants";
import { BIGINT_ONE } from "../../src/utils/constants";

const starterLevel = 1;
const firstUpgradeLevel = 2;
const secondUpgradeLevel = 4;

describe("Upgrade band repeated", () => {
    beforeEach(() => {
        clearStore();
        initialize();

        initializeAndSetUp();
        stakeStandardFlexi(alice, bandLevels[starterLevel - 1], bandIds[0], initDate);
        upgradeBand(
            alice,
            BigInt.fromString(ids[0]),
            BigInt.fromI32(starterLevel),
            BigInt.fromI32(firstUpgradeLevel),
            initDate,
        );
        upgradeBand(
            alice,
            BigInt.fromString(ids[0]),
            BigInt.fromI32(firstUpgradeLevel),
            BigInt.fromI32(secondUpgradeLevel),
            initDate,
        );
    });
    test("Should allow another upgrade and change band level", () => {
        //Assert changed field
        assert.fieldEquals("Band", ids[0], "bandLevel", secondUpgradeLevel.toString());
        assert.fieldEquals(
            "StakingContract",
            ids[0],
            "totalStakedAmount",
            bandLevelPrices[secondUpgradeLevel - 1].toString(),
        );
        assert.fieldEquals("Staker", alice.toHex(), "stakedAmount", bandLevelPrices[secondUpgradeLevel - 1].toString());
        assert.entityCount("Band", 1);
        assert.entityCount("Staker", BIGINT_ONE.toI32());
    });
});
