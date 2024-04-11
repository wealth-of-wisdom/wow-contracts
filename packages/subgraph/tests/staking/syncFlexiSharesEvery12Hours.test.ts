import { Address, BigInt, log } from "@graphprotocol/graph-ts";
import { describe, test, beforeAll, beforeEach, afterEach, clearStore, assert } from "matchstick-as/assembly/index";
import { syncFlexiSharesEvery12Hours } from "../../src/utils/staking/sharesSync";
import { stakeStandardFlexi, initializeAndSetUp } from "./helpers/helper";
import { alice, bob, charlie, totalPools, ids, bandIds } from "../utils/data/constants";
import { bandLevels, months, secondsInMonths, sharesInMonths } from "../utils/data/data";
import { initDate, monthsAfterInit } from "../utils/data/dates";
import { getOrInitStakingContract } from "../../src/helpers/staking.helpers";
import { BIGINT_ZERO } from "../../src/utils/constants";
import { convertBigIntArrayToString, createEmptyArray } from "../utils/arrays";

let bandsCount = 0;
let stakersCount = 0;
let bandLevel = 0;
let syncMonth = 0;
let shares: BigInt;
let stakers: Address[];
let flexiStakerShares: BigInt[];
let isolatedFlexiStakerShares: BigInt[];
let nextSyncDate: BigInt;

describe("syncFlexiSharesEvery12Hours() tests", () => {
    beforeEach(() => {
        clearStore();
        initializeAndSetUp();
    });

    describe("Time tests", () => {
        describe("Less than 12 hours passed", () => {
            describe("After initialization", () => {
                describe("1 hour passed", () => {
                    test("Should not sync shares", () => {
                        const hour = BigInt.fromI32(3600);
                        const synced = syncFlexiSharesEvery12Hours(initDate.plus(hour));
                        assert.assertTrue(!synced);
                    });

                    test("Should not update last sync date", () => {
                        assert.fieldEquals("StakingContract", ids[0], "lastSharesSyncDate", initDate.toString());
                    });
                });

                describe("11 hours 59 minutes 59 seconds passed", () => {
                    test("Should not sync shares", () => {
                        const time = BigInt.fromI32(11 * 3600 + 59 * 60 + 59);
                        const synced = syncFlexiSharesEvery12Hours(initDate.plus(time));
                        assert.assertTrue(!synced);
                    });

                    test("Should not update last sync date", () => {
                        assert.fieldEquals("StakingContract", ids[0], "lastSharesSyncDate", initDate.toString());
                    });
                });
            });

            describe("After previous sync event", () => {
                beforeEach(() => {
                    const duration = BigInt.fromI32(12 * 3600);
                    nextSyncDate = initDate.plus(duration);
                    syncFlexiSharesEvery12Hours(nextSyncDate);
                });

                describe("1 hour passed", () => {
                    test("Should not sync shares", () => {
                        const hour = BigInt.fromI32(3600);
                        const synced = syncFlexiSharesEvery12Hours(nextSyncDate.plus(hour));
                        assert.assertTrue(!synced);
                    });

                    test("Should not update last sync date", () => {
                        assert.fieldEquals("StakingContract", ids[0], "lastSharesSyncDate", nextSyncDate.toString());
                    });
                });

                describe("11 hours 59 minutes 59 seconds passed", () => {
                    test("Should not sync shares", () => {
                        const time = BigInt.fromI32(11 * 3600 + 59 * 60 + 59);
                        const synced = syncFlexiSharesEvery12Hours(nextSyncDate.plus(time));
                        assert.assertTrue(!synced);
                    });

                    test("Should not update last sync date", () => {
                        assert.fieldEquals("StakingContract", ids[0], "lastSharesSyncDate", nextSyncDate.toString());
                    });
                });
            });
        });
    });

    describe("Shares tests", () => {
        describe("1 Staker", () => {
            afterEach(() => {
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
                    assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", flexiStakerShares[i - 1].toString());
                    assert.fieldEquals(
                        "Pool",
                        ids[i],
                        "isolatedFlexiSharesAmount",
                        isolatedFlexiStakerShares[i - 1].toString(),
                    );
                }
            });

            describe("1 Band level", () => {
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
                    flexiStakerShares = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

                    // Only the highest accessible pool should have shares
                    // Example: band level -> 3, shares per pool -> [0, 0, 100, 0, 0, 0, 0, 0, 0]
                    isolatedFlexiStakerShares = createEmptyArray(totalPools);
                    isolatedFlexiStakerShares[bandLevel - 1] = totalShares;

                    // Staker stakes in the accessible pool of the band level
                    for (let i = 0; i < bandsCount; i++) {
                        stakeStandardFlexi(alice, bandLevels[bandLevel - 1], bandIds[i], initDate);
                    }

                    // ACT
                    const stakingContract = getOrInitStakingContract();

                    // Try to sync and update the shares
                    syncFlexiSharesEvery12Hours(monthsAfterInit[syncMonth]);
                });

                describe("1 FLEXI band", () => {
                    beforeAll(() => {
                        bandsCount = 1;
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            bandLevel = 1;
                        });

                        test("Synced after 0 months", () => {
                            syncMonth = 0;
                        });

                        test("Synced after 12 month", () => {
                            syncMonth = 12;
                        });

                        test("Synced after 25 months", () => {
                            syncMonth = 25;
                        });
                    });

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            bandLevel = 5;
                        });

                        test("Synced after 0 months", () => {
                            syncMonth = 0;
                        });

                        test("Synced after 12 month", () => {
                            syncMonth = 12;
                        });

                        test("Synced after 25 months", () => {
                            syncMonth = 25;
                        });
                    });

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            bandLevel = 9;
                        });

                        test("Synced after 0 months", () => {
                            syncMonth = 0;
                        });

                        test("Synced after 12 month", () => {
                            syncMonth = 12;
                        });

                        test("Synced after 25 months", () => {
                            syncMonth = 25;
                        });
                    });
                });

                describe("2 FLEXI bands", () => {
                    beforeAll(() => {
                        bandsCount = 2;
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            bandLevel = 1;
                        });

                        test("Synced after 0 months", () => {
                            syncMonth = 0;
                        });

                        test("Synced after 12 month", () => {
                            syncMonth = 12;
                        });

                        test("Synced after 25 months", () => {
                            syncMonth = 25;
                        });
                    });

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            bandLevel = 5;
                        });

                        test("Synced after 0 months", () => {
                            syncMonth = 0;
                        });

                        test("Synced after 12 month", () => {
                            syncMonth = 12;
                        });

                        test("Synced after 25 months", () => {
                            syncMonth = 25;
                        });
                    });

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            bandLevel = 9;
                        });

                        test("Synced after 0 months", () => {
                            syncMonth = 0;
                        });

                        test("Synced after 12 month", () => {
                            syncMonth = 12;
                        });

                        test("Synced after 25 months", () => {
                            syncMonth = 25;
                        });
                    });
                });

                describe("3 FLEXI bands", () => {
                    beforeAll(() => {
                        bandsCount = 3;
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            bandLevel = 1;
                        });

                        test("Synced after 0 months", () => {
                            syncMonth = 0;
                        });

                        test("Synced after 12 month", () => {
                            syncMonth = 12;
                        });

                        test("Synced after 25 months", () => {
                            syncMonth = 25;
                        });
                    });

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            bandLevel = 5;
                        });

                        test("Synced after 0 months", () => {
                            syncMonth = 0;
                        });

                        test("Synced after 12 month", () => {
                            syncMonth = 12;
                        });

                        test("Synced after 25 months", () => {
                            syncMonth = 25;
                        });
                    });

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            bandLevel = 9;
                        });

                        test("Synced after 0 months", () => {
                            syncMonth = 0;
                        });

                        test("Synced after 12 month", () => {
                            syncMonth = 12;
                        });

                        test("Synced after 25 months", () => {
                            syncMonth = 25;
                        });
                    });
                });
            });

            describe("3 Band levels", () => {
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

                    const sharesX2 = shares.times(BigInt.fromI32(2));
                    const sharesX3 = shares.times(BigInt.fromI32(3));

                    // Staker should have the different amount of shares in accessible pools
                    // Example: shares per pool -> [300, 300, 300, 200, 200, 200, 100, 100, 100]
                    flexiStakerShares = createEmptyArray(totalPools)
                        .fill(sharesX3, 0, 1)
                        .fill(sharesX2, 1, 5)
                        .fill(shares, 5, 9);

                    // Only the highest accessible pool should have shares
                    // Example: band level -> 3, shares per pool -> [100, 0, 0, 100, 0, 0, 100, 0, 0]
                    isolatedFlexiStakerShares = createEmptyArray(totalPools);
                    isolatedFlexiStakerShares[0] = shares;
                    isolatedFlexiStakerShares[4] = shares;
                    isolatedFlexiStakerShares[8] = shares;

                    // Staker stakes in the accessible pool of the band level
                    stakeStandardFlexi(alice, BigInt.fromI32(1), bandIds[0], initDate);
                    stakeStandardFlexi(alice, BigInt.fromI32(5), bandIds[1], initDate);
                    stakeStandardFlexi(alice, BigInt.fromI32(9), bandIds[2], initDate);

                    // ACT
                    const stakingContract = getOrInitStakingContract();

                    // Try to sync and update the shares
                    syncFlexiSharesEvery12Hours(monthsAfterInit[syncMonth]);
                });

                describe(`3 FLEXI bands`, () => {
                    beforeAll(() => {
                        bandsCount = 3;
                    });

                    test("Synced after 0 months", () => {
                        syncMonth = 0;
                    });

                    test("Synced after 12 month", () => {
                        syncMonth = 12;
                    });

                    test("Synced after 25 months", () => {
                        syncMonth = 25;
                    });
                });
            });
        });

        describe("3 Stakers", () => {
            beforeAll(() => {
                stakers = [alice, bob, charlie];
                stakersCount = stakers.length;
            });

            afterEach(() => {
                // ASSERT bands
                for (let i = 0; i < bandsCount * stakersCount; i++) {
                    assert.fieldEquals("Band", ids[i], "sharesAmount", shares.toString());
                }

                // ASSERT stakers
                for (let i = 0; i < stakersCount; i++) {
                    const stakerId = stakers[i].toHex();

                    assert.fieldEquals(
                        "Staker",
                        stakerId,
                        "flexiSharesPerPool",
                        convertBigIntArrayToString(flexiStakerShares),
                    );
                    assert.fieldEquals(
                        "Staker",
                        stakerId,
                        "isolatedFlexiSharesPerPool",
                        convertBigIntArrayToString(isolatedFlexiStakerShares),
                    );
                }

                // ASSERT pools
                for (let i = 1; i <= totalPools.toI32(); i++) {
                    const totalFlexiShares = flexiStakerShares[i - 1].times(BigInt.fromI32(stakersCount));
                    const totalIsolatedFlexiShares = isolatedFlexiStakerShares[i - 1].times(
                        BigInt.fromI32(stakersCount),
                    );

                    assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", totalFlexiShares.toString());
                    assert.fieldEquals(
                        "Pool",
                        ids[i],
                        "isolatedFlexiSharesAmount",
                        totalIsolatedFlexiShares.toString(),
                    );
                }
            });

            describe("1 Band level", () => {
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
                    flexiStakerShares = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

                    // Only the highest accessible pool should have shares
                    // Example: band level -> 3, shares per pool -> [0, 0, 100, 0, 0, 0, 0, 0, 0]
                    isolatedFlexiStakerShares = createEmptyArray(totalPools);
                    isolatedFlexiStakerShares[bandLevel - 1] = totalShares;

                    // Staker stakes in the accessible pool of the band level
                    for (let i = 0; i < bandsCount; i++) {
                        for (let j = 0; j < stakersCount; j++) {
                            stakeStandardFlexi(
                                stakers[j],
                                bandLevels[bandLevel - 1],
                                bandIds[i * stakersCount + j],
                                initDate,
                            );
                        }
                    }

                    // ACT
                    const stakingContract = getOrInitStakingContract();

                    // Try to sync and update the shares
                    syncFlexiSharesEvery12Hours(monthsAfterInit[syncMonth]);
                });

                describe(`1 FLEXI band for each staker`, () => {
                    beforeAll(() => {
                        bandsCount = 1;
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            bandLevel = 1;
                        });

                        test("Synced after 0 months", () => {
                            syncMonth = 0;
                        });

                        test("Synced after 12 month", () => {
                            syncMonth = 12;
                        });

                        test("Synced after 25 months", () => {
                            syncMonth = 25;
                        });
                    });

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            bandLevel = 5;
                        });

                        test("Synced after 0 months", () => {
                            syncMonth = 0;
                        });

                        test("Synced after 12 month", () => {
                            syncMonth = 12;
                        });

                        test("Synced after 25 months", () => {
                            syncMonth = 25;
                        });
                    });

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            bandLevel = 9;
                        });

                        test("Synced after 0 months", () => {
                            syncMonth = 0;
                        });

                        test("Synced after 12 month", () => {
                            syncMonth = 12;
                        });

                        test("Synced after 25 months", () => {
                            syncMonth = 25;
                        });
                    });
                });

                describe(`2 FLEXI bands for each staker`, () => {
                    beforeAll(() => {
                        bandsCount = 2;
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            bandLevel = 1;
                        });

                        test("Synced after 0 months", () => {
                            syncMonth = 0;
                        });

                        test("Synced after 12 month", () => {
                            syncMonth = 12;
                        });

                        test("Synced after 25 months", () => {
                            syncMonth = 25;
                        });
                    });

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            bandLevel = 5;
                        });

                        test("Synced after 0 months", () => {
                            syncMonth = 0;
                        });

                        test("Synced after 12 month", () => {
                            syncMonth = 12;
                        });

                        test("Synced after 25 months", () => {
                            syncMonth = 25;
                        });
                    });

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            bandLevel = 9;
                        });

                        test("Synced after 0 months", () => {
                            syncMonth = 0;
                        });

                        test("Synced after 12 month", () => {
                            syncMonth = 12;
                        });

                        test("Synced after 25 months", () => {
                            syncMonth = 25;
                        });
                    });
                });

                describe(`3 FLEXI bands for each staker`, () => {
                    beforeAll(() => {
                        bandsCount = 3;
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            bandLevel = 1;
                        });

                        test("Synced after 0 months", () => {
                            syncMonth = 0;
                        });

                        test("Synced after 12 month", () => {
                            syncMonth = 12;
                        });

                        test("Synced after 25 months", () => {
                            syncMonth = 25;
                        });
                    });

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            bandLevel = 5;
                        });

                        test("Synced after 0 months", () => {
                            syncMonth = 0;
                        });

                        test("Synced after 12 month", () => {
                            syncMonth = 12;
                        });

                        test("Synced after 25 months", () => {
                            syncMonth = 25;
                        });
                    });

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            bandLevel = 9;
                        });

                        test("Synced after 0 months", () => {
                            syncMonth = 0;
                        });

                        test("Synced after 12 month", () => {
                            syncMonth = 12;
                        });

                        test("Synced after 25 months", () => {
                            syncMonth = 25;
                        });
                    });
                });
            });

            describe("3 Band levels", () => {
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

                    const sharesX2 = shares.times(BigInt.fromI32(2));
                    const sharesX3 = shares.times(BigInt.fromI32(3));

                    // Staker should have the different amount of shares in accessible pools
                    // Example: shares per pool -> [300, 300, 300, 200, 200, 200, 100, 100, 100]
                    flexiStakerShares = createEmptyArray(totalPools)
                        .fill(sharesX3, 0, 1)
                        .fill(sharesX2, 1, 5)
                        .fill(shares, 5, 9);

                    // Only the highest accessible pool should have shares
                    // Example: band level -> 3, shares per pool -> [100, 0, 0, 100, 0, 0, 100, 0, 0]
                    isolatedFlexiStakerShares = createEmptyArray(totalPools);
                    isolatedFlexiStakerShares[0] = shares;
                    isolatedFlexiStakerShares[4] = shares;
                    isolatedFlexiStakerShares[8] = shares;

                    // Staker stakes in the accessible pool of the band level
                    for (let i = 0; i < stakersCount; i++) {
                        stakeStandardFlexi(stakers[i], bandLevels[0], bandIds[i * 3], initDate);
                        stakeStandardFlexi(stakers[i], bandLevels[4], bandIds[i * 3 + 1], initDate);
                        stakeStandardFlexi(stakers[i], bandLevels[8], bandIds[i * 3 + 2], initDate);
                    }

                    // ACT
                    const stakingContract = getOrInitStakingContract();

                    // Try to sync and update the shares
                    syncFlexiSharesEvery12Hours(monthsAfterInit[syncMonth]);
                });

                describe(`3 FLEXI bands`, () => {
                    beforeAll(() => {
                        bandsCount = 3;
                    });

                    test("Synced after 0 months", () => {
                        syncMonth = 0;
                    });

                    test("Synced after 12 month", () => {
                        syncMonth = 12;
                    });

                    test("Synced after 25 months", () => {
                        syncMonth = 25;
                    });
                });
            });
        });
    });
});
