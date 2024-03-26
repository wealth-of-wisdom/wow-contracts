import { BigInt } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, clearStore, assert } from "matchstick-as/assembly/index";
import { initialize, setPool, setBandLevel, setSharesInMonth, stakeStandardFlexi, upgradeBand } from "./helpers/helper";
import {
    alice,
    totalPools,
    totalBandLevels,
    initDate,
    poolDistributionPercentages,
    bandLevelPrices,
    bandLevelAccessiblePools,
    bandLevels,
    ids,
    bandIds,
    sharesInMonths,
    zeroStr,
} from "../utils/constants";

const starterLevel = 1;
const firstUpgradeLevel = 2;
const secondUpgradeLevel = 4;

describe("handleBandUpgraded() tests", () => {
    //NOTE: share functionality for upgrade bands - incomplete
    describe("Create StakingContract, stake and upgrade band", () => {
        beforeEach(() => {
            clearStore();
            initialize();

            for (let i = 0; i < totalPools.toI32(); i++) {
                const poolId: BigInt = BigInt.fromI32(i + 1);
                setPool(poolId, poolDistributionPercentages[i]);
            }

            for (let i = 0; i < totalBandLevels.toI32(); i++) {
                const bandLevel: BigInt = BigInt.fromI32(i + 1);
                setBandLevel(bandLevel, bandLevelPrices[i], bandLevelAccessiblePools[i]);
            }

            setSharesInMonth(sharesInMonths);
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
        });

        test("Should allow another upgrade and change band level", () => {
            upgradeBand(
                alice,
                BigInt.fromString(ids[0]),
                BigInt.fromI32(firstUpgradeLevel),
                BigInt.fromI32(secondUpgradeLevel),
                initDate,
            );

            //Assert changed field
            assert.fieldEquals("Band", ids[0], "bandLevel", secondUpgradeLevel.toString());
            assert.fieldEquals(
                "StakingContract",
                ids[0],
                "totalStakedAmount",
                bandLevelPrices[secondUpgradeLevel - 1].toString(),
            );
            assert.fieldEquals(
                "Staker",
                alice.toHex(),
                "stakedAmount",
                bandLevelPrices[secondUpgradeLevel - 1].toString(),
            );
        });
    });
});
