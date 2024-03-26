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

const starterLevel = 4;
const upgradeLevel = 6;

describe("handleBandUpgraded() tests", () => {
    beforeEach(() => {
        clearStore();
    });

    //NOTE: share functionality for upgrade bands - incomplete
    describe("Create StakingContract, stake and upgrade band", () => {
        beforeEach(() => {
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
        });

        test("Should upgrade band and change band level", () => {
            upgradeBand(
                alice,
                BigInt.fromString(ids[0]),
                BigInt.fromI32(starterLevel),
                BigInt.fromI32(upgradeLevel),
                initDate,
            );
            //Assert unchanged field
            assert.fieldEquals("Band", ids[0], "owner", alice.toHex());
            assert.fieldEquals("Band", ids[0], "stakingStartDate", initDate.toString());
            assert.fieldEquals("Band", ids[0], "fixedMonths", zeroStr);
            assert.fieldEquals("Band", ids[0], "areTokensVested", false.toString());
            assert.fieldEquals("Band", ids[0], "sharesAmount", zeroStr);

            //Assert changed field
            assert.fieldEquals("Band", ids[0], "bandLevel", upgradeLevel.toString());
        });
    });
});
