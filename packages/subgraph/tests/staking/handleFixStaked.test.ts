import { Address, BigInt, log } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, beforeAll, afterEach, clearStore, assert } from "matchstick-as/assembly/index";
import { initializeAndSetUp, stakeStandardFixed } from "./helpers/helper";
import {
    ids,
    alice,
    bob,
    charlie,
    bandLevels,
    initDate,
    bandIds,
    totalPools,
    sharesInMonths,
} from "../utils/constants";
import { convertBigIntArrayToString, createEmptyArray } from "../utils/arrays";

let bandsCount = 0;
let stakersCount = 0;
let bandLevel = 1;
let shares: BigInt;
let stakers: Address[];
let fixedMonths: BigInt = BigInt.fromI32(20);
let fixStakerShares: BigInt[];
let isolatedFixedSharesPerPool: BigInt[];

describe("handleStaked() FIX tests", () => {
    beforeEach(() => {
        clearStore();
        initializeAndSetUp();
    });

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
                "fixedSharesPerPool",
                convertBigIntArrayToString(fixStakerShares),
            );
            assert.fieldEquals(
                "Staker",
                alice.toHex(),
                "isolatedFixedSharesPerPool",
                convertBigIntArrayToString(isolatedFixedSharesPerPool),
            );

            // ASSERT pools
            for (let i = 1; i <= totalPools.toI32(); i++) {
                assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", fixStakerShares[i - 1].toString());
                assert.fieldEquals(
                    "Pool",
                    ids[i],
                    "isolatedFixedSharesAmount",
                    isolatedFixedSharesPerPool[i - 1].toString(),
                );
            }
        });

        describe("1 Band level", () => {
            beforeAll(() => {
                bandLevel = 1;
            });
            afterEach(() => {
                shares = sharesInMonths[fixedMonths.toI32() - 1];
                const totalShares = shares.times(BigInt.fromI32(bandsCount));

                fixStakerShares = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

                isolatedFixedSharesPerPool = createEmptyArray(totalPools);
                isolatedFixedSharesPerPool[bandLevel - 1] = totalShares;

                // Staker stakes in the accessible pool of the band level
                for (let i = 0; i < bandsCount; i++) {
                    stakeStandardFixed(alice, bandLevels[bandLevel - 1], bandIds[i], fixedMonths, initDate);
                }
                log.debug("Band Count: {}, Band Level: {}, Total Shares: {}", [
                    bandsCount.toString(),
                    bandLevel.toString(),
                    totalShares.toString(),
                ]);
            });

            describe("1 FIX band", () => {
                beforeAll(() => {
                    bandsCount = 1;
                });

                test("Fixed months - 1", () => {
                    fixedMonths = BigInt.fromI32(1);
                });
                test("Fixed months - 11", () => {
                    fixedMonths = BigInt.fromI32(11);
                });
                test("Fixed months - 24", () => {
                    fixedMonths = BigInt.fromI32(24);
                });
            });

            describe("2 FIX bands", () => {
                beforeAll(() => {
                    bandsCount = 2;
                });

                test("Fixed months - 1", () => {
                    fixedMonths = BigInt.fromI32(1);
                });
                test("Fixed months - 11", () => {
                    fixedMonths = BigInt.fromI32(11);
                });
                test("Fixed months - 24", () => {
                    fixedMonths = BigInt.fromI32(24);
                });
            });

            describe("3 FIX bands", () => {
                beforeAll(() => {
                    bandsCount = 3;
                });

                test("Fixed months - 1", () => {
                    fixedMonths = BigInt.fromI32(1);
                });
                test("Fixed months - 11", () => {
                    fixedMonths = BigInt.fromI32(11);
                });
                test("Fixed months - 24", () => {
                    fixedMonths = BigInt.fromI32(24);
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
            // ASSERT band
            for (let i = 0; i < bandsCount * stakersCount; i++) {
                assert.fieldEquals("Band", ids[i], "sharesAmount", shares.toString());
            }

            // ASSERT staker
            for (let i = 0; i < stakersCount; i++) {
                const stakerId = stakers[i].toHex();
                assert.fieldEquals(
                    "Staker",
                    stakerId,
                    "fixedSharesPerPool",
                    convertBigIntArrayToString(fixStakerShares),
                );
                assert.fieldEquals(
                    "Staker",
                    stakerId,
                    "isolatedFixedSharesPerPool",
                    convertBigIntArrayToString(isolatedFixedSharesPerPool),
                );
            }

            // ASSERT pools
            for (let i = 1; i <= totalPools.toI32(); i++) {
                const totalFixedShares = fixStakerShares[i - 1].times(BigInt.fromI32(stakersCount));
                const totalIsolatedFixedShares = isolatedFixedSharesPerPool[i - 1].times(BigInt.fromI32(stakersCount));

                assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", totalFixedShares.toString());
                assert.fieldEquals("Pool", ids[i], "isolatedFixedSharesAmount", totalIsolatedFixedShares.toString());
            }
        });

        describe("1 Band level", () => {
            beforeAll(() => {
                bandLevel = 1;
            });
            afterEach(() => {
                shares = sharesInMonths[fixedMonths.toI32() - 1];
                const totalShares = shares.times(BigInt.fromI32(bandsCount));

                fixStakerShares = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

                isolatedFixedSharesPerPool = createEmptyArray(totalPools);
                isolatedFixedSharesPerPool[bandLevel - 1] = totalShares;

                // Staker stakes in the accessible pool of the band level
                for (let i = 0; i < bandsCount; i++) {
                    for (let j = 0; j < stakersCount; j++) {
                        stakeStandardFixed(
                            stakers[j],
                            bandLevels[bandLevel - 1],
                            bandIds[i * stakersCount + j],
                            fixedMonths,
                            initDate,
                        );
                    }
                }
                log.debug("Band Count: {}, Band Level: {}, Total Shares: {}", [
                    bandsCount.toString(),
                    bandLevel.toString(),
                    totalShares.toString(),
                ]);
            });

            describe("1 FIX band", () => {
                beforeAll(() => {
                    bandsCount = 1;
                });

                test("Fixed months - 1", () => {
                    fixedMonths = BigInt.fromI32(1);
                });
                test("Fixed months - 11", () => {
                    fixedMonths = BigInt.fromI32(11);
                });
                test("Fixed months - 24", () => {
                    fixedMonths = BigInt.fromI32(24);
                });
            });

            describe("2 FIX bands", () => {
                beforeAll(() => {
                    bandsCount = 2;
                });

                test("Fixed months - 1", () => {
                    fixedMonths = BigInt.fromI32(1);
                });
                test("Fixed months - 11", () => {
                    fixedMonths = BigInt.fromI32(11);
                });
                test("Fixed months - 24", () => {
                    fixedMonths = BigInt.fromI32(24);
                });
            });

            describe("3 FIX bands", () => {
                beforeAll(() => {
                    bandsCount = 3;
                });

                test("Fixed months - 1", () => {
                    fixedMonths = BigInt.fromI32(1);
                });
                test("Fixed months - 11", () => {
                    fixedMonths = BigInt.fromI32(11);
                });
                test("Fixed months - 24", () => {
                    fixedMonths = BigInt.fromI32(24);
                });
            });
        });
    });
});
