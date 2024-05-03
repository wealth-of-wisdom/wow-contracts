import { Address, BigInt, log } from "@graphprotocol/graph-ts";
import { describe, test, beforeAll, beforeEach, afterEach, clearStore, assert } from "matchstick-as/assembly/index";
import { validateTimeAndSyncFlexiShares } from "../../src/utils/staking/sharesSync";
import { stakeStandardFlexi, initializeAndSetUp, stakeVestedFlexi } from "./helpers/helper";
import { alice, bob, charlie, totalPools, ids, bandIds } from "../utils/data/constants";
import { bandLevels, sharesInMonths } from "../utils/data/data";
import { initDate, monthsAfterInit } from "../utils/data/dates";
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
let flexiPoolShares: BigInt[];
let isolatedFlexiPoolShares: BigInt[];
let syncDate: BigInt;
let duration: BigInt;
let allStakerFlexiShares: BigInt[][];
let allStakerIsolatedFlexiShares: BigInt[][];

describe("validateTimeAndSyncFlexiShares() tests", () => {
    beforeEach(() => {
        clearStore();
        initializeAndSetUp();
    });

    describe("Time tests", () => {
        describe("Less than 12 hours passed", () => {
            describe("After initialization", () => {
                beforeAll(() => {
                    syncDate = initDate;
                });

                describe("1 hour passed", () => {
                    beforeAll(() => {
                        duration = BigInt.fromI32(3600);
                    });

                    test("Should not sync shares", () => {
                        const synced = validateTimeAndSyncFlexiShares(syncDate.plus(duration));
                        assert.assertTrue(!synced);
                    });

                    test("Should not update last sync date", () => {
                        validateTimeAndSyncFlexiShares(syncDate.plus(duration));
                        assert.fieldEquals("StakingContract", ids[0], "lastSharesSyncDate", syncDate.toString());
                    });
                });

                describe("11 hours 59 minutes 59 seconds passed", () => {
                    beforeAll(() => {
                        duration = BigInt.fromI32(11 * 3600 + 59 * 60 + 59);
                    });

                    test("Should not sync shares", () => {
                        const synced = validateTimeAndSyncFlexiShares(syncDate.plus(duration));
                        assert.assertTrue(!synced);
                    });

                    test("Should not update last sync date", () => {
                        validateTimeAndSyncFlexiShares(syncDate.plus(duration));
                        assert.fieldEquals("StakingContract", ids[0], "lastSharesSyncDate", syncDate.toString());
                    });
                });
            });

            describe("After another sync", () => {
                beforeAll(() => {
                    const time = BigInt.fromI32(12 * 3600);
                    syncDate = initDate.plus(time);
                });

                beforeEach(() => {
                    validateTimeAndSyncFlexiShares(syncDate);
                });

                describe("1 hour passed", () => {
                    beforeAll(() => {
                        duration = BigInt.fromI32(3600);
                    });

                    test("Should not sync shares", () => {
                        const synced = validateTimeAndSyncFlexiShares(syncDate.plus(duration));
                        assert.assertTrue(!synced);
                    });

                    test("Should not update last sync date", () => {
                        validateTimeAndSyncFlexiShares(syncDate.plus(duration));
                        assert.fieldEquals("StakingContract", ids[0], "lastSharesSyncDate", syncDate.toString());
                    });
                });

                describe("11 hours 59 minutes 59 seconds passed", () => {
                    beforeAll(() => {
                        duration = BigInt.fromI32(11 * 3600 + 59 * 60 + 59);
                    });

                    test("Should not sync shares", () => {
                        const synced = validateTimeAndSyncFlexiShares(syncDate.plus(duration));
                        assert.assertTrue(!synced);
                    });

                    test("Should not update last sync date", () => {
                        validateTimeAndSyncFlexiShares(syncDate.plus(duration));
                        assert.fieldEquals("StakingContract", ids[0], "lastSharesSyncDate", syncDate.toString());
                    });
                });
            });
        });

        describe("More than 12 hours passed", () => {
            describe("After initialization", () => {
                beforeAll(() => {
                    syncDate = initDate;
                });

                describe("12 hours passed", () => {
                    beforeAll(() => {
                        duration = BigInt.fromI32(12 * 3600);
                    });

                    test("Should sync shares", () => {
                        const synced = validateTimeAndSyncFlexiShares(syncDate.plus(duration));
                        assert.assertTrue(synced);
                    });

                    test("Should update last sync date", () => {
                        validateTimeAndSyncFlexiShares(syncDate.plus(duration));
                        assert.fieldEquals(
                            "StakingContract",
                            ids[0],
                            "lastSharesSyncDate",
                            syncDate.plus(duration).toString(),
                        );
                    });
                });

                describe("24 hours passed", () => {
                    beforeAll(() => {
                        duration = BigInt.fromI32(24 * 3600);
                    });

                    test("Should sync shares", () => {
                        const synced = validateTimeAndSyncFlexiShares(syncDate.plus(duration));
                        assert.assertTrue(synced);
                    });

                    test("Should update last sync date", () => {
                        validateTimeAndSyncFlexiShares(syncDate.plus(duration));
                        assert.fieldEquals(
                            "StakingContract",
                            ids[0],
                            "lastSharesSyncDate",
                            syncDate.plus(duration).toString(),
                        );
                    });
                });
            });

            describe("After another sync", () => {
                beforeAll(() => {
                    const time = BigInt.fromI32(12 * 3600);
                    syncDate = initDate.plus(time);
                });

                beforeEach(() => {
                    validateTimeAndSyncFlexiShares(syncDate);
                });

                describe("12 hours passed", () => {
                    beforeAll(() => {
                        duration = BigInt.fromI32(12 * 3600);
                    });

                    test("Should sync shares", () => {
                        const synced = validateTimeAndSyncFlexiShares(syncDate.plus(duration));
                        assert.assertTrue(synced);
                    });

                    test("Should update last sync date", () => {
                        validateTimeAndSyncFlexiShares(syncDate.plus(duration));
                        assert.fieldEquals(
                            "StakingContract",
                            ids[0],
                            "lastSharesSyncDate",
                            syncDate.plus(duration).toString(),
                        );
                    });
                });

                describe("24 hours passed", () => {
                    beforeAll(() => {
                        duration = BigInt.fromI32(24 * 3600);
                    });

                    test("Should sync shares", () => {
                        const synced = validateTimeAndSyncFlexiShares(syncDate.plus(duration));
                        assert.assertTrue(synced);
                    });

                    test("Should update last sync date", () => {
                        validateTimeAndSyncFlexiShares(syncDate.plus(duration));
                        assert.fieldEquals(
                            "StakingContract",
                            ids[0],
                            "lastSharesSyncDate",
                            syncDate.plus(duration).toString(),
                        );
                    });
                });
            });
        });
    });

    describe("Shares tests", () => {
        describe("Simple cases", () => {
            describe("Standard staking", () => {
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
                            assert.fieldEquals(
                                "Pool",
                                ids[i],
                                "totalFlexiSharesAmount",
                                flexiStakerShares[i - 1].toString(),
                            );
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

                            // Try to sync and update the shares
                            validateTimeAndSyncFlexiShares(monthsAfterInit[syncMonth]);
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

                            // Try to sync and update the shares
                            validateTimeAndSyncFlexiShares(monthsAfterInit[syncMonth]);
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

                            // Try to sync and update the shares
                            validateTimeAndSyncFlexiShares(monthsAfterInit[syncMonth]);
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

                            // Try to sync and update the shares
                            validateTimeAndSyncFlexiShares(monthsAfterInit[syncMonth]);
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

            describe("Vested staking", () => {
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
                            assert.fieldEquals(
                                "Pool",
                                ids[i],
                                "totalFlexiSharesAmount",
                                flexiStakerShares[i - 1].toString(),
                            );
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
                                stakeVestedFlexi(alice, bandLevels[bandLevel - 1], bandIds[i], initDate);
                            }

                            // Try to sync and update the shares
                            validateTimeAndSyncFlexiShares(monthsAfterInit[syncMonth]);
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
                            stakeVestedFlexi(alice, BigInt.fromI32(1), bandIds[0], initDate);
                            stakeVestedFlexi(alice, BigInt.fromI32(5), bandIds[1], initDate);
                            stakeVestedFlexi(alice, BigInt.fromI32(9), bandIds[2], initDate);

                            // Try to sync and update the shares
                            validateTimeAndSyncFlexiShares(monthsAfterInit[syncMonth]);
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
                                    stakeVestedFlexi(
                                        stakers[j],
                                        bandLevels[bandLevel - 1],
                                        bandIds[i * stakersCount + j],
                                        initDate,
                                    );
                                }
                            }

                            // Try to sync and update the shares
                            validateTimeAndSyncFlexiShares(monthsAfterInit[syncMonth]);
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
                                stakeVestedFlexi(stakers[i], bandLevels[0], bandIds[i * 3], initDate);
                                stakeVestedFlexi(stakers[i], bandLevels[4], bandIds[i * 3 + 1], initDate);
                                stakeVestedFlexi(stakers[i], bandLevels[8], bandIds[i * 3 + 2], initDate);
                            }

                            // Try to sync and update the shares
                            validateTimeAndSyncFlexiShares(monthsAfterInit[syncMonth]);
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

        describe("Complex cases", () => {
            describe("3 stakers, 3 bands each, 9 band levels", () => {
                beforeAll(() => {
                    stakers = [alice, bob, charlie];
                    stakersCount = stakers.length;
                    bandsCount = 3;
                });

                beforeEach(() => {
                    let bandId = 0;
                    let dayDuration = 24 * 3600; // 1 day

                    for (let i = 0; i < stakersCount; i++) {
                        for (let j = 0; j < bandsCount; j++) {
                            stakeStandardFlexi(
                                stakers[i],
                                bandLevels[bandId],
                                bandIds[bandId],
                                initDate.plus(BigInt.fromI32(bandId * dayDuration)),
                            );
                            bandId++;
                        }
                    }
                });

                afterEach(() => {
                    if (syncMonth == 0) {
                        shares = BIGINT_ZERO;
                    } else if (syncMonth <= 24) {
                        shares = sharesInMonths[syncMonth - 1];
                    } else {
                        shares = sharesInMonths[sharesInMonths.length - 1];
                    }

                    const bandStakingDuration = BigInt.fromI32(9 * 24 * 3600);
                    validateTimeAndSyncFlexiShares(monthsAfterInit[syncMonth].plus(bandStakingDuration));

                    const sharesX2 = shares.times(BigInt.fromI32(2));
                    const sharesX3 = shares.times(BigInt.fromI32(3));
                    flexiPoolShares = createEmptyArray(totalPools);
                    isolatedFlexiPoolShares = createEmptyArray(totalPools);

                    const staker1FlexiShares = createEmptyArray(totalPools);
                    staker1FlexiShares[0] = sharesX3;
                    staker1FlexiShares[1] = sharesX2;
                    staker1FlexiShares[2] = shares;
                    const staker1IsolatedFlexiShares = createEmptyArray(totalPools);
                    staker1IsolatedFlexiShares[0] = shares;
                    staker1IsolatedFlexiShares[1] = shares;
                    staker1IsolatedFlexiShares[2] = shares;

                    const staker2FlexiShares = createEmptyArray(totalPools).fill(sharesX3, 0, 4);
                    staker2FlexiShares[4] = sharesX2;
                    staker2FlexiShares[5] = shares;
                    const staker2IsolatedFlexiShares = createEmptyArray(totalPools);
                    staker2IsolatedFlexiShares[3] = shares;
                    staker2IsolatedFlexiShares[4] = shares;
                    staker2IsolatedFlexiShares[5] = shares;

                    const staker3FlexiShares = createEmptyArray(totalPools).fill(sharesX3, 0, 7);
                    staker3FlexiShares[7] = sharesX2;
                    staker3FlexiShares[8] = shares;
                    const staker3IsolatedFlexiShares = createEmptyArray(totalPools);
                    staker3IsolatedFlexiShares[6] = shares;
                    staker3IsolatedFlexiShares[7] = shares;
                    staker3IsolatedFlexiShares[8] = shares;

                    allStakerFlexiShares = [staker1FlexiShares, staker2FlexiShares, staker3FlexiShares];
                    allStakerIsolatedFlexiShares = [
                        staker1IsolatedFlexiShares,
                        staker2IsolatedFlexiShares,
                        staker3IsolatedFlexiShares,
                    ];

                    for (let i = 0; i < totalPools.toI32(); i++) {
                        for (let j = 0; j < stakersCount; j++) {
                            flexiPoolShares[i] = flexiPoolShares[i].plus(allStakerFlexiShares[j][i]);
                            isolatedFlexiPoolShares[i] = shares;
                        }
                    }

                    log.debug("Should sync band shares", []);
                    for (let i = 0; i < bandsCount * stakersCount; i++) {
                        assert.fieldEquals("Band", ids[i], "sharesAmount", shares.toString());
                    }

                    log.debug("Should sync staker shares", []);
                    for (let i = 0; i < stakersCount; i++) {
                        const stakerId = stakers[i].toHex();

                        assert.fieldEquals(
                            "Staker",
                            stakerId,
                            "flexiSharesPerPool",
                            convertBigIntArrayToString(allStakerFlexiShares[i]),
                        );
                        assert.fieldEquals(
                            "Staker",
                            stakerId,
                            "isolatedFlexiSharesPerPool",
                            convertBigIntArrayToString(allStakerIsolatedFlexiShares[i]),
                        );
                    }

                    log.debug("Should sync pool shares", []);
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        const totalFlexiShares = flexiPoolShares[i - 1];
                        const totalIsolatedFlexiShares = isolatedFlexiPoolShares[i - 1];

                        assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", totalFlexiShares.toString());
                        assert.fieldEquals(
                            "Pool",
                            ids[i],
                            "isolatedFlexiSharesAmount",
                            totalIsolatedFlexiShares.toString(),
                        );
                    }
                });

                test("Sync after 0 months", () => {
                    syncMonth = 0;
                });

                test("Sync after 1 month", () => {
                    syncMonth = 1;
                });

                test("Sync after 6 months", () => {
                    syncMonth = 6;
                });

                test("Sync after 12 months", () => {
                    syncMonth = 12;
                });

                test("Sync after 24 months", () => {
                    syncMonth = 24;
                });

                test("Sync after 40 months", () => {
                    syncMonth = 40;
                });
            });
        });
    });
});
