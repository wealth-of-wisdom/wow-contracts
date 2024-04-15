import { Address, BigInt, log } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, beforeAll, afterEach, clearStore, assert } from "matchstick-as/assembly/index";
import {
    initializeAndSetUp,
    stakeStandardFixed,
    stakeStandardFlexi,
    stakeVestedFixed,
    stakeVestedFlexi,
    triggerSharesSync,
} from "../helpers/helper";
import { ids, bandIds, alice, bob, charlie, totalPools } from "../../utils/data/constants";
import { monthsAfterInit } from "../../utils/data/dates";
import { sharesInMonths, bandLevels, months, bandLevelPrices } from "../../utils/data/data";
import {
    convertAddressArrayToString,
    convertBigIntArrayToString,
    createArray,
    createArrayWithMultiplication,
    createEmptyArray,
} from "../../utils/arrays";
import { stringifyStakingType } from "../../../src/utils/utils";
import { BIGINT_ZERO, StakingType } from "../../../src/utils/constants";

let bandsCount = 0;
let stakersCount = 0;
let shares: BigInt;
let stakers: Address[];
let fixedMonths: BigInt = BigInt.fromI32(20);
let bandLevel = 0;
let totalStaked: BigInt;
let totalShares: BigInt;
let areTokensVested: boolean;

// Fixed bands data
let fixedStakerSharesPerPool: BigInt[];
let isolatedFixedSharesPerPool: BigInt[];

// Flexi bands data
let flexiStakerSharesPerPool: BigInt[];
let isolatedFlexiSharesPerPool: BigInt[];

describe("handleStaked()", () => {
    beforeEach(() => {
        clearStore();
        initializeAndSetUp();
    });

    describe("Simple cases", () => {
        describe("Only FIXED bands", () => {
            describe("1 Staker", () => {
                beforeAll(() => {
                    stakersCount = 1;
                });

                afterEach(() => {
                    /*//////////////////////////////////////////////////////////////////////////
                                                GET ASSERION DATA
                    //////////////////////////////////////////////////////////////////////////*/

                    const emptySharesArray = convertBigIntArrayToString(createEmptyArray(totalPools));

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

                    log.debug("Should set staker fixed shares", []);
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

                    log.debug("Should not set staker flexi shares", []);
                    assert.fieldEquals("Staker", alice.toHex(), "flexiSharesPerPool", emptySharesArray);
                    assert.fieldEquals("Staker", alice.toHex(), "isolatedFlexiSharesPerPool", emptySharesArray);

                    log.debug("Should set pool fixed shares", []);
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

                    log.debug("Should not set pool flexi shares", []);
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", "0");
                        assert.fieldEquals("Pool", ids[i], "isolatedFlexiSharesAmount", "0");
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
                                                GET ASSERION DATA
                    //////////////////////////////////////////////////////////////////////////*/

                    const emptySharesArray = convertBigIntArrayToString(createEmptyArray(totalPools));

                    shares = sharesInMonths[fixedMonths.toI32() - 1];
                    totalShares = shares.times(BigInt.fromI32(bandsCount));

                    fixedStakerSharesPerPool = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

                    isolatedFixedSharesPerPool = createEmptyArray(totalPools);
                    isolatedFixedSharesPerPool[bandLevel - 1] = totalShares;

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
                            assert.fieldEquals(
                                "Band",
                                ids[i * stakersCount + j],
                                "fixedMonths",
                                fixedMonths.toString(),
                            );
                            assert.fieldEquals(
                                "Band",
                                ids[i * stakersCount + j],
                                "areTokensVested",
                                areTokensVested.toString(),
                            );
                        }
                    }

                    log.debug("Should updated staking contract details", []);
                    assert.fieldEquals("StakingContract", ids[0], "stakers", convertAddressArrayToString(stakers));
                    assert.fieldEquals("StakingContract", ids[0], "nextBandId", (bandsCount * stakersCount).toString());
                    assert.fieldEquals(
                        "StakingContract",
                        ids[0],
                        "totalStakedAmount",
                        totalStaked.times(BigInt.fromI32(stakersCount)).toString(),
                    );

                    log.debug("Should update staker details", []);
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

                    log.debug("Should set staker fixed shares", []);
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

                    log.debug("Should not set staker flexi shares", []);
                    for (let i = 0; i < stakersCount; i++) {
                        const stakerId = stakers[i].toHex();
                        assert.fieldEquals("Staker", stakerId, "flexiSharesPerPool", emptySharesArray);
                        assert.fieldEquals("Staker", stakerId, "isolatedFlexiSharesPerPool", emptySharesArray);
                    }

                    log.debug("Should set pool fixed shares", []);
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

                    log.debug("Should not set pool flexi shares", []);
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", "0");
                        assert.fieldEquals("Pool", ids[i], "isolatedFlexiSharesAmount", "0");
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

        describe("Only FLEXI bands", () => {
            describe("1 Staker", () => {
                beforeAll(() => {
                    stakersCount = 1;
                });

                afterEach(() => {
                    triggerSharesSync(monthsAfterInit[13]);

                    /*//////////////////////////////////////////////////////////////////////////
                                                GET ASSERION DATA
                    //////////////////////////////////////////////////////////////////////////*/

                    const emptySharesArray = convertBigIntArrayToString(createEmptyArray(totalPools));

                    shares = sharesInMonths[11];
                    totalShares = shares.times(BigInt.fromI32(bandsCount));

                    flexiStakerSharesPerPool = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

                    isolatedFlexiSharesPerPool = createEmptyArray(totalPools);
                    isolatedFlexiSharesPerPool[bandLevel - 1] = totalShares;

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
                        assert.fieldEquals("Band", ids[i], "stakingType", stringifyStakingType(StakingType.FLEXI));
                        assert.fieldEquals("Band", ids[i], "fixedMonths", "0");
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
                    assert.fieldEquals("Staker", alice.toHex(), "fixedBands", "[]");
                    assert.fieldEquals("Staker", alice.toHex(), "flexiBands", bands);

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

                    log.debug("Should set staker flexi shares", []);
                    assert.fieldEquals(
                        "Staker",
                        alice.toHex(),
                        "flexiSharesPerPool",
                        convertBigIntArrayToString(flexiStakerSharesPerPool),
                    );
                    assert.fieldEquals(
                        "Staker",
                        alice.toHex(),
                        "isolatedFlexiSharesPerPool",
                        convertBigIntArrayToString(isolatedFlexiSharesPerPool),
                    );

                    log.debug("Should not set staker fixed shares", []);
                    assert.fieldEquals("Staker", alice.toHex(), "fixedSharesPerPool", emptySharesArray);
                    assert.fieldEquals("Staker", alice.toHex(), "isolatedFixedSharesPerPool", emptySharesArray);

                    log.debug("Should set pool flexi shares", []);
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        assert.fieldEquals(
                            "Pool",
                            ids[i],
                            "totalFlexiSharesAmount",
                            flexiStakerSharesPerPool[i - 1].toString(),
                        );
                        assert.fieldEquals(
                            "Pool",
                            ids[i],
                            "isolatedFlexiSharesAmount",
                            isolatedFlexiSharesPerPool[i - 1].toString(),
                        );
                    }

                    log.debug("Should not set pool fixed shares", []);
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", "0");
                        assert.fieldEquals("Pool", ids[i], "isolatedFixedSharesAmount", "0");
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
                                stakeStandardFlexi(alice, bandLevels[bandLevel - 1], bandIds[i], monthsAfterInit[1]);
                                totalStaked = totalStaked.plus(bandLevelPrices[bandLevel - 1]);
                            }
                        });

                        describe("Band level 1", () => {
                            beforeAll(() => {
                                bandLevel = 1;
                            });

                            test("1 FLEXI band", () => {
                                bandsCount = 1;
                            });

                            test("2 FLEXI bands", () => {
                                bandsCount = 2;
                            });

                            test("3 FLEXI bands", () => {
                                bandsCount = 3;
                            });
                        });

                        describe("Band level 5", () => {
                            beforeAll(() => {
                                bandLevel = 5;
                            });

                            test("1 FLEXI band", () => {
                                bandsCount = 1;
                            });

                            test("2 FLEXI bands", () => {
                                bandsCount = 2;
                            });

                            test("3 FLEXI bands", () => {
                                bandsCount = 3;
                            });
                        });

                        describe("Band level 9", () => {
                            beforeAll(() => {
                                bandLevel = 9;
                            });

                            test("1 FLEXI band", () => {
                                bandsCount = 1;
                            });

                            test("2 FLEXI bands", () => {
                                bandsCount = 2;
                            });

                            test("3 FLEXI bands", () => {
                                bandsCount = 3;
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
                                stakeVestedFlexi(alice, bandLevels[bandLevel - 1], bandIds[i], monthsAfterInit[1]);
                                totalStaked = totalStaked.plus(bandLevelPrices[bandLevel - 1]);
                            }
                        });

                        describe("Band level 1", () => {
                            beforeAll(() => {
                                bandLevel = 1;
                            });

                            test("1 FLEXI band", () => {
                                bandsCount = 1;
                            });

                            test("2 FLEXI bands", () => {
                                bandsCount = 2;
                            });

                            test("3 FLEXI bands", () => {
                                bandsCount = 3;
                            });
                        });

                        describe("Band level 5", () => {
                            beforeAll(() => {
                                bandLevel = 5;
                            });

                            test("1 FLEXI band", () => {
                                bandsCount = 1;
                            });

                            test("2 FLEXI bands", () => {
                                bandsCount = 2;
                            });

                            test("3 FLEXI bands", () => {
                                bandsCount = 3;
                            });
                        });

                        describe("Band level 9", () => {
                            beforeAll(() => {
                                bandLevel = 9;
                            });

                            test("1 FLEXI band", () => {
                                bandsCount = 1;
                            });

                            test("2 FLEXI bands", () => {
                                bandsCount = 2;
                            });

                            test("3 FLEXI bands", () => {
                                bandsCount = 3;
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
                    triggerSharesSync(monthsAfterInit[13]);

                    /*//////////////////////////////////////////////////////////////////////////
                                                GET ASSERION DATA
                    //////////////////////////////////////////////////////////////////////////*/

                    const emptySharesArray = convertBigIntArrayToString(createEmptyArray(totalPools));

                    shares = sharesInMonths[11];
                    totalShares = shares.times(BigInt.fromI32(bandsCount));

                    flexiStakerSharesPerPool = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

                    isolatedFlexiSharesPerPool = createEmptyArray(totalPools);
                    isolatedFlexiSharesPerPool[bandLevel - 1] = totalShares;

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
                                stringifyStakingType(StakingType.FLEXI),
                            );
                            assert.fieldEquals("Band", ids[i * stakersCount + j], "fixedMonths", "0");
                            assert.fieldEquals(
                                "Band",
                                ids[i * stakersCount + j],
                                "areTokensVested",
                                areTokensVested.toString(),
                            );
                        }
                    }

                    log.debug("Should updated staking contract details", []);
                    assert.fieldEquals("StakingContract", ids[0], "stakers", convertAddressArrayToString(stakers));
                    assert.fieldEquals("StakingContract", ids[0], "nextBandId", (bandsCount * stakersCount).toString());
                    assert.fieldEquals(
                        "StakingContract",
                        ids[0],
                        "totalStakedAmount",
                        totalStaked.times(BigInt.fromI32(stakersCount)).toString(),
                    );

                    log.debug("Should update staker details", []);
                    for (let i = 0; i < stakersCount; i++) {
                        const staker = stakers[i].toHex();
                        const bands = convertBigIntArrayToString(
                            createArrayWithMultiplication(
                                bandIds[i],
                                BigInt.fromI32(bandsCount + i - 1),
                                BigInt.fromI32(stakersCount),
                            ),
                        );

                        assert.fieldEquals("Staker", staker, "fixedBands", "[]");
                        assert.fieldEquals("Staker", staker, "flexiBands", bands);
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

                    log.debug("Should set staker flexi shares", []);
                    for (let i = 0; i < stakersCount; i++) {
                        const stakerId = stakers[i].toHex();
                        assert.fieldEquals(
                            "Staker",
                            stakerId,
                            "flexiSharesPerPool",
                            convertBigIntArrayToString(flexiStakerSharesPerPool),
                        );
                        assert.fieldEquals(
                            "Staker",
                            stakerId,
                            "isolatedFlexiSharesPerPool",
                            convertBigIntArrayToString(isolatedFlexiSharesPerPool),
                        );
                    }

                    log.debug("Should not set staker fixed shares", []);
                    for (let i = 0; i < stakersCount; i++) {
                        const stakerId = stakers[i].toHex();
                        assert.fieldEquals("Staker", stakerId, "fixedSharesPerPool", emptySharesArray);
                        assert.fieldEquals("Staker", stakerId, "isolatedFixedSharesPerPool", emptySharesArray);
                    }

                    log.debug("Should set pool flexi shares", []);
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        const totalFlexiShares = flexiStakerSharesPerPool[i - 1].times(BigInt.fromI32(stakersCount));
                        const totalIsolatedFlexiShares = isolatedFlexiSharesPerPool[i - 1].times(
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

                    log.debug("Should not set pool fixed shares", []);
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", "0");
                        assert.fieldEquals("Pool", ids[i], "isolatedFixedSharesAmount", "0");
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
                                for (let j = 0; j < stakersCount; j++) {
                                    stakeStandardFlexi(
                                        stakers[j],
                                        bandLevels[bandLevel - 1],
                                        bandIds[i * stakersCount + j],
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

                            test("1 FLEXI band", () => {
                                bandsCount = 1;
                            });

                            test("2 FLEXI bands", () => {
                                bandsCount = 2;
                            });

                            test("3 FLEXI bands", () => {
                                bandsCount = 3;
                            });
                        });

                        describe("Band level 5", () => {
                            beforeAll(() => {
                                bandLevel = 5;
                            });

                            test("1 FLEXI band", () => {
                                bandsCount = 1;
                            });

                            test("2 FLEXI bands", () => {
                                bandsCount = 2;
                            });

                            test("3 FLEXI bands", () => {
                                bandsCount = 3;
                            });
                        });

                        describe("Band level 9", () => {
                            beforeAll(() => {
                                bandLevel = 9;
                            });

                            test("1 FLEXI band", () => {
                                bandsCount = 1;
                            });

                            test("2 FLEXI bands", () => {
                                bandsCount = 2;
                            });

                            test("3 FLEXI bands", () => {
                                bandsCount = 3;
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
                                    stakeVestedFlexi(
                                        stakers[j],
                                        bandLevels[bandLevel - 1],
                                        bandIds[i * stakersCount + j],
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

                            test("1 FLEXI band", () => {
                                bandsCount = 1;
                            });

                            test("2 FLEXI bands", () => {
                                bandsCount = 2;
                            });

                            test("3 FLEXI bands", () => {
                                bandsCount = 3;
                            });
                        });

                        describe("Band level 5", () => {
                            beforeAll(() => {
                                bandLevel = 5;
                            });

                            test("1 FLEXI band", () => {
                                bandsCount = 1;
                            });

                            test("2 FLEXI bands", () => {
                                bandsCount = 2;
                            });

                            test("3 FLEXI bands", () => {
                                bandsCount = 3;
                            });
                        });

                        describe("Band level 9", () => {
                            beforeAll(() => {
                                bandLevel = 9;
                            });

                            test("1 FLEXI band", () => {
                                bandsCount = 1;
                            });

                            test("2 FLEXI bands", () => {
                                bandsCount = 2;
                            });

                            test("3 FLEXI bands", () => {
                                bandsCount = 3;
                            });
                        });
                    });
                });
            });
        });
    });
});
