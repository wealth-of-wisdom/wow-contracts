import { BigInt, log } from "@graphprotocol/graph-ts";
import {
    describe,
    test,
    beforeAll,
    beforeEach,
    afterAll,
    afterEach,
    clearStore,
    assert,
} from "matchstick-as/assembly/index";
import { updateFlexiSharesDuringSync } from "../../src/utils/staking/sharesSync";
import {
    initialize,
    setPool,
    setBandLevel,
    setSharesInMonth,
    stakeStandardFixed,
    stakeStandardFlexi,
    stakeVestedFixed,
    stakeVestedFlexi,
    createDistribution,
    distributeRewards,
    initializeAndSetUp,
} from "./helpers/helper";
import {
    stakingAddress,
    usdtToken,
    usdcToken,
    wowToken,
    alice,
    bob,
    charlie,
    totalPools,
    totalBandLevels,
    usd100k,
    initDate,
    zeroStr,
    poolDistributionPercentages,
    bandLevelPrices,
    bandLevelAccessiblePools,
    bandLevels,
    ids,
    bandIds,
    months,
    secondsInMonths,
    sharesInMonths,
} from "../utils/constants";
import { getOrInitStakingContract } from "../../src/helpers/staking.helpers";
import { BIGINT_ZERO } from "../../src/utils/constants";
import { convertBigIntArrayToString, createEmptyArray } from "../utils/arrays";

let bandsCount = 0;
let bandLevel = 0;
let syncMonth = 0;
let shares: BigInt = BIGINT_ZERO;
let testBandsCount = [1, 2, 3];
let bandsCountIndex = 0;
let testBandLevels = [1, 5, 9];
let bandLevelIndex = 0;
let testSyncMonths = [0, 12, 25];
let syncMonthIndex = 0;

describe("updateFlexiSharesDuringSync() tests", () => {
    beforeEach(() => {
        clearStore();

        initializeAndSetUp();
    });

    describe("1 Staker", () => {
        describe("1 Band level", () => {
            describe("Standard staking", () => {
                // This is the full test template
                // test() functions are only used to set different values for the variables
                afterEach(() => {
                    // ARRANGE
                    if (syncMonth == 0) {
                        shares = BIGINT_ZERO;
                    } else if (syncMonth <= 24) {
                        shares = sharesInMonths[syncMonth - 1];
                    } else {
                        shares = sharesInMonths[sharesInMonths.length - 1];
                    }

                    const totalShares = shares.times(BigInt.fromI32(bandsCount));

                    // Staker should have the same amount of shares in all accessible pools
                    // Example: band level -> 3, shares per pool -> [100, 100, 100, 0, 0, 0, 0, 0, 0]
                    const flexiStakerShares: BigInt[] = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

                    // Only the highest accessible pool should have shares
                    // Example: band level -> 3, shares per pool -> [0, 0, 100, 0, 0, 0, 0, 0, 0]
                    const isolatedFlexiStakerShares: BigInt[] = createEmptyArray(totalPools);
                    isolatedFlexiStakerShares[bandLevel - 1] = totalShares;

                    // Staker stakes in the accessible pool of the band level
                    for (let i = 0; i < bandsCount; i++) {
                        stakeStandardFlexi(alice, bandLevels[bandLevel - 1], bandIds[i], initDate);
                    }

                    // ACT
                    const stakingContract = getOrInitStakingContract();

                    // Try to sync and update the shares
                    updateFlexiSharesDuringSync(stakingContract, initDate.plus(secondsInMonths[syncMonth]));

                    // ASSERT band
                    for (let i = 0; i < bandsCount; i++) {
                        assert.fieldEquals("Band", ids[i], "sharesAmount", shares.toString());
                    }

                    // ASSERT staker
                    assert.fieldEquals(
                        "Staker",
                        alice.toHex(),
                        "flexiSharesPerPool",
                        convertBigIntArrayToString(flexiStakerShares),
                    );
                    assert.fieldEquals(
                        "Staker",
                        alice.toHex(),
                        "isolatedFlexiSharesPerPool",
                        convertBigIntArrayToString(isolatedFlexiStakerShares),
                    );

                    // ASSERT pools
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        let flexiPoolShares = i <= bandLevel ? totalShares.toString() : zeroStr;
                        assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", flexiPoolShares);

                        let isolatedFlexiPoolShares = i == bandLevel ? totalShares.toString() : zeroStr;
                        assert.fieldEquals("Pool", ids[i], "isolatedFlexiSharesAmount", isolatedFlexiPoolShares);
                    }
                });

                for (bandsCountIndex = 0; bandsCountIndex < testBandsCount.length; bandsCountIndex++) {
                    describe(`${testBandsCount[bandsCountIndex]} FLEXI bands`, () => {
                        beforeAll(() => {
                            bandsCount = testBandsCount[bandsCountIndex];
                        });

                        for (bandLevelIndex = 0; bandLevelIndex < testBandLevels.length; bandLevelIndex++) {
                            describe(`Band level ${testBandLevels[bandLevelIndex]}`, () => {
                                beforeAll(() => {
                                    bandLevel = testBandLevels[bandLevelIndex];
                                });

                                for (syncMonthIndex = 0; syncMonthIndex < testSyncMonths.length; syncMonthIndex++) {
                                    test(`Synced after ${testSyncMonths[syncMonthIndex]} months`, () => {
                                        syncMonth = testSyncMonths[syncMonthIndex];
                                    });
                                }
                            });
                        }
                    });
                }
            });
        });
    });
});
