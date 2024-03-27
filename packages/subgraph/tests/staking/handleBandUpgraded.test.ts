import { BigInt } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, clearStore, assert } from "matchstick-as/assembly/index";
import { initialize, initializeAndSetUp, stakeStandardFlexi, upgradeBand } from "./helpers/helper";
import { alice, initDate, bandLevelPrices, bandLevels, ids, bandIds, oneInt } from "../utils/constants";

const starterLevel = 1;
const firstUpgradeLevel = 2;

describe("Create StakingContract, stake and upgrade band two times", () => {
    //NOTE: share functionality for upgrade bands - incomplete
    describe("Create StakingContract, stake and upgrade band", () => {
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
        });

        test("Should upgrade band and change band level", () => {
            //Assert changed field
            assert.fieldEquals("Band", ids[0], "bandLevel", firstUpgradeLevel.toString());
            assert.fieldEquals(
                "StakingContract",
                ids[0],
                "totalStakedAmount",
                bandLevelPrices[firstUpgradeLevel - 1].toString(),
            );
            assert.fieldEquals(
                "Staker",
                alice.toHex(),
                "stakedAmount",
                bandLevelPrices[firstUpgradeLevel - 1].toString(),
            );

            assert.entityCount("Band", oneInt);
            assert.entityCount("Staker", oneInt);
        });
    });
});
