import { Address, BigInt, log } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, beforeAll, afterEach, clearStore, assert } from "matchstick-as/assembly/index";
import { initializeAndSetUp, stakeStandardFixed, stakeVestedFixed } from "./helpers/helper";
import { ids, bandIds, alice, bob, charlie, totalPools } from "../utils/data/constants";
import { initDate, monthsAfterInit } from "../utils/data/dates";
import { sharesInMonths, bandLevels, months, bandLevelPrices } from "../utils/data/data";
import {
    convertAddressArrayToString,
    convertBigIntArrayToString,
    createArray,
    createArrayWithMultiplication,
    createEmptyArray,
} from "../utils/arrays";
import { stringifyStakingType } from "../../src/utils/utils";
import { BIGDEC_ZERO, BIGINT_TWO, BIGINT_ZERO, StakingType } from "../../src/utils/constants";

let bandsCount = 0;
let stakersCount = 0;
let shares: BigInt;
let stakers: Address[];
let fixedMonths: BigInt = BigInt.fromI32(20);
let fixedStakerSharesPerPool: BigInt[];
let isolatedFixedSharesPerPool: BigInt[];
let bandLevel = 0;
let totalStaked: BigInt;
let totalShares: BigInt;
let areTokensVested: boolean;

describe("handleStaked()", () => {
    beforeEach(() => {
        clearStore();
        initializeAndSetUp();
    });

    describe("Simple cases", () => {
        afterEach(() => {
            // This helps to debug the tests
            log.debug("Stakers: {}, Bands: {}, Band Level: {}, Total Staker Shares: {}", [
                stakersCount.toString(),
                bandsCount.toString(),
                bandLevel.toString(),
                totalShares.toString(),
            ]);
        });

        describe("1 Staker", () => {
            beforeAll(() => {
                stakersCount = 1;
            });

            afterEach(() => {
                /*//////////////////////////////////////////////////////////////////////////
                                          GET ASSERION DATA
            //////////////////////////////////////////////////////////////////////////*/

                shares = sharesInMonths[fixedMonths.toI32() - 1];
                totalShares = shares.times(BigInt.fromI32(bandsCount));

                fixedStakerSharesPerPool = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

                isolatedFixedSharesPerPool = createEmptyArray(totalPools);
                isolatedFixedSharesPerPool[bandLevel - 1] = totalShares;

                /*//////////////////////////////////////////////////////////////////////////
                                          ASSERT MAIN DATA
            //////////////////////////////////////////////////////////////////////////*/

                log.debug("Should create new bands", []);
                assert.entityCount("Band", bandsCount);
                for (let i = 0; i < bandsCount; i++) {
                    assert.fieldEquals("Band", ids[i], "id", ids[i]);
                }

                log.debug("Should set band values correctly", []);
                for (let i = 0; i < bandsCount; i++) {
                    assert.fieldEquals("Band", ids[i], "owner", alice.toHex());
                    assert.fieldEquals("Band", ids[i], "stakingStartDate", monthsAfterInit[1].toString());
                    assert.fieldEquals("Band", ids[i], "bandLevel", bandLevel.toString());
                    assert.fieldEquals("Band", ids[i], "stakingType", stringifyStakingType(StakingType.FIX));
                    assert.fieldEquals("Band", ids[i], "fixedMonths", fixedMonths.toString());
                    assert.fieldEquals("Band", ids[i], "areTokensVested", areTokensVested.toString());
                }

                log.debug("Should add staker to all stakers", []);
                const stakersArray = `[${alice.toHex()}]`;
                assert.fieldEquals("StakingContract", ids[0], "stakers", stakersArray);

                log.debug("Should updated staking contract details", []);
                assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
                assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());

                log.debug("Should add band to staker bands array", []);
                const bands = convertBigIntArrayToString(createArray(bandIds[0], BigInt.fromI32(bandsCount - 1)));
                assert.fieldEquals("Staker", alice.toHex(), "fixedBands", bands);
                assert.fieldEquals("Staker", alice.toHex(), "flexiBands", "[]");

                log.debug("Should update staker details", []);
                assert.fieldEquals("Staker", alice.toHex(), "bandsCount", bandsCount.toString());
                assert.fieldEquals("Staker", alice.toHex(), "stakedAmount", totalStaked.toString());

                /*//////////////////////////////////////////////////////////////////////////
                                            ASSERT SHARES
            //////////////////////////////////////////////////////////////////////////*/

                log.debug("Should set band shares", []);
                for (let i = 0; i < bandsCount; i++) {
                    assert.fieldEquals("Band", ids[i], "sharesAmount", shares.toString());
                }

                log.debug("Should set staker shares", []);
                assert.fieldEquals(
                    "Staker",
                    alice.toHex(),
                    "fixedSharesPerPool",
                    convertBigIntArrayToString(fixedStakerSharesPerPool),
                );
                assert.fieldEquals(
                    "Staker",
                    alice.toHex(),
                    "isolatedFixedSharesPerPool",
                    convertBigIntArrayToString(isolatedFixedSharesPerPool),
                );

                log.debug("Should set pool shares", []);
                for (let i = 1; i <= totalPools.toI32(); i++) {
                    assert.fieldEquals(
                        "Pool",
                        ids[i],
                        "totalFixedSharesAmount",
                        fixedStakerSharesPerPool[i - 1].toString(),
                    );
                    assert.fieldEquals(
                        "Pool",
                        ids[i],
                        "isolatedFixedSharesAmount",
                        isolatedFixedSharesPerPool[i - 1].toString(),
                    );
                }
            });

            describe("Single band level", () => {
                describe("Standard staking", () => {
                    beforeAll(() => {
                        areTokensVested = false;
                    });

                    afterEach(() => {
                        // Staker stakes in the accessible pool of the band level
                        totalStaked = BIGINT_ZERO;
                        for (let i = 0; i < bandsCount; i++) {
                            stakeStandardFixed(
                                alice,
                                bandLevels[bandLevel - 1],
                                bandIds[i],
                                fixedMonths,
                                monthsAfterInit[1],
                            );
                            totalStaked = totalStaked.plus(bandLevelPrices[bandLevel - 1]);
                        }
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            bandLevel = 1;
                        });

                        describe("1 FIXED band", () => {
                            beforeAll(() => {
                                bandsCount = 1;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = months[1];
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = months[12];
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = months[24];
                            });
                        });

                        describe("2 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 2;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = months[1];
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = months[12];
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = months[24];
                            });
                        });

                        describe("3 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 3;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = months[1];
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = months[12];
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = months[24];
                            });
                        });
                    });

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            bandLevel = 5;
                        });

                        describe("1 FIXED band", () => {
                            beforeAll(() => {
                                bandsCount = 1;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = months[1];
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = months[12];
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = months[24];
                            });
                        });

                        describe("2 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 2;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = months[1];
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = months[12];
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = months[24];
                            });
                        });

                        describe("3 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 3;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = months[1];
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = months[12];
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = months[24];
                            });
                        });
                    });

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            bandLevel = 9;
                        });

                        describe("1 FIXED band", () => {
                            beforeAll(() => {
                                bandsCount = 1;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = months[1];
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = months[12];
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = months[24];
                            });
                        });

                        describe("2 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 2;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = months[1];
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = months[12];
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = months[24];
                            });
                        });

                        describe("3 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 3;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = months[1];
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = months[12];
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = months[24];
                            });
                        });
                    });
                });

                describe("Vested staking", () => {
                    beforeAll(() => {
                        areTokensVested = true;
                    });

                    afterEach(() => {
                        // Staker stakes in the accessible pool of the band level
                        totalStaked = BIGINT_ZERO;
                        for (let i = 0; i < bandsCount; i++) {
                            stakeVestedFixed(
                                alice,
                                bandLevels[bandLevel - 1],
                                bandIds[i],
                                fixedMonths,
                                monthsAfterInit[1],
                            );
                            totalStaked = totalStaked.plus(bandLevelPrices[bandLevel - 1]);
                        }
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            bandLevel = 1;
                        });

                        describe("1 FIXED band", () => {
                            beforeAll(() => {
                                bandsCount = 1;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = months[1];
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = months[12];
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = months[24];
                            });
                        });

                        describe("2 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 2;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = months[1];
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = months[12];
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = months[24];
                            });
                        });

                        describe("3 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 3;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = months[1];
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = months[12];
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = months[24];
                            });
                        });
                    });

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            bandLevel = 5;
                        });

                        describe("1 FIXED band", () => {
                            beforeAll(() => {
                                bandsCount = 1;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = months[1];
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = months[12];
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = months[24];
                            });
                        });

                        describe("2 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 2;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = months[1];
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = months[12];
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = months[24];
                            });
                        });

                        describe("3 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 3;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = months[1];
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = months[12];
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = months[24];
                            });
                        });
                    });

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            bandLevel = 9;
                        });

                        describe("1 FIXED band", () => {
                            beforeAll(() => {
                                bandsCount = 1;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = months[1];
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = months[12];
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = months[24];
                            });
                        });

                        describe("2 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 2;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = months[1];
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = months[12];
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = months[24];
                            });
                        });

                        describe("3 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 3;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = months[1];
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = months[12];
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = months[24];
                            });
                        });
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
                /*//////////////////////////////////////////////////////////////////////////
                                          ASSERT MAIN DATA
            //////////////////////////////////////////////////////////////////////////*/

                log.debug("Should create new bands", []);
                assert.entityCount("Band", bandsCount * stakersCount);
                for (let i = 0; i < bandsCount * stakersCount; i++) {
                    assert.fieldEquals("Band", ids[i], "id", ids[i]);
                }

                log.debug("Should set band values correctly", []);
                for (let i = 0; i < bandsCount; i++) {
                    for (let j = 0; j < stakersCount; j++) {
                        assert.fieldEquals("Band", ids[i * stakersCount + j], "owner", stakers[j].toHex());
                        assert.fieldEquals(
                            "Band",
                            ids[i * stakersCount + j],
                            "stakingStartDate",
                            monthsAfterInit[1].toString(),
                        );
                        assert.fieldEquals("Band", ids[i * stakersCount + j], "bandLevel", bandLevel.toString());
                        assert.fieldEquals(
                            "Band",
                            ids[i * stakersCount + j],
                            "stakingType",
                            stringifyStakingType(StakingType.FIX),
                        );
                        assert.fieldEquals("Band", ids[i * stakersCount + j], "fixedMonths", fixedMonths.toString());
                        assert.fieldEquals(
                            "Band",
                            ids[i * stakersCount + j],
                            "areTokensVested",
                            areTokensVested.toString(),
                        );
                    }
                }

                log.debug("Should add staker to all stakers", []);
                assert.fieldEquals("StakingContract", ids[0], "stakers", convertAddressArrayToString(stakers));

                log.debug("Should updated staking contract details", []);
                assert.fieldEquals("StakingContract", ids[0], "nextBandId", (bandsCount * stakersCount).toString());
                assert.fieldEquals(
                    "StakingContract",
                    ids[0],
                    "totalStakedAmount",
                    totalStaked.times(BigInt.fromI32(stakersCount)).toString(),
                );

                log.debug("Should add band to staker bands array", []);
                for (let i = 0; i < stakersCount; i++) {
                    const staker = stakers[i].toHex();
                    const bands = convertBigIntArrayToString(
                        createArrayWithMultiplication(
                            bandIds[i],
                            BigInt.fromI32(bandsCount + i - 1),
                            BigInt.fromI32(stakersCount),
                        ),
                    );

                    assert.fieldEquals("Staker", staker, "fixedBands", bands);
                    assert.fieldEquals("Staker", staker, "flexiBands", "[]");

                    log.debug("Should update staker details", []);
                    assert.fieldEquals("Staker", staker, "bandsCount", bandsCount.toString());
                    assert.fieldEquals("Staker", staker, "stakedAmount", totalStaked.toString());
                }

                /*//////////////////////////////////////////////////////////////////////////
                                            ASSERT SHARES
            //////////////////////////////////////////////////////////////////////////*/

                log.debug("Should set band shares", []);
                for (let i = 0; i < bandsCount * stakersCount; i++) {
                    assert.fieldEquals("Band", ids[i], "sharesAmount", shares.toString());
                }

                log.debug("Should set staker shares", []);
                for (let i = 0; i < stakersCount; i++) {
                    const stakerId = stakers[i].toHex();
                    assert.fieldEquals(
                        "Staker",
                        stakerId,
                        "fixedSharesPerPool",
                        convertBigIntArrayToString(fixedStakerSharesPerPool),
                    );
                    assert.fieldEquals(
                        "Staker",
                        stakerId,
                        "isolatedFixedSharesPerPool",
                        convertBigIntArrayToString(isolatedFixedSharesPerPool),
                    );
                }

                log.debug("Should set pool shares", []);
                for (let i = 1; i <= totalPools.toI32(); i++) {
                    const totalFixedShares = fixedStakerSharesPerPool[i - 1].times(BigInt.fromI32(stakersCount));
                    const totalIsolatedFixedShares = isolatedFixedSharesPerPool[i - 1].times(
                        BigInt.fromI32(stakersCount),
                    );

                    assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", totalFixedShares.toString());
                    assert.fieldEquals(
                        "Pool",
                        ids[i],
                        "isolatedFixedSharesAmount",
                        totalIsolatedFixedShares.toString(),
                    );
                }
            });

            describe("Single band level", () => {
                describe("Standard staking", () => {
                    beforeAll(() => {
                        areTokensVested = false;
                    });

                    afterEach(() => {
                        shares = sharesInMonths[fixedMonths.toI32() - 1];
                        totalShares = shares.times(BigInt.fromI32(bandsCount));

                        fixedStakerSharesPerPool = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

                        isolatedFixedSharesPerPool = createEmptyArray(totalPools);
                        isolatedFixedSharesPerPool[bandLevel - 1] = totalShares;

                        // Staker stakes in the accessible pool of the band level
                        totalStaked = BIGINT_ZERO;
                        for (let i = 0; i < bandsCount; i++) {
                            for (let j = 0; j < stakersCount; j++) {
                                stakeStandardFixed(
                                    stakers[j],
                                    bandLevels[bandLevel - 1],
                                    bandIds[i * stakersCount + j],
                                    fixedMonths,
                                    monthsAfterInit[1],
                                );
                            }
                            totalStaked = totalStaked.plus(bandLevelPrices[bandLevel - 1]);
                        }
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            bandLevel = 1;
                        });

                        describe("1 FIXED band", () => {
                            beforeAll(() => {
                                bandsCount = 1;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = BigInt.fromI32(1);
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = BigInt.fromI32(12);
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = BigInt.fromI32(24);
                            });
                        });

                        describe("2 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 2;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = BigInt.fromI32(1);
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = BigInt.fromI32(12);
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = BigInt.fromI32(24);
                            });
                        });

                        describe("3 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 3;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = BigInt.fromI32(1);
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = BigInt.fromI32(12);
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = BigInt.fromI32(24);
                            });
                        });
                    });

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            bandLevel = 5;
                        });

                        describe("1 FIXED band", () => {
                            beforeAll(() => {
                                bandsCount = 1;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = BigInt.fromI32(1);
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = BigInt.fromI32(12);
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = BigInt.fromI32(24);
                            });
                        });

                        describe("2 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 2;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = BigInt.fromI32(1);
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = BigInt.fromI32(12);
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = BigInt.fromI32(24);
                            });
                        });

                        describe("3 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 3;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = BigInt.fromI32(1);
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = BigInt.fromI32(12);
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = BigInt.fromI32(24);
                            });
                        });
                    });

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            bandLevel = 9;
                        });

                        describe("1 FIXED band", () => {
                            beforeAll(() => {
                                bandsCount = 1;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = BigInt.fromI32(1);
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = BigInt.fromI32(12);
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = BigInt.fromI32(24);
                            });
                        });

                        describe("2 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 2;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = BigInt.fromI32(1);
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = BigInt.fromI32(12);
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = BigInt.fromI32(24);
                            });
                        });

                        describe("3 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 3;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = BigInt.fromI32(1);
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = BigInt.fromI32(12);
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = BigInt.fromI32(24);
                            });
                        });
                    });
                });

                describe("Vested staking", () => {
                    beforeAll(() => {
                        areTokensVested = true;
                    });

                    afterEach(() => {
                        shares = sharesInMonths[fixedMonths.toI32() - 1];
                        totalShares = shares.times(BigInt.fromI32(bandsCount));

                        fixedStakerSharesPerPool = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

                        isolatedFixedSharesPerPool = createEmptyArray(totalPools);
                        isolatedFixedSharesPerPool[bandLevel - 1] = totalShares;

                        // Staker stakes in the accessible pool of the band level
                        totalStaked = BIGINT_ZERO;
                        for (let i = 0; i < bandsCount; i++) {
                            for (let j = 0; j < stakersCount; j++) {
                                stakeVestedFixed(
                                    stakers[j],
                                    bandLevels[bandLevel - 1],
                                    bandIds[i * stakersCount + j],
                                    fixedMonths,
                                    monthsAfterInit[1],
                                );
                            }
                            totalStaked = totalStaked.plus(bandLevelPrices[bandLevel - 1]);
                        }
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            bandLevel = 1;
                        });

                        describe("1 FIXED band", () => {
                            beforeAll(() => {
                                bandsCount = 1;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = BigInt.fromI32(1);
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = BigInt.fromI32(12);
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = BigInt.fromI32(24);
                            });
                        });

                        describe("2 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 2;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = BigInt.fromI32(1);
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = BigInt.fromI32(12);
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = BigInt.fromI32(24);
                            });
                        });

                        describe("3 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 3;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = BigInt.fromI32(1);
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = BigInt.fromI32(12);
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = BigInt.fromI32(24);
                            });
                        });
                    });

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            bandLevel = 5;
                        });

                        describe("1 FIXED band", () => {
                            beforeAll(() => {
                                bandsCount = 1;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = BigInt.fromI32(1);
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = BigInt.fromI32(12);
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = BigInt.fromI32(24);
                            });
                        });

                        describe("2 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 2;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = BigInt.fromI32(1);
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = BigInt.fromI32(12);
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = BigInt.fromI32(24);
                            });
                        });

                        describe("3 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 3;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = BigInt.fromI32(1);
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = BigInt.fromI32(12);
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = BigInt.fromI32(24);
                            });
                        });
                    });

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            bandLevel = 9;
                        });

                        describe("1 FIXED band", () => {
                            beforeAll(() => {
                                bandsCount = 1;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = BigInt.fromI32(1);
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = BigInt.fromI32(12);
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = BigInt.fromI32(24);
                            });
                        });

                        describe("2 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 2;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = BigInt.fromI32(1);
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = BigInt.fromI32(12);
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = BigInt.fromI32(24);
                            });
                        });

                        describe("3 FIXED bands", () => {
                            beforeAll(() => {
                                bandsCount = 3;
                            });

                            test("Fixed months - 1", () => {
                                fixedMonths = BigInt.fromI32(1);
                            });

                            test("Fixed months - 12", () => {
                                fixedMonths = BigInt.fromI32(12);
                            });

                            test("Fixed months - 24", () => {
                                fixedMonths = BigInt.fromI32(24);
                            });
                        });
                    });
                });
            });
        });
    });

    describe("Complex cases", () => {
        describe("Only FIXED bands", () => {
            describe("Only Standard FIXED bands", () => {
                test("9 stakers, each staker with different band levels", () => {});
                test("1 staker with 9 bands, each band with different band levels", () => {});
                test("3 stakers, 1 staker with fixed band level 1, 1 staker with fixed band different levels (4, 5, 6), 1 staker with fixed band level 9", () => {});
            });

            describe("Only Vested FIXED bands", () => {
                test("9 stakers, each staker with different band levels", () => {});
                test("1 staker with 9 bands, each band with different band levels", () => {});
                test("3 stakers, 1 staker with fixed band level 1, 1 staker with different fixed band levels (4, 5, 6), 1 staker with fixed band level 9", () => {});
            });

            describe("Mixed FIXED bands", () => {
                test("3 stakers, 1 staker with standard fixed band level 1, 1 staker with standard fixed band levels 4 and vested fixed band levels 6, 1 staker with vested fixed band level 9", () => {});
            });
        });

        describe("Only FLEXI bands", () => {
            describe("Only Standard FLEXI bands", () => {
                test("9 stakers, each staker with different band levels", () => {});
                test("1 staker with 9 bands, each band with different band levels", () => {});
                test("3 stakers, 1 staker with flexi band level 1, 1 staker with flexi band different levels (4, 5, 6), 1 staker with flexi band level 9", () => {});
            });

            describe("Only Vested FLEXI bands", () => {
                test("9 stakers, each staker with different band levels", () => {});
                test("1 staker with 9 bands, each band with different band levels", () => {});
                test("3 stakers, 1 staker with flexi band level 1, 1 staker with different flexi band levels (4, 5, 6), 1 staker with flexi band level 9", () => {});
            });

            describe("Mixed FLEXI bands", () => {
                test("3 stakers, 1 staker with standard flexi band level 1, 1 staker with standard flexi band levels 4 and vested flexi band levels 6, 1 staker with vested flexi band level 9", () => {});
            });
        });

        describe("All Mixed bands", () => {
            test("5 stakers, 1 staker with standard fixed band level 1, 1 staker with standard flexi band level 2, 1 staker with vested fixed band level 3, 1 staker with vested flexi band level 4, 1 staker with standard fixed (lvl 6), standard flexi (lvl 7), vested fixed (lvl 8), vested flexi (lvl 9)", () => {});
        });
    });
});
