import { BigInt } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, clearStore, assert } from "matchstick-as/assembly/index";
import {
    initialize,
    setPool,
    setBandLevel,
    setSharesInMonth,
    stakeStandardFlexi,
    downgradeBand,
} from "./helpers/helper";
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
} from "../utils/constants";

const starterLevel = 5;
const firstDowngradeLevel = 3;
const secondDowngradeLevel = 1;

describe("handleBandDowngraded() tests", () => {
    //NOTE: share functionality for downgrade bands - incomplete
    describe("Create StakingContract, stake and downgrade band", () => {
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
            downgradeBand(
                alice,
                BigInt.fromString(ids[0]),
                BigInt.fromI32(starterLevel),
                BigInt.fromI32(firstDowngradeLevel),
                initDate,
            );
        });

        test("Should downgrade band and change band level", () => {
            //Assert changed field
            assert.fieldEquals("Band", ids[0], "bandLevel", firstDowngradeLevel.toString());
            assert.fieldEquals(
                "StakingContract",
                ids[0],
                "totalStakedAmount",
                bandLevelPrices[firstDowngradeLevel - 1].toString(),
            );
            assert.fieldEquals(
                "Staker",
                alice.toHex(),
                "stakedAmount",
                bandLevelPrices[firstDowngradeLevel - 1].toString(),
            );
        });

        test("Should allow another downgrade and change band level", () => {
            downgradeBand(
                alice,
                BigInt.fromString(ids[0]),
                BigInt.fromI32(firstDowngradeLevel),
                BigInt.fromI32(secondDowngradeLevel),
                initDate,
            );

            //Assert changed field
            assert.fieldEquals("Band", ids[0], "bandLevel", secondDowngradeLevel.toString());
            assert.fieldEquals(
                "StakingContract",
                ids[0],
                "totalStakedAmount",
                bandLevelPrices[secondDowngradeLevel - 1].toString(),
            );
            assert.fieldEquals(
                "Staker",
                alice.toHex(),
                "stakedAmount",
                bandLevelPrices[secondDowngradeLevel - 1].toString(),
            );
        });
    });
});
