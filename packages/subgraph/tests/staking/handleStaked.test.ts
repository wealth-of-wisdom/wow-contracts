import { Address, BigInt, log } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, beforeAll, afterEach, clearStore, assert } from "matchstick-as/assembly/index";
import { initializeAndSetUp, stakeStandardFixed } from "./helpers/helper";
import { ids, bandIds, alice, bob, charlie, totalPools } from "../utils/data/constants";
import { initDate, monthsAfterInit } from "../utils/data/dates";
import { sharesInMonths, bandLevels, months, bandLevelPrices } from "../utils/data/data";
import { convertBigIntArrayToString, createEmptyArray } from "../utils/arrays";
import { stringifyStakingType } from "../../src/utils/utils";
import { StakingType } from "../../src/utils/constants";

let bandsCount = 0;
let stakersCount = 0;
let bandLevel = 1;
let shares: BigInt;
let stakers: Address[];
let fixedMonths: BigInt = BigInt.fromI32(20);
let fixStakerShares: BigInt[];
let isolatedFixedSharesPerPool: BigInt[];

describe("handleStaked()", () => {
    beforeEach(() => {
        clearStore();
        initializeAndSetUp();
    });

    // describe("1 Staker", () => {
    //     // afterEach(() => {
    //     //     // ASSERT band
    //     //     for (let i = 0; i < bandsCount; i++) {
    //     //         assert.fieldEquals("Band", ids[i], "sharesAmount", shares.toString());
    //     //     }

    //     //     // ASSERT staker
    //     //     assert.fieldEquals(
    //     //         "Staker",
    //     //         alice.toHex(),
    //     //         "fixedSharesPerPool",
    //     //         convertBigIntArrayToString(fixStakerShares),
    //     //     );
    //     //     assert.fieldEquals(
    //     //         "Staker",
    //     //         alice.toHex(),
    //     //         "isolatedFixedSharesPerPool",
    //     //         convertBigIntArrayToString(isolatedFixedSharesPerPool),
    //     //     );

    //     //     // ASSERT pools
    //     //     for (let i = 1; i <= totalPools.toI32(); i++) {
    //     //         assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", fixStakerShares[i - 1].toString());
    //     //         assert.fieldEquals(
    //     //             "Pool",
    //     //             ids[i],
    //     //             "isolatedFixedSharesAmount",
    //     //             isolatedFixedSharesPerPool[i - 1].toString(),
    //     //         );
    //     //     }
    //     // });

    //     describe("Single band level", () => {
    //         describe("Band level 1", () => {
    //             beforeAll(() => {
    //                 bandLevel = 1;
    //             });

    //             // afterEach(() => {
    //             //     shares = sharesInMonths[fixedMonths.toI32() - 1];
    //             //     const totalShares = shares.times(BigInt.fromI32(bandsCount));

    //             //     fixStakerShares = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

    //             //     isolatedFixedSharesPerPool = createEmptyArray(totalPools);
    //             //     isolatedFixedSharesPerPool[bandLevel - 1] = totalShares;

    //             //     // Staker stakes in the accessible pool of the band level
    //             //     for (let i = 0; i < bandsCount; i++) {
    //             //         stakeStandardFixed(alice, bandLevels[bandLevel - 1], bandIds[i], fixedMonths, initDate);
    //             //     }

    //             //     // This helps to debug the tests
    //             //     log.debug("Band Count: {}, Band Level: {}, Total Shares: {}", [
    //             //         bandsCount.toString(),
    //             //         bandLevel.toString(),
    //             //         totalShares.toString(),
    //             //     ]);
    //             // });

    //             describe("1 FIXED band", () => {
    //                 beforeAll(() => {
    //                     bandsCount = 1;
    //                 });

    //                 test("Fixed months - 1", () => {
    //                     fixedMonths = months[1];
    //                 });

    //                 test("Fixed months - 11", () => {
    //                     fixedMonths = months[11];
    //                 });

    //                 test("Fixed months - 24", () => {
    //                     fixedMonths = months[24];
    //                 });
    //             });

    //             describe("2 FIXED bands", () => {
    //                 beforeAll(() => {
    //                     bandsCount = 2;
    //                 });

    //                 test("Fixed months - 1", () => {
    //                     fixedMonths = months[1];
    //                 });

    //                 test("Fixed months - 11", () => {
    //                     fixedMonths = months[11];
    //                 });

    //                 test("Fixed months - 24", () => {
    //                     fixedMonths = months[24];
    //                 });
    //             });
    //         });
    //     });
    // });

    // describe("3 Stakers", () => {
    //     beforeAll(() => {
    //         stakers = [alice, bob, charlie];
    //         stakersCount = stakers.length;
    //     });

    //     afterEach(() => {
    //         // ASSERT band
    //         for (let i = 0; i < bandsCount * stakersCount; i++) {
    //             assert.fieldEquals("Band", ids[i], "sharesAmount", shares.toString());
    //         }

    //         // ASSERT staker
    //         for (let i = 0; i < stakersCount; i++) {
    //             const stakerId = stakers[i].toHex();
    //             assert.fieldEquals(
    //                 "Staker",
    //                 stakerId,
    //                 "fixedSharesPerPool",
    //                 convertBigIntArrayToString(fixStakerShares),
    //             );
    //             assert.fieldEquals(
    //                 "Staker",
    //                 stakerId,
    //                 "isolatedFixedSharesPerPool",
    //                 convertBigIntArrayToString(isolatedFixedSharesPerPool),
    //             );
    //         }

    //         // ASSERT pools
    //         for (let i = 1; i <= totalPools.toI32(); i++) {
    //             const totalFixedShares = fixStakerShares[i - 1].times(BigInt.fromI32(stakersCount));
    //             const totalIsolatedFixedShares = isolatedFixedSharesPerPool[i - 1].times(BigInt.fromI32(stakersCount));

    //             assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", totalFixedShares.toString());
    //             assert.fieldEquals("Pool", ids[i], "isolatedFixedSharesAmount", totalIsolatedFixedShares.toString());
    //         }
    //     });

    //     describe("1 Band level", () => {
    //         beforeAll(() => {
    //             bandLevel = 1;
    //         });

    //         afterEach(() => {
    //             shares = sharesInMonths[fixedMonths.toI32() - 1];
    //             const totalShares = shares.times(BigInt.fromI32(bandsCount));

    //             fixStakerShares = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

    //             isolatedFixedSharesPerPool = createEmptyArray(totalPools);
    //             isolatedFixedSharesPerPool[bandLevel - 1] = totalShares;

    //             // Staker stakes in the accessible pool of the band level
    //             for (let i = 0; i < bandsCount; i++) {
    //                 for (let j = 0; j < stakersCount; j++) {
    //                     stakeStandardFixed(
    //                         stakers[j],
    //                         bandLevels[bandLevel - 1],
    //                         bandIds[i * stakersCount + j],
    //                         fixedMonths,
    //                         initDate,
    //                     );
    //                 }
    //             }
    //             log.debug("Band Count: {}, Band Level: {}, Total Shares: {}", [
    //                 bandsCount.toString(),
    //                 bandLevel.toString(),
    //                 totalShares.toString(),
    //             ]);
    //         });

    //         describe("1 FIX band", () => {
    //             beforeAll(() => {
    //                 bandsCount = 1;
    //             });

    //             test("Fixed months - 1", () => {
    //                 fixedMonths = BigInt.fromI32(1);
    //             });
    //             test("Fixed months - 11", () => {
    //                 fixedMonths = BigInt.fromI32(11);
    //             });
    //             test("Fixed months - 24", () => {
    //                 fixedMonths = BigInt.fromI32(24);
    //             });
    //         });

    //         describe("2 FIX bands", () => {
    //             beforeAll(() => {
    //                 bandsCount = 2;
    //             });

    //             test("Fixed months - 1", () => {
    //                 fixedMonths = BigInt.fromI32(1);
    //             });
    //             test("Fixed months - 11", () => {
    //                 fixedMonths = BigInt.fromI32(11);
    //             });
    //             test("Fixed months - 24", () => {
    //                 fixedMonths = BigInt.fromI32(24);
    //             });
    //         });

    //         describe("3 FIX bands", () => {
    //             beforeAll(() => {
    //                 bandsCount = 3;
    //             });

    //             test("Fixed months - 1", () => {
    //                 fixedMonths = BigInt.fromI32(1);
    //             });
    //             test("Fixed months - 11", () => {
    //                 fixedMonths = BigInt.fromI32(11);
    //             });
    //             test("Fixed months - 24", () => {
    //                 fixedMonths = BigInt.fromI32(24);
    //             });
    //         });
    //     });
    // });

    describe("1 Staker", () => {
        describe("Single band level", () => {
            describe("Band level 1", () => {
                describe("1 FIXED band", () => {
                    describe("Fixed months - 1", () => {
                        beforeEach(() => {
                            stakeStandardFixed(alice, bandLevels[0], bandIds[0], months[1], monthsAfterInit[1]);
                        });

                        test("Should create new band", () => {
                            assert.fieldEquals("Band", ids[0], "id", ids[0]);
                            assert.entityCount("Band", 1);
                        });

                        test("Should set band values correctly", () => {
                            assert.fieldEquals("Band", ids[0], "owner", alice.toHex());
                            assert.fieldEquals("Band", ids[0], "stakingStartDate", monthsAfterInit[1].toString());
                            assert.fieldEquals("Band", ids[0], "bandLevel", bandLevels[0].toString());
                            assert.fieldEquals("Band", ids[0], "stakingType", stringifyStakingType(StakingType.FIX));
                            assert.fieldEquals("Band", ids[0], "fixedMonths", months[1].toString());
                            assert.fieldEquals("Band", ids[0], "areTokensVested", "false");
                        });

                        test("Should add staker to all stakers", () => {
                            const stakers = `[${alice.toHex()}]`;
                            assert.fieldEquals("StakingContract", ids[0], "stakers", stakers);
                        });

                        test("Should updated staking contract details", () => {
                            assert.fieldEquals("StakingContract", ids[0], "nextBandId", ids[1]);
                            assert.fieldEquals(
                                "StakingContract",
                                ids[0],
                                "totalStakedAmount",
                                bandLevelPrices[0].toString(),
                            );
                        });

                        test("Should add band to staker bands array", () => {
                            const bands = `[${ids[0]}]`;
                            assert.fieldEquals("Staker", alice.toHex(), "fixedBands", bands);
                            assert.fieldEquals("Staker", alice.toHex(), "flexiBands", "[]");
                        });

                        test("Should update staker details", () => {
                            assert.fieldEquals("Staker", alice.toHex(), "bandsCount", "1");
                            assert.fieldEquals("Staker", alice.toHex(), "stakedAmount", bandLevelPrices[0].toString());
                        });

                        // @todo calculate shares
                    });

                    describe("Fixed months - 11", () => {
                        fixedMonths = months[11];
                    });

                    describe("Fixed months - 24", () => {
                        fixedMonths = months[24];
                    });
                });

                describe("2 FIXED bands", () => {
                    test("Fixed months - 1", () => {
                        fixedMonths = months[1];
                    });

                    test("Fixed months - 11", () => {
                        fixedMonths = months[11];
                    });

                    test("Fixed months - 24", () => {
                        fixedMonths = months[24];
                    });
                });
            });
        });
    });
});
