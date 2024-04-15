import { Address, BigInt } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, beforeAll, clearStore, assert } from "matchstick-as/assembly/index";
import {
    initializeAndSetUp,
    stakeStandardFixed,
    stakeStandardFlexi,
    stakeVestedFixed,
    stakeVestedFlexi,
} from "../helpers/helper";
import { ids, bandIds, alice, bob, charlie, users, totalPools, totalBandLevels, dan } from "../../utils/data/constants";
import { monthsAfterInit } from "../../utils/data/dates";
import { sharesInMonths, bandLevels, months, bandLevelPrices } from "../../utils/data/data";
import {
    convertAddressArrayToString,
    convertBigIntArrayToString,
    createArray,
    createDoubleEmptyArray,
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
let stakerBands: BigInt[][];
let stakerTokensAreVested: boolean[][];
let stakerBandsTypes: StakingType[][];

// Fixed bands data
let fixedStakerSharesPerPool: BigInt[];
let isolatedFixedSharesPerPool: BigInt[];
let allStakerFixedShares: BigInt[][];
let allStakerIsolatedFixedShares: BigInt[][];
let allPoolTotalFixedShares: BigInt[];
let allPoolIsolatedFixedShares: BigInt[];

// Flexi bands data
let allStakerFlexiShares: BigInt[][];
let allStakerIsolatedFlexiShares: BigInt[][];
let allPoolTotalFlexiShares: BigInt[];
let allPoolIsolatedFlexiShares: BigInt[];

describe("handleStaked()", () => {
    beforeEach(() => {
        clearStore();
        initializeAndSetUp();
    });

    describe("Complex cases", () => {
        describe("Only FIXED bands", () => {
            describe("Single type stakes (standard or vested)", () => {
                describe("9 stakers, each staker with different band levels", () => {
                    beforeAll(() => {
                        bandsCount = 9;
                        stakersCount = 9;

                        // Calculations for testing shares
                        allPoolTotalFixedShares = createEmptyArray(totalPools);
                        allPoolIsolatedFixedShares = createEmptyArray(totalPools);
                        allStakerFixedShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);
                        allStakerIsolatedFixedShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);

                        for (let i = 0; i < stakersCount; i++) {
                            allStakerIsolatedFixedShares[i][i] = sharesInMonths[i];
                            allPoolIsolatedFixedShares[i] = allPoolIsolatedFixedShares[i].plus(sharesInMonths[i]);

                            for (let j = 0; j < i + 1; j++) {
                                allStakerFixedShares[i][j] = sharesInMonths[i];
                                allPoolTotalFixedShares[j] = allPoolTotalFixedShares[j].plus(sharesInMonths[i]);
                            }
                        }
                    });

                    describe("Standard FIXED bands", () => {
                        beforeAll(() => {
                            areTokensVested = false;
                        });

                        beforeEach(() => {
                            totalStaked = BIGINT_ZERO;

                            // Stake in all bands
                            for (let i = 0; i < totalBandLevels.toI32(); i++) {
                                stakeStandardFixed(
                                    users[i],
                                    bandLevels[i],
                                    bandIds[i],
                                    months[i + 1],
                                    monthsAfterInit[i + 1],
                                );
                                totalStaked = totalStaked.plus(bandLevelPrices[i]);
                            }
                        });

                        test("Should create new bands", () => {
                            assert.entityCount("Band", bandsCount);
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "id", ids[i]);
                            }
                        });

                        test("Should set band values correctly", () => {
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "owner", users[i].toHex());
                                assert.fieldEquals(
                                    "Band",
                                    ids[i],
                                    "stakingStartDate",
                                    monthsAfterInit[i + 1].toString(),
                                );
                                assert.fieldEquals("Band", ids[i], "bandLevel", bandLevels[i].toString());
                                assert.fieldEquals(
                                    "Band",
                                    ids[i],
                                    "stakingType",
                                    stringifyStakingType(StakingType.FIX),
                                );
                                assert.fieldEquals("Band", ids[i], "fixedMonths", months[i + 1].toString());
                                assert.fieldEquals("Band", ids[i], "areTokensVested", areTokensVested.toString());
                            }
                        });

                        test("Should updated staking contract details", () => {
                            assert.fieldEquals(
                                "StakingContract",
                                ids[0],
                                "stakers",
                                convertAddressArrayToString(users),
                            );
                            assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
                            assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
                        });

                        test("Should update staker details", () => {
                            for (let i = 0; i < stakersCount; i++) {
                                const staker = users[i].toHex();
                                const bands = `[${ids[i]}]`;

                                assert.fieldEquals("Staker", staker, "fixedBands", bands);
                                assert.fieldEquals("Staker", staker, "flexiBands", "[]");
                                assert.fieldEquals("Staker", staker, "bandsCount", "1");
                                assert.fieldEquals("Staker", staker, "stakedAmount", bandLevelPrices[i].toString());
                            }
                        });

                        describe("Shares calculations", () => {
                            test("Should set band shares", () => {
                                for (let i = 0; i < bandsCount; i++) {
                                    assert.fieldEquals("Band", ids[i], "sharesAmount", sharesInMonths[i].toString());
                                }
                            });

                            test("Should set staker FIXED shares", () => {
                                for (let i = 0; i < stakersCount; i++) {
                                    const staker = users[i].toHex();

                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "fixedSharesPerPool",
                                        convertBigIntArrayToString(allStakerFixedShares[i]),
                                    );
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "isolatedFixedSharesPerPool",
                                        convertBigIntArrayToString(allStakerIsolatedFixedShares[i]),
                                    );
                                }
                            });

                            test("Should not set staker FLEXI shares", () => {
                                const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));

                                for (let i = 0; i < stakersCount; i++) {
                                    const staker = users[i].toHex();
                                    assert.fieldEquals("Staker", staker, "flexiSharesPerPool", stringifiedEmptyArray);
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "isolatedFlexiSharesPerPool",
                                        stringifiedEmptyArray,
                                    );
                                }
                            });

                            test("Should set pool FIXED shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    const totalFixedShares = allPoolTotalFixedShares[i - 1];
                                    const totalIsolatedFixedShares = allPoolIsolatedFixedShares[i - 1];

                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "totalFixedSharesAmount",
                                        totalFixedShares.toString(),
                                    );
                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "isolatedFixedSharesAmount",
                                        totalIsolatedFixedShares.toString(),
                                    );
                                }
                            });

                            test("Should not set pool FLEXI shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", "0");
                                    assert.fieldEquals("Pool", ids[i], "isolatedFlexiSharesAmount", "0");
                                }
                            });
                        });
                    });

                    describe("Vested FIXED bands", () => {
                        beforeAll(() => {
                            areTokensVested = true;
                        });

                        beforeEach(() => {
                            totalStaked = BIGINT_ZERO;

                            // Stake in all bands
                            for (let i = 0; i < totalBandLevels.toI32(); i++) {
                                stakeVestedFixed(
                                    users[i],
                                    bandLevels[i],
                                    bandIds[i],
                                    months[i + 1],
                                    monthsAfterInit[i + 1],
                                );
                                totalStaked = totalStaked.plus(bandLevelPrices[i]);
                            }
                        });

                        test("Should create new bands", () => {
                            assert.entityCount("Band", bandsCount);
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "id", ids[i]);
                            }
                        });

                        test("Should set band values correctly", () => {
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "owner", users[i].toHex());
                                assert.fieldEquals(
                                    "Band",
                                    ids[i],
                                    "stakingStartDate",
                                    monthsAfterInit[i + 1].toString(),
                                );
                                assert.fieldEquals("Band", ids[i], "bandLevel", bandLevels[i].toString());
                                assert.fieldEquals(
                                    "Band",
                                    ids[i],
                                    "stakingType",
                                    stringifyStakingType(StakingType.FIX),
                                );
                                assert.fieldEquals("Band", ids[i], "fixedMonths", months[i + 1].toString());
                                assert.fieldEquals("Band", ids[i], "areTokensVested", areTokensVested.toString());
                            }
                        });

                        test("Should updated staking contract details", () => {
                            assert.fieldEquals(
                                "StakingContract",
                                ids[0],
                                "stakers",
                                convertAddressArrayToString(users),
                            );
                            assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
                            assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
                        });

                        test("Should update staker details", () => {
                            for (let i = 0; i < stakersCount; i++) {
                                const staker = users[i].toHex();
                                const bands = `[${ids[i]}]`;

                                assert.fieldEquals("Staker", staker, "fixedBands", bands);
                                assert.fieldEquals("Staker", staker, "flexiBands", "[]");
                                assert.fieldEquals("Staker", staker, "bandsCount", "1");
                                assert.fieldEquals("Staker", staker, "stakedAmount", bandLevelPrices[i].toString());
                            }
                        });

                        describe("Shares calculations", () => {
                            test("Should set band shares", () => {
                                for (let i = 0; i < bandsCount; i++) {
                                    assert.fieldEquals("Band", ids[i], "sharesAmount", sharesInMonths[i].toString());
                                }
                            });

                            test("Should set staker FIXED shares", () => {
                                for (let i = 0; i < stakersCount; i++) {
                                    const staker = users[i].toHex();

                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "fixedSharesPerPool",
                                        convertBigIntArrayToString(allStakerFixedShares[i]),
                                    );
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "isolatedFixedSharesPerPool",
                                        convertBigIntArrayToString(allStakerIsolatedFixedShares[i]),
                                    );
                                }
                            });

                            test("Should not set staker FLEXI shares", () => {
                                const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));

                                for (let i = 0; i < stakersCount; i++) {
                                    const staker = users[i].toHex();
                                    assert.fieldEquals("Staker", staker, "flexiSharesPerPool", stringifiedEmptyArray);
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "isolatedFlexiSharesPerPool",
                                        stringifiedEmptyArray,
                                    );
                                }
                            });

                            test("Should set pool FIXED shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    const totalFixedShares = allPoolTotalFixedShares[i - 1];
                                    const totalIsolatedFixedShares = allPoolIsolatedFixedShares[i - 1];

                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "totalFixedSharesAmount",
                                        totalFixedShares.toString(),
                                    );
                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "isolatedFixedSharesAmount",
                                        totalIsolatedFixedShares.toString(),
                                    );
                                }
                            });

                            test("Should not set pool FLEXI shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", "0");
                                    assert.fieldEquals("Pool", ids[i], "isolatedFlexiSharesAmount", "0");
                                }
                            });
                        });
                    });
                });

                describe("1 staker with 9 bands, each band with different band levels", () => {
                    beforeAll(() => {
                        bandsCount = 9;
                        stakersCount = 1;

                        // Calculations for testing shares
                        allPoolTotalFixedShares = createEmptyArray(totalPools);
                        allPoolIsolatedFixedShares = createEmptyArray(totalPools);

                        for (let i = 0; i < bandsCount; i++) {
                            allPoolIsolatedFixedShares[i] = allPoolIsolatedFixedShares[i].plus(sharesInMonths[i]);

                            for (let j = 0; j < i + 1; j++) {
                                allPoolTotalFixedShares[j] = allPoolTotalFixedShares[j].plus(sharesInMonths[i]);
                            }
                        }
                    });

                    describe("Standard FIXED band", () => {
                        beforeAll(() => {
                            areTokensVested = false;
                        });

                        beforeEach(() => {
                            totalStaked = BIGINT_ZERO;

                            // Stake in all bands
                            for (let i = 0; i < totalBandLevels.toI32(); i++) {
                                stakeStandardFixed(
                                    alice,
                                    bandLevels[i],
                                    bandIds[i],
                                    months[i + 1],
                                    monthsAfterInit[i + 1],
                                );
                                totalStaked = totalStaked.plus(bandLevelPrices[i]);
                            }
                        });

                        test("Should create new bands", () => {
                            assert.entityCount("Band", bandsCount);
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "id", ids[i]);
                            }
                        });

                        test("Should set band values correctly", () => {
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "owner", alice.toHex());
                                assert.fieldEquals(
                                    "Band",
                                    ids[i],
                                    "stakingStartDate",
                                    monthsAfterInit[i + 1].toString(),
                                );
                                assert.fieldEquals("Band", ids[i], "bandLevel", bandLevels[i].toString());
                                assert.fieldEquals(
                                    "Band",
                                    ids[i],
                                    "stakingType",
                                    stringifyStakingType(StakingType.FIX),
                                );
                                assert.fieldEquals("Band", ids[i], "fixedMonths", months[i + 1].toString());
                                assert.fieldEquals("Band", ids[i], "areTokensVested", areTokensVested.toString());
                            }
                        });

                        test("Should updated staking contract details", () => {
                            const stakers: string = `[${alice.toHex()}]`;
                            assert.fieldEquals("StakingContract", ids[0], "stakers", stakers);
                            assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
                            assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
                        });

                        test("Should update staker details", () => {
                            const staker = alice.toHex();
                            const bands = createArray(BIGINT_ZERO, BigInt.fromI32(bandsCount - 1));

                            assert.fieldEquals("Staker", staker, "fixedBands", convertBigIntArrayToString(bands));
                            assert.fieldEquals("Staker", staker, "flexiBands", "[]");
                            assert.fieldEquals("Staker", staker, "bandsCount", "9");
                            assert.fieldEquals("Staker", staker, "stakedAmount", totalStaked.toString());
                        });

                        describe("Shares calculations", () => {
                            test("Should set band shares", () => {
                                for (let i = 0; i < bandsCount; i++) {
                                    assert.fieldEquals("Band", ids[i], "sharesAmount", sharesInMonths[i].toString());
                                }
                            });

                            test("Should set staker FIXED shares", () => {
                                const staker = alice.toHex();

                                assert.fieldEquals(
                                    "Staker",
                                    staker,
                                    "fixedSharesPerPool",
                                    convertBigIntArrayToString(allPoolTotalFixedShares),
                                );
                                assert.fieldEquals(
                                    "Staker",
                                    staker,
                                    "isolatedFixedSharesPerPool",
                                    convertBigIntArrayToString(allPoolIsolatedFixedShares),
                                );
                            });

                            test("Should not set staker FLEXI shares", () => {
                                const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));
                                const staker = alice.toHex();

                                assert.fieldEquals("Staker", staker, "flexiSharesPerPool", stringifiedEmptyArray);
                                assert.fieldEquals(
                                    "Staker",
                                    staker,
                                    "isolatedFlexiSharesPerPool",
                                    stringifiedEmptyArray,
                                );
                            });

                            test("Should set pool FIXED shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    const totalFixedShares = allPoolTotalFixedShares[i - 1];
                                    const totalIsolatedFixedShares = allPoolIsolatedFixedShares[i - 1];

                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "totalFixedSharesAmount",
                                        totalFixedShares.toString(),
                                    );
                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "isolatedFixedSharesAmount",
                                        totalIsolatedFixedShares.toString(),
                                    );
                                }
                            });

                            test("Should not set pool FLEXI shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", "0");
                                    assert.fieldEquals("Pool", ids[i], "isolatedFlexiSharesAmount", "0");
                                }
                            });
                        });
                    });

                    describe("Vested FIXED band", () => {
                        beforeAll(() => {
                            areTokensVested = true;
                        });

                        beforeEach(() => {
                            totalStaked = BIGINT_ZERO;

                            // Stake in all bands
                            for (let i = 0; i < totalBandLevels.toI32(); i++) {
                                stakeVestedFixed(
                                    alice,
                                    bandLevels[i],
                                    bandIds[i],
                                    months[i + 1],
                                    monthsAfterInit[i + 1],
                                );
                                totalStaked = totalStaked.plus(bandLevelPrices[i]);
                            }
                        });

                        test("Should create new bands", () => {
                            assert.entityCount("Band", bandsCount);
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "id", ids[i]);
                            }
                        });

                        test("Should set band values correctly", () => {
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "owner", alice.toHex());
                                assert.fieldEquals(
                                    "Band",
                                    ids[i],
                                    "stakingStartDate",
                                    monthsAfterInit[i + 1].toString(),
                                );
                                assert.fieldEquals("Band", ids[i], "bandLevel", bandLevels[i].toString());
                                assert.fieldEquals(
                                    "Band",
                                    ids[i],
                                    "stakingType",
                                    stringifyStakingType(StakingType.FIX),
                                );
                                assert.fieldEquals("Band", ids[i], "fixedMonths", months[i + 1].toString());
                                assert.fieldEquals("Band", ids[i], "areTokensVested", areTokensVested.toString());
                            }
                        });

                        test("Should updated staking contract details", () => {
                            const stakers: string = `[${alice.toHex()}]`;
                            assert.fieldEquals("StakingContract", ids[0], "stakers", stakers);
                            assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
                            assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
                        });

                        test("Should update staker details", () => {
                            const staker = alice.toHex();
                            const bands = createArray(BIGINT_ZERO, BigInt.fromI32(bandsCount - 1));

                            assert.fieldEquals("Staker", staker, "fixedBands", convertBigIntArrayToString(bands));
                            assert.fieldEquals("Staker", staker, "flexiBands", "[]");
                            assert.fieldEquals("Staker", staker, "bandsCount", "9");
                            assert.fieldEquals("Staker", staker, "stakedAmount", totalStaked.toString());
                        });

                        describe("Shares calculations", () => {
                            test("Should set band shares", () => {
                                for (let i = 0; i < bandsCount; i++) {
                                    assert.fieldEquals("Band", ids[i], "sharesAmount", sharesInMonths[i].toString());
                                }
                            });

                            test("Should set staker FIXED shares", () => {
                                const staker = alice.toHex();

                                assert.fieldEquals(
                                    "Staker",
                                    staker,
                                    "fixedSharesPerPool",
                                    convertBigIntArrayToString(allPoolTotalFixedShares),
                                );
                                assert.fieldEquals(
                                    "Staker",
                                    staker,
                                    "isolatedFixedSharesPerPool",
                                    convertBigIntArrayToString(allPoolIsolatedFixedShares),
                                );
                            });

                            test("Should not set staker FLEXI shares", () => {
                                const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));
                                const staker = alice.toHex();

                                assert.fieldEquals("Staker", staker, "flexiSharesPerPool", stringifiedEmptyArray);
                                assert.fieldEquals(
                                    "Staker",
                                    staker,
                                    "isolatedFlexiSharesPerPool",
                                    stringifiedEmptyArray,
                                );
                            });

                            test("Should set pool FIXED shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    const totalFixedShares = allPoolTotalFixedShares[i - 1];
                                    const totalIsolatedFixedShares = allPoolIsolatedFixedShares[i - 1];

                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "totalFixedSharesAmount",
                                        totalFixedShares.toString(),
                                    );
                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "isolatedFixedSharesAmount",
                                        totalIsolatedFixedShares.toString(),
                                    );
                                }
                            });

                            test("Should not set pool FLEXI shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", "0");
                                    assert.fieldEquals("Pool", ids[i], "isolatedFlexiSharesAmount", "0");
                                }
                            });
                        });
                    });
                });

                describe("4 stakers, 8 bands, all random stakes", () => {
                    beforeAll(() => {
                        bandsCount = 8;
                        stakersCount = 4;
                        stakers = [alice, bob, charlie, dan];
                        stakerBands = [
                            [bandLevels[0]],
                            [bandLevels[3], bandLevels[1], bandLevels[1]],
                            [bandLevels[3], bandLevels[7], bandLevels[5]],
                            [bandLevels[8]],
                        ];

                        // Calculations for testing shares
                        allPoolTotalFixedShares = createEmptyArray(totalPools);
                        allPoolIsolatedFixedShares = createEmptyArray(totalPools);
                        allStakerFixedShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);
                        allStakerIsolatedFixedShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);
                        let bandId = 0;

                        for (let i = 0; i < stakersCount; i++) {
                            const bands = stakerBands[i];
                            const bandsCount = bands.length;

                            for (let j = 0; j < bandsCount; j++) {
                                const bandLevel = bands[j].toI32() - 1;
                                const shares = sharesInMonths[bandId];

                                allStakerIsolatedFixedShares[i][bandLevel] =
                                    allStakerIsolatedFixedShares[i][bandLevel].plus(shares);
                                allPoolIsolatedFixedShares[bandLevel] =
                                    allPoolIsolatedFixedShares[bandLevel].plus(shares);

                                for (let k = 0; k < bandLevel + 1; k++) {
                                    allStakerFixedShares[i][k] = allStakerFixedShares[i][k].plus(shares);
                                    allPoolTotalFixedShares[k] = allPoolTotalFixedShares[k].plus(shares);
                                }

                                bandId++;
                            }
                        }
                    });

                    describe("Standard FIXED bands", () => {
                        beforeAll(() => {
                            areTokensVested = false;
                        });

                        beforeEach(() => {
                            let bandId = 0;
                            totalStaked = BIGINT_ZERO;

                            for (let i = 0; i < stakersCount; i++) {
                                const bands = stakerBands[i];
                                const bandsCount = bands.length;

                                for (let j = 0; j < bandsCount; j++) {
                                    const bandLevel = bands[j];

                                    stakeStandardFixed(
                                        stakers[i],
                                        bandLevel,
                                        bandIds[bandId],
                                        months[bandId + 1],
                                        monthsAfterInit[bandId + 1],
                                    );
                                    totalStaked = totalStaked.plus(bandLevelPrices[bandLevel.toI32() - 1]);
                                    bandId++;
                                }
                            }
                        });

                        test("Should create new bands", () => {
                            assert.entityCount("Band", bandsCount);
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "id", ids[i]);
                            }
                        });

                        test("Should set band values correctly", () => {
                            let bandId = 0;

                            for (let i = 0; i < stakersCount; i++) {
                                const bands = stakerBands[i];
                                const stakerBandsCount = bands.length;

                                for (let j = 0; j < stakerBandsCount; j++) {
                                    assert.fieldEquals("Band", ids[bandId], "owner", stakers[i].toHex());
                                    assert.fieldEquals(
                                        "Band",
                                        ids[bandId],
                                        "stakingStartDate",
                                        monthsAfterInit[bandId + 1].toString(),
                                    );
                                    assert.fieldEquals("Band", ids[bandId], "bandLevel", bands[j].toString());
                                    assert.fieldEquals(
                                        "Band",
                                        ids[bandId],
                                        "stakingType",
                                        stringifyStakingType(StakingType.FIX),
                                    );
                                    assert.fieldEquals(
                                        "Band",
                                        ids[bandId],
                                        "fixedMonths",
                                        months[bandId + 1].toString(),
                                    );
                                    assert.fieldEquals(
                                        "Band",
                                        ids[bandId],
                                        "areTokensVested",
                                        areTokensVested.toString(),
                                    );

                                    bandId++;
                                }
                            }
                        });

                        test("Should updated staking contract details", () => {
                            assert.fieldEquals(
                                "StakingContract",
                                ids[0],
                                "stakers",
                                convertAddressArrayToString(stakers),
                            );
                            assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
                            assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
                        });

                        test("Should update staker details", () => {
                            let bandId = 0;

                            for (let i = 0; i < stakersCount; i++) {
                                const staker = stakers[i].toHex();
                                const bandsWithLevels = stakerBands[i];
                                const stakerBandsCount = bandsWithLevels.length;
                                const bands: BigInt[] = [];
                                let stakedAmount: BigInt = BIGINT_ZERO;

                                for (let j = 0; j < stakerBandsCount; j++) {
                                    stakedAmount = stakedAmount.plus(bandLevelPrices[bandsWithLevels[j].toI32() - 1]);
                                    bands.push(BigInt.fromI32(bandId));
                                    bandId++;
                                }

                                assert.fieldEquals("Staker", staker, "fixedBands", convertBigIntArrayToString(bands));
                                assert.fieldEquals("Staker", staker, "flexiBands", "[]");
                                assert.fieldEquals("Staker", staker, "bandsCount", stakerBandsCount.toString());
                                assert.fieldEquals("Staker", staker, "stakedAmount", stakedAmount.toString());
                            }
                        });

                        describe("Shares calculations", () => {
                            test("Should set band shares", () => {
                                let bandId = 0;
                                for (let i = 0; i < stakersCount; i++) {
                                    const bandsWithLevels = stakerBands[i];
                                    const stakerBandsCount = bandsWithLevels.length;

                                    for (let j = 0; j < stakerBandsCount; j++) {
                                        assert.fieldEquals(
                                            "Band",
                                            ids[bandId],
                                            "sharesAmount",
                                            sharesInMonths[bandId].toString(),
                                        );
                                    }
                                }
                            });

                            test("Should set staker FIXED shares", () => {
                                for (let i = 0; i < stakersCount; i++) {
                                    const staker = stakers[i].toHex();
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "fixedSharesPerPool",
                                        convertBigIntArrayToString(allStakerFixedShares[i]),
                                    );
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "isolatedFixedSharesPerPool",
                                        convertBigIntArrayToString(allStakerIsolatedFixedShares[i]),
                                    );
                                }
                            });

                            test("Should not set staker FLEXI shares", () => {
                                const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));
                                for (let i = 0; i < stakersCount; i++) {
                                    const staker = stakers[i].toHex();
                                    assert.fieldEquals("Staker", staker, "flexiSharesPerPool", stringifiedEmptyArray);
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "isolatedFlexiSharesPerPool",
                                        stringifiedEmptyArray,
                                    );
                                }
                            });

                            test("Should set pool FIXED shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    const totalFixedShares = allPoolTotalFixedShares[i - 1];
                                    const totalIsolatedFixedShares = allPoolIsolatedFixedShares[i - 1];
                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "totalFixedSharesAmount",
                                        totalFixedShares.toString(),
                                    );
                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "isolatedFixedSharesAmount",
                                        totalIsolatedFixedShares.toString(),
                                    );
                                }
                            });

                            test("Should not set pool FLEXI shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", "0");
                                    assert.fieldEquals("Pool", ids[i], "isolatedFlexiSharesAmount", "0");
                                }
                            });
                        });
                    });

                    describe("Vested FIXED bands", () => {
                        beforeAll(() => {
                            areTokensVested = true;
                        });

                        beforeEach(() => {
                            let bandId = 0;
                            totalStaked = BIGINT_ZERO;

                            for (let i = 0; i < stakersCount; i++) {
                                const bands = stakerBands[i];
                                const bandsCount = bands.length;

                                for (let j = 0; j < bandsCount; j++) {
                                    const bandLevel = bands[j];

                                    stakeVestedFixed(
                                        stakers[i],
                                        bandLevel,
                                        bandIds[bandId],
                                        months[bandId + 1],
                                        monthsAfterInit[bandId + 1],
                                    );
                                    totalStaked = totalStaked.plus(bandLevelPrices[bandLevel.toI32() - 1]);
                                    bandId++;
                                }
                            }
                        });

                        test("Should create new bands", () => {
                            assert.entityCount("Band", bandsCount);
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "id", ids[i]);
                            }
                        });

                        test("Should set band values correctly", () => {
                            let bandId = 0;

                            for (let i = 0; i < stakersCount; i++) {
                                const bands = stakerBands[i];
                                const stakerBandsCount = bands.length;

                                for (let j = 0; j < stakerBandsCount; j++) {
                                    assert.fieldEquals("Band", ids[bandId], "owner", stakers[i].toHex());
                                    assert.fieldEquals(
                                        "Band",
                                        ids[bandId],
                                        "stakingStartDate",
                                        monthsAfterInit[bandId + 1].toString(),
                                    );
                                    assert.fieldEquals("Band", ids[bandId], "bandLevel", bands[j].toString());
                                    assert.fieldEquals(
                                        "Band",
                                        ids[bandId],
                                        "stakingType",
                                        stringifyStakingType(StakingType.FIX),
                                    );
                                    assert.fieldEquals(
                                        "Band",
                                        ids[bandId],
                                        "fixedMonths",
                                        months[bandId + 1].toString(),
                                    );
                                    assert.fieldEquals(
                                        "Band",
                                        ids[bandId],
                                        "areTokensVested",
                                        areTokensVested.toString(),
                                    );

                                    bandId++;
                                }
                            }
                        });

                        test("Should updated staking contract details", () => {
                            assert.fieldEquals(
                                "StakingContract",
                                ids[0],
                                "stakers",
                                convertAddressArrayToString(stakers),
                            );
                            assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
                            assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
                        });

                        test("Should update staker details", () => {
                            let bandId = 0;

                            for (let i = 0; i < stakersCount; i++) {
                                const staker = stakers[i].toHex();
                                const bandsWithLevels = stakerBands[i];
                                const stakerBandsCount = bandsWithLevels.length;
                                const bands: BigInt[] = [];
                                let stakedAmount: BigInt = BIGINT_ZERO;

                                for (let j = 0; j < stakerBandsCount; j++) {
                                    stakedAmount = stakedAmount.plus(bandLevelPrices[bandsWithLevels[j].toI32() - 1]);
                                    bands.push(BigInt.fromI32(bandId));
                                    bandId++;
                                }

                                assert.fieldEquals("Staker", staker, "fixedBands", convertBigIntArrayToString(bands));
                                assert.fieldEquals("Staker", staker, "flexiBands", "[]");
                                assert.fieldEquals("Staker", staker, "bandsCount", stakerBandsCount.toString());
                                assert.fieldEquals("Staker", staker, "stakedAmount", stakedAmount.toString());
                            }
                        });

                        describe("Shares calculations", () => {
                            test("Should set band shares", () => {
                                let bandId = 0;
                                for (let i = 0; i < stakersCount; i++) {
                                    const bandsWithLevels = stakerBands[i];
                                    const stakerBandsCount = bandsWithLevels.length;

                                    for (let j = 0; j < stakerBandsCount; j++) {
                                        assert.fieldEquals(
                                            "Band",
                                            ids[bandId],
                                            "sharesAmount",
                                            sharesInMonths[bandId].toString(),
                                        );
                                    }
                                }
                            });

                            test("Should set staker FIXED shares", () => {
                                for (let i = 0; i < stakersCount; i++) {
                                    const staker = stakers[i].toHex();
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "fixedSharesPerPool",
                                        convertBigIntArrayToString(allStakerFixedShares[i]),
                                    );
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "isolatedFixedSharesPerPool",
                                        convertBigIntArrayToString(allStakerIsolatedFixedShares[i]),
                                    );
                                }
                            });

                            test("Should not set staker FLEXI shares", () => {
                                const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));
                                for (let i = 0; i < stakersCount; i++) {
                                    const staker = stakers[i].toHex();
                                    assert.fieldEquals("Staker", staker, "flexiSharesPerPool", stringifiedEmptyArray);
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "isolatedFlexiSharesPerPool",
                                        stringifiedEmptyArray,
                                    );
                                }
                            });

                            test("Should set pool FIXED shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    const totalFixedShares = allPoolTotalFixedShares[i - 1];
                                    const totalIsolatedFixedShares = allPoolIsolatedFixedShares[i - 1];
                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "totalFixedSharesAmount",
                                        totalFixedShares.toString(),
                                    );
                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "isolatedFixedSharesAmount",
                                        totalIsolatedFixedShares.toString(),
                                    );
                                }
                            });

                            test("Should not set pool FLEXI shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", "0");
                                    assert.fieldEquals("Pool", ids[i], "isolatedFlexiSharesAmount", "0");
                                }
                            });
                        });
                    });
                });
            });

            describe("Mixed FIXED bands (standard and vested)", () => {
                describe("4 stakers, 4 vested stakes + 4 standard stakes", () => {
                    beforeAll(() => {
                        bandsCount = 8;
                        stakersCount = 4;
                        stakers = [alice, bob, charlie, dan];
                        stakerBands = [
                            [bandLevels[0]],
                            [bandLevels[3], bandLevels[1], bandLevels[1]],
                            [bandLevels[3], bandLevels[7], bandLevels[5]],
                            [bandLevels[8]],
                        ];
                        stakerTokensAreVested = [[true], [false, false, true], [true, true, false], [false]];

                        // Calculations for testing shares
                        allPoolTotalFixedShares = createEmptyArray(totalPools);
                        allPoolIsolatedFixedShares = createEmptyArray(totalPools);
                        allStakerFixedShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);
                        allStakerIsolatedFixedShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);
                        let bandId = 0;

                        for (let i = 0; i < stakersCount; i++) {
                            const bands = stakerBands[i];
                            const bandsCount = bands.length;

                            for (let j = 0; j < bandsCount; j++) {
                                const bandLevel = bands[j].toI32() - 1;
                                const shares = sharesInMonths[bandId];

                                allStakerIsolatedFixedShares[i][bandLevel] =
                                    allStakerIsolatedFixedShares[i][bandLevel].plus(shares);
                                allPoolIsolatedFixedShares[bandLevel] =
                                    allPoolIsolatedFixedShares[bandLevel].plus(shares);

                                for (let k = 0; k < bandLevel + 1; k++) {
                                    allStakerFixedShares[i][k] = allStakerFixedShares[i][k].plus(shares);
                                    allPoolTotalFixedShares[k] = allPoolTotalFixedShares[k].plus(shares);
                                }

                                bandId++;
                            }
                        }
                    });

                    beforeEach(() => {
                        let bandId = 0;
                        totalStaked = BIGINT_ZERO;

                        for (let i = 0; i < stakersCount; i++) {
                            const bands = stakerBands[i];
                            const bandsCount = bands.length;

                            for (let j = 0; j < bandsCount; j++) {
                                const bandLevel = bands[j];

                                if (stakerTokensAreVested[i][j]) {
                                    stakeVestedFixed(
                                        stakers[i],
                                        bandLevel,
                                        bandIds[bandId],
                                        months[bandId + 1],
                                        monthsAfterInit[bandId + 1],
                                    );
                                } else {
                                    stakeStandardFixed(
                                        stakers[i],
                                        bandLevel,
                                        bandIds[bandId],
                                        months[bandId + 1],
                                        monthsAfterInit[bandId + 1],
                                    );
                                }
                                totalStaked = totalStaked.plus(bandLevelPrices[bandLevel.toI32() - 1]);
                                bandId++;
                            }
                        }
                    });

                    test("Should create new bands", () => {
                        assert.entityCount("Band", bandsCount);
                        for (let i = 0; i < bandsCount; i++) {
                            assert.fieldEquals("Band", ids[i], "id", ids[i]);
                        }
                    });

                    test("Should set band values correctly", () => {
                        let bandId = 0;

                        for (let i = 0; i < stakersCount; i++) {
                            const bands = stakerBands[i];
                            const stakerBandsCount = bands.length;

                            for (let j = 0; j < stakerBandsCount; j++) {
                                assert.fieldEquals("Band", ids[bandId], "owner", stakers[i].toHex());
                                assert.fieldEquals(
                                    "Band",
                                    ids[bandId],
                                    "stakingStartDate",
                                    monthsAfterInit[bandId + 1].toString(),
                                );
                                assert.fieldEquals("Band", ids[bandId], "bandLevel", bands[j].toString());
                                assert.fieldEquals(
                                    "Band",
                                    ids[bandId],
                                    "stakingType",
                                    stringifyStakingType(StakingType.FIX),
                                );
                                assert.fieldEquals("Band", ids[bandId], "fixedMonths", months[bandId + 1].toString());
                                assert.fieldEquals(
                                    "Band",
                                    ids[bandId],
                                    "areTokensVested",
                                    stakerTokensAreVested[i][j].toString(),
                                );

                                bandId++;
                            }
                        }
                    });

                    test("Should updated staking contract details", () => {
                        assert.fieldEquals("StakingContract", ids[0], "stakers", convertAddressArrayToString(stakers));
                        assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
                        assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
                    });

                    test("Should update staker details", () => {
                        let bandId = 0;

                        for (let i = 0; i < stakersCount; i++) {
                            const staker = stakers[i].toHex();
                            const bandsWithLevels = stakerBands[i];
                            const stakerBandsCount = bandsWithLevels.length;
                            const bands: BigInt[] = [];
                            let stakedAmount: BigInt = BIGINT_ZERO;

                            for (let j = 0; j < stakerBandsCount; j++) {
                                stakedAmount = stakedAmount.plus(bandLevelPrices[bandsWithLevels[j].toI32() - 1]);
                                bands.push(BigInt.fromI32(bandId));
                                bandId++;
                            }

                            assert.fieldEquals("Staker", staker, "fixedBands", convertBigIntArrayToString(bands));
                            assert.fieldEquals("Staker", staker, "flexiBands", "[]");
                            assert.fieldEquals("Staker", staker, "bandsCount", stakerBandsCount.toString());
                            assert.fieldEquals("Staker", staker, "stakedAmount", stakedAmount.toString());
                        }
                    });

                    describe("Shares calculations", () => {
                        test("Should set band shares", () => {
                            let bandId = 0;
                            for (let i = 0; i < stakersCount; i++) {
                                const bandsWithLevels = stakerBands[i];
                                const stakerBandsCount = bandsWithLevels.length;

                                for (let j = 0; j < stakerBandsCount; j++) {
                                    assert.fieldEquals(
                                        "Band",
                                        ids[bandId],
                                        "sharesAmount",
                                        sharesInMonths[bandId].toString(),
                                    );
                                }
                            }
                        });

                        test("Should set staker FIXED shares", () => {
                            for (let i = 0; i < stakersCount; i++) {
                                const staker = stakers[i].toHex();
                                assert.fieldEquals(
                                    "Staker",
                                    staker,
                                    "fixedSharesPerPool",
                                    convertBigIntArrayToString(allStakerFixedShares[i]),
                                );
                                assert.fieldEquals(
                                    "Staker",
                                    staker,
                                    "isolatedFixedSharesPerPool",
                                    convertBigIntArrayToString(allStakerIsolatedFixedShares[i]),
                                );
                            }
                        });

                        test("Should not set staker FLEXI shares", () => {
                            const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));
                            for (let i = 0; i < stakersCount; i++) {
                                const staker = stakers[i].toHex();
                                assert.fieldEquals("Staker", staker, "flexiSharesPerPool", stringifiedEmptyArray);
                                assert.fieldEquals(
                                    "Staker",
                                    staker,
                                    "isolatedFlexiSharesPerPool",
                                    stringifiedEmptyArray,
                                );
                            }
                        });

                        test("Should set pool FIXED shares", () => {
                            for (let i = 1; i <= totalPools.toI32(); i++) {
                                const totalFixedShares = allPoolTotalFixedShares[i - 1];
                                const totalIsolatedFixedShares = allPoolIsolatedFixedShares[i - 1];
                                assert.fieldEquals(
                                    "Pool",
                                    ids[i],
                                    "totalFixedSharesAmount",
                                    totalFixedShares.toString(),
                                );
                                assert.fieldEquals(
                                    "Pool",
                                    ids[i],
                                    "isolatedFixedSharesAmount",
                                    totalIsolatedFixedShares.toString(),
                                );
                            }
                        });

                        test("Should not set pool FLEXI shares", () => {
                            for (let i = 1; i <= totalPools.toI32(); i++) {
                                assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", "0");
                                assert.fieldEquals("Pool", ids[i], "isolatedFlexiSharesAmount", "0");
                            }
                        });
                    });
                });
            });
        });

        describe("Only FLEXI bands", () => {
            describe("Single type stakes (standard or vested)", () => {
                describe("9 stakers, each staker with different band levels", () => {
                    beforeAll(() => {
                        bandsCount = 9;
                        stakersCount = 9;

                        // Calculations for testing shares
                        allPoolTotalFlexiShares = createEmptyArray(totalPools);
                        allPoolIsolatedFlexiShares = createEmptyArray(totalPools);
                        allStakerFlexiShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);
                        allStakerIsolatedFlexiShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);

                        for (let i = 0; i < stakersCount; i++) {
                            const month = bandsCount - i - 1;
                            let shares = month > 0 ? sharesInMonths[month - 1] : BIGINT_ZERO;

                            allStakerIsolatedFlexiShares[i][i] = shares;
                            allPoolIsolatedFlexiShares[i] = allPoolIsolatedFlexiShares[i].plus(shares);

                            for (let j = 0; j < i + 1; j++) {
                                allStakerFlexiShares[i][j] = shares;
                                allPoolTotalFlexiShares[j] = allPoolTotalFlexiShares[j].plus(shares);
                            }
                        }
                    });

                    describe("Standard FLEXI bands", () => {
                        beforeAll(() => {
                            areTokensVested = false;
                        });

                        beforeEach(() => {
                            totalStaked = BIGINT_ZERO;

                            // Stake in all bands
                            for (let i = 0; i < totalBandLevels.toI32(); i++) {
                                stakeStandardFlexi(users[i], bandLevels[i], bandIds[i], monthsAfterInit[i + 1]);
                                totalStaked = totalStaked.plus(bandLevelPrices[i]);
                            }
                        });

                        test("Should create new bands", () => {
                            assert.entityCount("Band", bandsCount);
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "id", ids[i]);
                            }
                        });

                        test("Should set band values correctly", () => {
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "owner", users[i].toHex());
                                assert.fieldEquals(
                                    "Band",
                                    ids[i],
                                    "stakingStartDate",
                                    monthsAfterInit[i + 1].toString(),
                                );
                                assert.fieldEquals("Band", ids[i], "bandLevel", bandLevels[i].toString());
                                assert.fieldEquals(
                                    "Band",
                                    ids[i],
                                    "stakingType",
                                    stringifyStakingType(StakingType.FLEXI),
                                );
                                assert.fieldEquals("Band", ids[i], "fixedMonths", "0");
                                assert.fieldEquals("Band", ids[i], "areTokensVested", areTokensVested.toString());
                            }
                        });

                        test("Should updated staking contract details", () => {
                            assert.fieldEquals(
                                "StakingContract",
                                ids[0],
                                "stakers",
                                convertAddressArrayToString(users),
                            );
                            assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
                            assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
                        });

                        test("Should update staker details", () => {
                            for (let i = 0; i < stakersCount; i++) {
                                const staker = users[i].toHex();
                                const bands = `[${ids[i]}]`;

                                assert.fieldEquals("Staker", staker, "fixedBands", "[]");
                                assert.fieldEquals("Staker", staker, "flexiBands", bands);
                                assert.fieldEquals("Staker", staker, "bandsCount", "1");
                                assert.fieldEquals("Staker", staker, "stakedAmount", bandLevelPrices[i].toString());
                            }
                        });

                        describe("Shares calculations", () => {
                            test("Should set band shares", () => {
                                for (let i = 0; i < bandsCount; i++) {
                                    const month = bandsCount - i - 1;
                                    let shares = month > 0 ? sharesInMonths[month - 1] : BIGINT_ZERO;

                                    assert.fieldEquals("Band", ids[i], "sharesAmount", shares.toString());
                                }
                            });

                            test("Should set staker FLEXI shares", () => {
                                for (let i = 0; i < stakersCount; i++) {
                                    const staker = users[i].toHex();

                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "flexiSharesPerPool",
                                        convertBigIntArrayToString(allStakerFlexiShares[i]),
                                    );
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "isolatedFlexiSharesPerPool",
                                        convertBigIntArrayToString(allStakerIsolatedFlexiShares[i]),
                                    );
                                }
                            });

                            test("Should not set staker FIXED shares", () => {
                                const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));

                                for (let i = 0; i < stakersCount; i++) {
                                    const staker = users[i].toHex();
                                    assert.fieldEquals("Staker", staker, "fixedSharesPerPool", stringifiedEmptyArray);
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "isolatedFixedSharesPerPool",
                                        stringifiedEmptyArray,
                                    );
                                }
                            });

                            test("Should set pool FLEXI shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    const totalFlexiShares = allPoolTotalFlexiShares[i - 1];
                                    const totalIsolatedFlexiShares = allPoolIsolatedFlexiShares[i - 1];

                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "totalFlexiSharesAmount",
                                        totalFlexiShares.toString(),
                                    );
                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "isolatedFlexiSharesAmount",
                                        totalIsolatedFlexiShares.toString(),
                                    );
                                }
                            });

                            test("Should not set pool FIXED shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", "0");
                                    assert.fieldEquals("Pool", ids[i], "isolatedFixedSharesAmount", "0");
                                }
                            });
                        });
                    });

                    describe("Vested FLEXI bands", () => {
                        beforeAll(() => {
                            areTokensVested = true;
                        });

                        beforeEach(() => {
                            totalStaked = BIGINT_ZERO;

                            // Stake in all bands
                            for (let i = 0; i < totalBandLevels.toI32(); i++) {
                                stakeVestedFlexi(users[i], bandLevels[i], bandIds[i], monthsAfterInit[i + 1]);
                                totalStaked = totalStaked.plus(bandLevelPrices[i]);
                            }
                        });

                        test("Should create new bands", () => {
                            assert.entityCount("Band", bandsCount);
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "id", ids[i]);
                            }
                        });

                        test("Should set band values correctly", () => {
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "owner", users[i].toHex());
                                assert.fieldEquals(
                                    "Band",
                                    ids[i],
                                    "stakingStartDate",
                                    monthsAfterInit[i + 1].toString(),
                                );
                                assert.fieldEquals("Band", ids[i], "bandLevel", bandLevels[i].toString());
                                assert.fieldEquals(
                                    "Band",
                                    ids[i],
                                    "stakingType",
                                    stringifyStakingType(StakingType.FLEXI),
                                );
                                assert.fieldEquals("Band", ids[i], "fixedMonths", "0");
                                assert.fieldEquals("Band", ids[i], "areTokensVested", areTokensVested.toString());
                            }
                        });

                        test("Should updated staking contract details", () => {
                            assert.fieldEquals(
                                "StakingContract",
                                ids[0],
                                "stakers",
                                convertAddressArrayToString(users),
                            );
                            assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
                            assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
                        });

                        test("Should update staker details", () => {
                            for (let i = 0; i < stakersCount; i++) {
                                const staker = users[i].toHex();
                                const bands = `[${ids[i]}]`;

                                assert.fieldEquals("Staker", staker, "fixedBands", "[]");
                                assert.fieldEquals("Staker", staker, "flexiBands", bands);
                                assert.fieldEquals("Staker", staker, "bandsCount", "1");
                                assert.fieldEquals("Staker", staker, "stakedAmount", bandLevelPrices[i].toString());
                            }
                        });

                        describe("Shares calculations", () => {
                            test("Should set band shares", () => {
                                for (let i = 0; i < bandsCount; i++) {
                                    const month = bandsCount - i - 1;
                                    let shares = month > 0 ? sharesInMonths[month - 1] : BIGINT_ZERO;

                                    assert.fieldEquals("Band", ids[i], "sharesAmount", shares.toString());
                                }
                            });

                            test("Should set staker FLEXI shares", () => {
                                for (let i = 0; i < stakersCount; i++) {
                                    const staker = users[i].toHex();

                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "flexiSharesPerPool",
                                        convertBigIntArrayToString(allStakerFlexiShares[i]),
                                    );
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "isolatedFlexiSharesPerPool",
                                        convertBigIntArrayToString(allStakerIsolatedFlexiShares[i]),
                                    );
                                }
                            });

                            test("Should not set staker FIXED shares", () => {
                                const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));

                                for (let i = 0; i < stakersCount; i++) {
                                    const staker = users[i].toHex();
                                    assert.fieldEquals("Staker", staker, "fixedSharesPerPool", stringifiedEmptyArray);
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "isolatedFixedSharesPerPool",
                                        stringifiedEmptyArray,
                                    );
                                }
                            });

                            test("Should set pool FLEXI shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    const totalFlexiShares = allPoolTotalFlexiShares[i - 1];
                                    const totalIsolatedFlexiShares = allPoolIsolatedFlexiShares[i - 1];

                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "totalFlexiSharesAmount",
                                        totalFlexiShares.toString(),
                                    );
                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "isolatedFlexiSharesAmount",
                                        totalIsolatedFlexiShares.toString(),
                                    );
                                }
                            });

                            test("Should not set pool FIXED shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", "0");
                                    assert.fieldEquals("Pool", ids[i], "isolatedFixedSharesAmount", "0");
                                }
                            });
                        });
                    });
                });

                describe("1 staker with 9 bands, each band with different band levels", () => {
                    beforeAll(() => {
                        bandsCount = 9;
                        stakersCount = 1;

                        // Calculations for testing shares
                        allPoolTotalFlexiShares = createEmptyArray(totalPools);
                        allPoolIsolatedFlexiShares = createEmptyArray(totalPools);

                        for (let i = 0; i < bandsCount; i++) {
                            const month = bandsCount - i - 1;
                            let shares = month > 0 ? sharesInMonths[month - 1] : BIGINT_ZERO;

                            allPoolIsolatedFlexiShares[i] = allPoolIsolatedFlexiShares[i].plus(shares);

                            for (let j = 0; j < i + 1; j++) {
                                allPoolTotalFlexiShares[j] = allPoolTotalFlexiShares[j].plus(shares);
                            }
                        }
                    });

                    describe("Standard FLEXI bands", () => {
                        beforeAll(() => {
                            areTokensVested = false;
                        });

                        beforeEach(() => {
                            totalStaked = BIGINT_ZERO;

                            // Stake in all bands
                            for (let i = 0; i < totalBandLevels.toI32(); i++) {
                                stakeStandardFlexi(alice, bandLevels[i], bandIds[i], monthsAfterInit[i + 1]);
                                totalStaked = totalStaked.plus(bandLevelPrices[i]);
                            }
                        });

                        test("Should create new bands", () => {
                            assert.entityCount("Band", bandsCount);
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "id", ids[i]);
                            }
                        });

                        test("Should set band values correctly", () => {
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "owner", alice.toHex());
                                assert.fieldEquals(
                                    "Band",
                                    ids[i],
                                    "stakingStartDate",
                                    monthsAfterInit[i + 1].toString(),
                                );
                                assert.fieldEquals("Band", ids[i], "bandLevel", bandLevels[i].toString());
                                assert.fieldEquals(
                                    "Band",
                                    ids[i],
                                    "stakingType",
                                    stringifyStakingType(StakingType.FLEXI),
                                );
                                assert.fieldEquals("Band", ids[i], "fixedMonths", "0");
                                assert.fieldEquals("Band", ids[i], "areTokensVested", areTokensVested.toString());
                            }
                        });

                        test("Should updated staking contract details", () => {
                            const stakersArray = `[${alice.toHex()}]`;
                            assert.fieldEquals("StakingContract", ids[0], "stakers", stakersArray);
                            assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
                            assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
                        });

                        test("Should update staker details", () => {
                            const staker = alice.toHex();
                            const bands = createArray(BIGINT_ZERO, BigInt.fromI32(bandsCount - 1));
                            assert.fieldEquals("Staker", staker, "fixedBands", "[]");
                            assert.fieldEquals("Staker", staker, "flexiBands", convertBigIntArrayToString(bands));
                            assert.fieldEquals("Staker", staker, "bandsCount", "9");
                            assert.fieldEquals("Staker", staker, "stakedAmount", totalStaked.toString());
                        });

                        describe("Shares calculations", () => {
                            test("Should set band shares", () => {
                                for (let i = 0; i < bandsCount; i++) {
                                    const month = bandsCount - i - 1;
                                    let shares = month > 0 ? sharesInMonths[month - 1] : BIGINT_ZERO;

                                    assert.fieldEquals("Band", ids[i], "sharesAmount", shares.toString());
                                }
                            });

                            test("Should set staker FLEXI shares", () => {
                                const staker = alice.toHex();

                                assert.fieldEquals(
                                    "Staker",
                                    staker,
                                    "flexiSharesPerPool",
                                    convertBigIntArrayToString(allPoolTotalFlexiShares),
                                );
                                assert.fieldEquals(
                                    "Staker",
                                    staker,
                                    "isolatedFlexiSharesPerPool",
                                    convertBigIntArrayToString(allPoolIsolatedFlexiShares),
                                );
                            });

                            test("Should not set staker FIXED shares", () => {
                                const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));

                                for (let i = 0; i < stakersCount; i++) {
                                    const staker = users[i].toHex();
                                    assert.fieldEquals("Staker", staker, "fixedSharesPerPool", stringifiedEmptyArray);
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "isolatedFixedSharesPerPool",
                                        stringifiedEmptyArray,
                                    );
                                }
                            });

                            test("Should set pool FLEXI shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    const totalFlexiShares = allPoolTotalFlexiShares[i - 1];
                                    const totalIsolatedFlexiShares = allPoolIsolatedFlexiShares[i - 1];

                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "totalFlexiSharesAmount",
                                        totalFlexiShares.toString(),
                                    );
                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "isolatedFlexiSharesAmount",
                                        totalIsolatedFlexiShares.toString(),
                                    );
                                }
                            });

                            test("Should not set pool FIXED shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", "0");
                                    assert.fieldEquals("Pool", ids[i], "isolatedFixedSharesAmount", "0");
                                }
                            });
                        });
                    });

                    describe("Vested FLEXI bands", () => {
                        beforeAll(() => {
                            areTokensVested = true;
                        });

                        beforeEach(() => {
                            totalStaked = BIGINT_ZERO;

                            // Stake in all bands
                            for (let i = 0; i < totalBandLevels.toI32(); i++) {
                                stakeVestedFlexi(alice, bandLevels[i], bandIds[i], monthsAfterInit[i + 1]);
                                totalStaked = totalStaked.plus(bandLevelPrices[i]);
                            }
                        });

                        test("Should create new bands", () => {
                            assert.entityCount("Band", bandsCount);
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "id", ids[i]);
                            }
                        });

                        test("Should set band values correctly", () => {
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "owner", alice.toHex());
                                assert.fieldEquals(
                                    "Band",
                                    ids[i],
                                    "stakingStartDate",
                                    monthsAfterInit[i + 1].toString(),
                                );
                                assert.fieldEquals("Band", ids[i], "bandLevel", bandLevels[i].toString());
                                assert.fieldEquals(
                                    "Band",
                                    ids[i],
                                    "stakingType",
                                    stringifyStakingType(StakingType.FLEXI),
                                );
                                assert.fieldEquals("Band", ids[i], "fixedMonths", "0");
                                assert.fieldEquals("Band", ids[i], "areTokensVested", areTokensVested.toString());
                            }
                        });

                        test("Should updated staking contract details", () => {
                            const stakersArray = `[${alice.toHex()}]`;
                            assert.fieldEquals("StakingContract", ids[0], "stakers", stakersArray);
                            assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
                            assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
                        });

                        test("Should update staker details", () => {
                            const staker = alice.toHex();
                            const bands = createArray(BIGINT_ZERO, BigInt.fromI32(bandsCount - 1));
                            assert.fieldEquals("Staker", staker, "fixedBands", "[]");
                            assert.fieldEquals("Staker", staker, "flexiBands", convertBigIntArrayToString(bands));
                            assert.fieldEquals("Staker", staker, "bandsCount", "9");
                            assert.fieldEquals("Staker", staker, "stakedAmount", totalStaked.toString());
                        });

                        describe("Shares calculations", () => {
                            test("Should set band shares", () => {
                                for (let i = 0; i < bandsCount; i++) {
                                    const month = bandsCount - i - 1;
                                    let shares = month > 0 ? sharesInMonths[month - 1] : BIGINT_ZERO;

                                    assert.fieldEquals("Band", ids[i], "sharesAmount", shares.toString());
                                }
                            });

                            test("Should set staker FLEXI shares", () => {
                                const staker = alice.toHex();

                                assert.fieldEquals(
                                    "Staker",
                                    staker,
                                    "flexiSharesPerPool",
                                    convertBigIntArrayToString(allPoolTotalFlexiShares),
                                );
                                assert.fieldEquals(
                                    "Staker",
                                    staker,
                                    "isolatedFlexiSharesPerPool",
                                    convertBigIntArrayToString(allPoolIsolatedFlexiShares),
                                );
                            });

                            test("Should not set staker FIXED shares", () => {
                                const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));

                                for (let i = 0; i < stakersCount; i++) {
                                    const staker = users[i].toHex();
                                    assert.fieldEquals("Staker", staker, "fixedSharesPerPool", stringifiedEmptyArray);
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "isolatedFixedSharesPerPool",
                                        stringifiedEmptyArray,
                                    );
                                }
                            });

                            test("Should set pool FLEXI shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    const totalFlexiShares = allPoolTotalFlexiShares[i - 1];
                                    const totalIsolatedFlexiShares = allPoolIsolatedFlexiShares[i - 1];

                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "totalFlexiSharesAmount",
                                        totalFlexiShares.toString(),
                                    );
                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "isolatedFlexiSharesAmount",
                                        totalIsolatedFlexiShares.toString(),
                                    );
                                }
                            });

                            test("Should not set pool FIXED shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", "0");
                                    assert.fieldEquals("Pool", ids[i], "isolatedFixedSharesAmount", "0");
                                }
                            });
                        });
                    });
                });

                describe("4 stakers, 8 bands, all random stakes", () => {
                    beforeAll(() => {
                        bandsCount = 8;
                        stakersCount = 4;
                        stakers = [alice, bob, charlie, dan];
                        stakerBands = [
                            [bandLevels[0]],
                            [bandLevels[3], bandLevels[1], bandLevels[1]],
                            [bandLevels[3], bandLevels[7], bandLevels[5]],
                            [bandLevels[8]],
                        ];

                        // Calculations for testing shares
                        allPoolTotalFlexiShares = createEmptyArray(totalPools);
                        allPoolIsolatedFlexiShares = createEmptyArray(totalPools);
                        allStakerFlexiShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);
                        allStakerIsolatedFlexiShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);

                        let bandId = 0;
                        for (let i = 0; i < stakersCount; i++) {
                            const bands = stakerBands[i];
                            const stakerBandsCount = bands.length;

                            for (let j = 0; j < stakerBandsCount; j++) {
                                const month = bandsCount - bandId - 1;
                                let shares = month > 0 ? sharesInMonths[month - 1] : BIGINT_ZERO;

                                const bandLevel = bands[j].toI32() - 1;

                                allStakerIsolatedFlexiShares[i][bandLevel] =
                                    allStakerIsolatedFlexiShares[i][bandLevel].plus(shares);
                                allPoolIsolatedFlexiShares[bandLevel] =
                                    allPoolIsolatedFlexiShares[bandLevel].plus(shares);

                                for (let k = 0; k < bandLevel + 1; k++) {
                                    allStakerFlexiShares[i][k] = allStakerFlexiShares[i][k].plus(shares);
                                    allPoolTotalFlexiShares[k] = allPoolTotalFlexiShares[k].plus(shares);
                                }

                                bandId++;
                            }
                        }
                    });

                    describe("Standard FLEXI bands", () => {
                        beforeAll(() => {
                            areTokensVested = false;
                        });

                        beforeEach(() => {
                            let bandId = 0;
                            totalStaked = BIGINT_ZERO;

                            for (let i = 0; i < stakersCount; i++) {
                                const bands = stakerBands[i];
                                const bandsCount = bands.length;

                                for (let j = 0; j < bandsCount; j++) {
                                    const bandLevel = bands[j];

                                    stakeStandardFlexi(
                                        stakers[i],
                                        bandLevel,
                                        bandIds[bandId],
                                        monthsAfterInit[bandId + 1],
                                    );
                                    totalStaked = totalStaked.plus(bandLevelPrices[bandLevel.toI32() - 1]);
                                    bandId++;
                                }
                            }
                        });

                        test("Should create new bands", () => {
                            assert.entityCount("Band", bandsCount);
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "id", ids[i]);
                            }
                        });

                        test("Should set band values correctly", () => {
                            let bandId = 0;

                            for (let i = 0; i < stakersCount; i++) {
                                const bands = stakerBands[i];
                                const stakerBandsCount = bands.length;

                                for (let j = 0; j < stakerBandsCount; j++) {
                                    assert.fieldEquals("Band", ids[bandId], "owner", stakers[i].toHex());
                                    assert.fieldEquals(
                                        "Band",
                                        ids[bandId],
                                        "stakingStartDate",
                                        monthsAfterInit[bandId + 1].toString(),
                                    );
                                    assert.fieldEquals("Band", ids[bandId], "bandLevel", bands[j].toString());
                                    assert.fieldEquals(
                                        "Band",
                                        ids[bandId],
                                        "stakingType",
                                        stringifyStakingType(StakingType.FLEXI),
                                    );
                                    assert.fieldEquals("Band", ids[bandId], "fixedMonths", "0");
                                    assert.fieldEquals(
                                        "Band",
                                        ids[bandId],
                                        "areTokensVested",
                                        areTokensVested.toString(),
                                    );

                                    bandId++;
                                }
                            }
                        });

                        test("Should updated staking contract details", () => {
                            assert.fieldEquals(
                                "StakingContract",
                                ids[0],
                                "stakers",
                                convertAddressArrayToString(stakers),
                            );
                            assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
                            assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
                        });

                        test("Should update staker details", () => {
                            let bandId = 0;

                            for (let i = 0; i < stakersCount; i++) {
                                const staker = stakers[i].toHex();
                                const bandsWithLevels = stakerBands[i];
                                const stakerBandsCount = bandsWithLevels.length;
                                const bands: BigInt[] = [];
                                let stakedAmount: BigInt = BIGINT_ZERO;

                                for (let j = 0; j < stakerBandsCount; j++) {
                                    stakedAmount = stakedAmount.plus(bandLevelPrices[bandsWithLevels[j].toI32() - 1]);
                                    bands.push(BigInt.fromI32(bandId));
                                    bandId++;
                                }

                                assert.fieldEquals("Staker", staker, "fixedBands", "[]");
                                assert.fieldEquals("Staker", staker, "flexiBands", convertBigIntArrayToString(bands));
                                assert.fieldEquals("Staker", staker, "bandsCount", stakerBandsCount.toString());
                                assert.fieldEquals("Staker", staker, "stakedAmount", stakedAmount.toString());
                            }
                        });

                        describe("Shares calculations", () => {
                            test("Should set band shares", () => {
                                let bandId = 0;
                                for (let i = 0; i < stakersCount; i++) {
                                    const bandsWithLevels = stakerBands[i];
                                    const stakerBandsCount = bandsWithLevels.length;

                                    for (let j = 0; j < stakerBandsCount; j++) {
                                        const month = bandsCount - bandId - 1;
                                        let shares = month > 0 ? sharesInMonths[month - 1] : BIGINT_ZERO;

                                        assert.fieldEquals("Band", ids[bandId], "sharesAmount", shares.toString());

                                        bandId++;
                                    }
                                }
                            });

                            test("Should set staker FLEXI shares", () => {
                                for (let i = 0; i < stakersCount; i++) {
                                    const staker = stakers[i].toHex();
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "flexiSharesPerPool",
                                        convertBigIntArrayToString(allStakerFlexiShares[i]),
                                    );
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "isolatedFlexiSharesPerPool",
                                        convertBigIntArrayToString(allStakerIsolatedFlexiShares[i]),
                                    );
                                }
                            });

                            test("Should not set staker FIXED shares", () => {
                                const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));
                                for (let i = 0; i < stakersCount; i++) {
                                    const staker = stakers[i].toHex();
                                    assert.fieldEquals("Staker", staker, "fixedSharesPerPool", stringifiedEmptyArray);
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "isolatedFixedSharesPerPool",
                                        stringifiedEmptyArray,
                                    );
                                }
                            });

                            test("Should set pool FLEXI shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    const totalFlexiShares = allPoolTotalFlexiShares[i - 1];
                                    const totalIsolatedFlexiShares = allPoolIsolatedFlexiShares[i - 1];
                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "totalFlexiSharesAmount",
                                        totalFlexiShares.toString(),
                                    );
                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "isolatedFlexiSharesAmount",
                                        totalIsolatedFlexiShares.toString(),
                                    );
                                }
                            });

                            test("Should not set pool FIXED shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", "0");
                                    assert.fieldEquals("Pool", ids[i], "isolatedFixedSharesAmount", "0");
                                }
                            });
                        });
                    });

                    describe("Vested FLEXI bands", () => {
                        beforeAll(() => {
                            areTokensVested = true;
                        });

                        beforeEach(() => {
                            let bandId = 0;
                            totalStaked = BIGINT_ZERO;

                            for (let i = 0; i < stakersCount; i++) {
                                const bands = stakerBands[i];
                                const bandsCount = bands.length;

                                for (let j = 0; j < bandsCount; j++) {
                                    const bandLevel = bands[j];

                                    stakeVestedFlexi(
                                        stakers[i],
                                        bandLevel,
                                        bandIds[bandId],
                                        monthsAfterInit[bandId + 1],
                                    );
                                    totalStaked = totalStaked.plus(bandLevelPrices[bandLevel.toI32() - 1]);
                                    bandId++;
                                }
                            }
                        });

                        test("Should create new bands", () => {
                            assert.entityCount("Band", bandsCount);
                            for (let i = 0; i < bandsCount; i++) {
                                assert.fieldEquals("Band", ids[i], "id", ids[i]);
                            }
                        });

                        test("Should set band values correctly", () => {
                            let bandId = 0;

                            for (let i = 0; i < stakersCount; i++) {
                                const bands = stakerBands[i];
                                const stakerBandsCount = bands.length;

                                for (let j = 0; j < stakerBandsCount; j++) {
                                    assert.fieldEquals("Band", ids[bandId], "owner", stakers[i].toHex());
                                    assert.fieldEquals(
                                        "Band",
                                        ids[bandId],
                                        "stakingStartDate",
                                        monthsAfterInit[bandId + 1].toString(),
                                    );
                                    assert.fieldEquals("Band", ids[bandId], "bandLevel", bands[j].toString());
                                    assert.fieldEquals(
                                        "Band",
                                        ids[bandId],
                                        "stakingType",
                                        stringifyStakingType(StakingType.FLEXI),
                                    );
                                    assert.fieldEquals("Band", ids[bandId], "fixedMonths", "0");
                                    assert.fieldEquals(
                                        "Band",
                                        ids[bandId],
                                        "areTokensVested",
                                        areTokensVested.toString(),
                                    );

                                    bandId++;
                                }
                            }
                        });

                        test("Should updated staking contract details", () => {
                            assert.fieldEquals(
                                "StakingContract",
                                ids[0],
                                "stakers",
                                convertAddressArrayToString(stakers),
                            );
                            assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
                            assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
                        });

                        test("Should update staker details", () => {
                            let bandId = 0;

                            for (let i = 0; i < stakersCount; i++) {
                                const staker = stakers[i].toHex();
                                const bandsWithLevels = stakerBands[i];
                                const stakerBandsCount = bandsWithLevels.length;
                                const bands: BigInt[] = [];
                                let stakedAmount: BigInt = BIGINT_ZERO;

                                for (let j = 0; j < stakerBandsCount; j++) {
                                    stakedAmount = stakedAmount.plus(bandLevelPrices[bandsWithLevels[j].toI32() - 1]);
                                    bands.push(BigInt.fromI32(bandId));
                                    bandId++;
                                }

                                assert.fieldEquals("Staker", staker, "fixedBands", "[]");
                                assert.fieldEquals("Staker", staker, "flexiBands", convertBigIntArrayToString(bands));
                                assert.fieldEquals("Staker", staker, "bandsCount", stakerBandsCount.toString());
                                assert.fieldEquals("Staker", staker, "stakedAmount", stakedAmount.toString());
                            }
                        });

                        describe("Shares calculations", () => {
                            test("Should set band shares", () => {
                                let bandId = 0;
                                for (let i = 0; i < stakersCount; i++) {
                                    const bandsWithLevels = stakerBands[i];
                                    const stakerBandsCount = bandsWithLevels.length;

                                    for (let j = 0; j < stakerBandsCount; j++) {
                                        const month = bandsCount - bandId - 1;
                                        let shares = month > 0 ? sharesInMonths[month - 1] : BIGINT_ZERO;

                                        assert.fieldEquals("Band", ids[bandId], "sharesAmount", shares.toString());

                                        bandId++;
                                    }
                                }
                            });

                            test("Should set staker FLEXI shares", () => {
                                for (let i = 0; i < stakersCount; i++) {
                                    const staker = stakers[i].toHex();
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "flexiSharesPerPool",
                                        convertBigIntArrayToString(allStakerFlexiShares[i]),
                                    );
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "isolatedFlexiSharesPerPool",
                                        convertBigIntArrayToString(allStakerIsolatedFlexiShares[i]),
                                    );
                                }
                            });

                            test("Should not set staker FIXED shares", () => {
                                const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));
                                for (let i = 0; i < stakersCount; i++) {
                                    const staker = stakers[i].toHex();
                                    assert.fieldEquals("Staker", staker, "fixedSharesPerPool", stringifiedEmptyArray);
                                    assert.fieldEquals(
                                        "Staker",
                                        staker,
                                        "isolatedFixedSharesPerPool",
                                        stringifiedEmptyArray,
                                    );
                                }
                            });

                            test("Should set pool FLEXI shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    const totalFlexiShares = allPoolTotalFlexiShares[i - 1];
                                    const totalIsolatedFlexiShares = allPoolIsolatedFlexiShares[i - 1];
                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "totalFlexiSharesAmount",
                                        totalFlexiShares.toString(),
                                    );
                                    assert.fieldEquals(
                                        "Pool",
                                        ids[i],
                                        "isolatedFlexiSharesAmount",
                                        totalIsolatedFlexiShares.toString(),
                                    );
                                }
                            });

                            test("Should not set pool FIXED shares", () => {
                                for (let i = 1; i <= totalPools.toI32(); i++) {
                                    assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", "0");
                                    assert.fieldEquals("Pool", ids[i], "isolatedFixedSharesAmount", "0");
                                }
                            });
                        });
                    });
                });
            });

            describe("Mixed FLEXI bands (standard and vested)", () => {
                describe("4 stakers, 4 vested stakes + 4 standard stakes", () => {
                    beforeAll(() => {
                        bandsCount = 8;
                        stakersCount = 4;
                        stakers = [alice, bob, charlie, dan];
                        stakerBands = [
                            [bandLevels[0]],
                            [bandLevels[3], bandLevels[1], bandLevels[1]],
                            [bandLevels[3], bandLevels[7], bandLevels[5]],
                            [bandLevels[8]],
                        ];
                        stakerTokensAreVested = [[true], [false, false, true], [true, true, false], [false]];

                        // Calculations for testing shares
                        allPoolTotalFlexiShares = createEmptyArray(totalPools);
                        allPoolIsolatedFlexiShares = createEmptyArray(totalPools);
                        allStakerFlexiShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);
                        allStakerIsolatedFlexiShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);

                        let bandId = 0;
                        for (let i = 0; i < stakersCount; i++) {
                            const bands = stakerBands[i];
                            const stakerBandsCount = bands.length;

                            for (let j = 0; j < stakerBandsCount; j++) {
                                const month = bandsCount - bandId - 1;
                                let shares = month > 0 ? sharesInMonths[month - 1] : BIGINT_ZERO;

                                const bandLevel = bands[j].toI32() - 1;

                                allStakerIsolatedFlexiShares[i][bandLevel] =
                                    allStakerIsolatedFlexiShares[i][bandLevel].plus(shares);
                                allPoolIsolatedFlexiShares[bandLevel] =
                                    allPoolIsolatedFlexiShares[bandLevel].plus(shares);

                                for (let k = 0; k < bandLevel + 1; k++) {
                                    allStakerFlexiShares[i][k] = allStakerFlexiShares[i][k].plus(shares);
                                    allPoolTotalFlexiShares[k] = allPoolTotalFlexiShares[k].plus(shares);
                                }

                                bandId++;
                            }
                        }
                    });

                    beforeEach(() => {
                        let bandId = 0;
                        totalStaked = BIGINT_ZERO;

                        for (let i = 0; i < stakersCount; i++) {
                            const bands = stakerBands[i];
                            const stakerBandsCount = bands.length;

                            for (let j = 0; j < stakerBandsCount; j++) {
                                const bandLevel = bands[j];

                                if (stakerTokensAreVested[i][j]) {
                                    stakeVestedFlexi(
                                        stakers[i],
                                        bandLevel,
                                        bandIds[bandId],
                                        monthsAfterInit[bandId + 1],
                                    );
                                } else {
                                    stakeStandardFlexi(
                                        stakers[i],
                                        bandLevel,
                                        bandIds[bandId],
                                        monthsAfterInit[bandId + 1],
                                    );
                                }
                                totalStaked = totalStaked.plus(bandLevelPrices[bandLevel.toI32() - 1]);
                                bandId++;
                            }
                        }
                    });

                    test("Should create new bands", () => {
                        assert.entityCount("Band", bandsCount);
                        for (let i = 0; i < bandsCount; i++) {
                            assert.fieldEquals("Band", ids[i], "id", ids[i]);
                        }
                    });

                    test("Should set band values correctly", () => {
                        let bandId = 0;

                        for (let i = 0; i < stakersCount; i++) {
                            const bands = stakerBands[i];
                            const stakerBandsCount = bands.length;

                            for (let j = 0; j < stakerBandsCount; j++) {
                                assert.fieldEquals("Band", ids[bandId], "owner", stakers[i].toHex());
                                assert.fieldEquals(
                                    "Band",
                                    ids[bandId],
                                    "stakingStartDate",
                                    monthsAfterInit[bandId + 1].toString(),
                                );
                                assert.fieldEquals("Band", ids[bandId], "bandLevel", bands[j].toString());
                                assert.fieldEquals(
                                    "Band",
                                    ids[bandId],
                                    "stakingType",
                                    stringifyStakingType(StakingType.FLEXI),
                                );
                                assert.fieldEquals("Band", ids[bandId], "fixedMonths", "0");
                                assert.fieldEquals(
                                    "Band",
                                    ids[bandId],
                                    "areTokensVested",
                                    stakerTokensAreVested[i][j].toString(),
                                );

                                bandId++;
                            }
                        }
                    });

                    test("Should updated staking contract details", () => {
                        assert.fieldEquals("StakingContract", ids[0], "stakers", convertAddressArrayToString(stakers));
                        assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
                        assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
                    });

                    test("Should update staker details", () => {
                        let bandId = 0;

                        for (let i = 0; i < stakersCount; i++) {
                            const staker = stakers[i].toHex();
                            const bandsWithLevels = stakerBands[i];
                            const stakerBandsCount = bandsWithLevels.length;
                            const bands: BigInt[] = [];
                            let stakedAmount: BigInt = BIGINT_ZERO;

                            for (let j = 0; j < stakerBandsCount; j++) {
                                stakedAmount = stakedAmount.plus(bandLevelPrices[bandsWithLevels[j].toI32() - 1]);
                                bands.push(BigInt.fromI32(bandId));
                                bandId++;
                            }

                            assert.fieldEquals("Staker", staker, "fixedBands", "[]");
                            assert.fieldEquals("Staker", staker, "flexiBands", convertBigIntArrayToString(bands));
                            assert.fieldEquals("Staker", staker, "bandsCount", stakerBandsCount.toString());
                            assert.fieldEquals("Staker", staker, "stakedAmount", stakedAmount.toString());
                        }
                    });

                    describe("Shares calculations", () => {
                        test("Should set band shares", () => {
                            let bandId = 0;
                            for (let i = 0; i < stakersCount; i++) {
                                const bandsWithLevels = stakerBands[i];
                                const stakerBandsCount = bandsWithLevels.length;

                                for (let j = 0; j < stakerBandsCount; j++) {
                                    const month = bandsCount - bandId - 1;
                                    let shares = month > 0 ? sharesInMonths[month - 1] : BIGINT_ZERO;

                                    assert.fieldEquals("Band", ids[bandId], "sharesAmount", shares.toString());

                                    bandId++;
                                }
                            }
                        });

                        test("Should set staker FLEXI shares", () => {
                            for (let i = 0; i < stakersCount; i++) {
                                const staker = stakers[i].toHex();
                                assert.fieldEquals(
                                    "Staker",
                                    staker,
                                    "flexiSharesPerPool",
                                    convertBigIntArrayToString(allStakerFlexiShares[i]),
                                );
                                assert.fieldEquals(
                                    "Staker",
                                    staker,
                                    "isolatedFlexiSharesPerPool",
                                    convertBigIntArrayToString(allStakerIsolatedFlexiShares[i]),
                                );
                            }
                        });

                        test("Should not set staker FIXED shares", () => {
                            const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));
                            for (let i = 0; i < stakersCount; i++) {
                                const staker = stakers[i].toHex();
                                assert.fieldEquals("Staker", staker, "fixedSharesPerPool", stringifiedEmptyArray);
                                assert.fieldEquals(
                                    "Staker",
                                    staker,
                                    "isolatedFixedSharesPerPool",
                                    stringifiedEmptyArray,
                                );
                            }
                        });

                        test("Should set pool FLEXI shares", () => {
                            for (let i = 1; i <= totalPools.toI32(); i++) {
                                const totalFlexiShares = allPoolTotalFlexiShares[i - 1];
                                const totalIsolatedFlexiShares = allPoolIsolatedFlexiShares[i - 1];
                                assert.fieldEquals(
                                    "Pool",
                                    ids[i],
                                    "totalFlexiSharesAmount",
                                    totalFlexiShares.toString(),
                                );
                                assert.fieldEquals(
                                    "Pool",
                                    ids[i],
                                    "isolatedFlexiSharesAmount",
                                    totalIsolatedFlexiShares.toString(),
                                );
                            }
                        });

                        test("Should not set pool FIXED shares", () => {
                            for (let i = 1; i <= totalPools.toI32(); i++) {
                                assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", "0");
                                assert.fieldEquals("Pool", ids[i], "isolatedFixedSharesAmount", "0");
                            }
                        });
                    });
                });
            });
        });

        describe("All Mixed bands", () => {
            describe("4 stakers, 8 bands (4 vested stakes + 4 standard stakes, 4 FIXED + 4 FLEXI) (all types)", () => {
                beforeAll(() => {
                    bandsCount = 8;
                    stakersCount = 4;
                    stakers = [alice, bob, charlie, dan];
                    stakerBands = [
                        [bandLevels[0]],
                        [bandLevels[3], bandLevels[1], bandLevels[1]],
                        [bandLevels[3], bandLevels[7], bandLevels[5]],
                        [bandLevels[8]],
                    ];
                    stakerTokensAreVested = [[true], [false, true, false], [false, true, true], [false]];
                    stakerBandsTypes = [
                        [StakingType.FIX],
                        [StakingType.FLEXI, StakingType.FIX, StakingType.FIX],
                        [StakingType.FLEXI, StakingType.FLEXI, StakingType.FIX],
                        [StakingType.FLEXI],
                    ];

                    // Calculations for testing shares
                    allPoolTotalFlexiShares = createEmptyArray(totalPools);
                    allPoolIsolatedFlexiShares = createEmptyArray(totalPools);
                    allStakerFlexiShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);
                    allStakerIsolatedFlexiShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);

                    allPoolTotalFixedShares = createEmptyArray(totalPools);
                    allPoolIsolatedFixedShares = createEmptyArray(totalPools);
                    allStakerFixedShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);
                    allStakerIsolatedFixedShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);

                    let bandId = 0;
                    for (let i = 0; i < stakersCount; i++) {
                        const bands = stakerBands[i];
                        const stakerBandsCount = bands.length;

                        for (let j = 0; j < stakerBandsCount; j++) {
                            const bandLevel = bands[j].toI32() - 1;

                            if (stakerBandsTypes[i][j] === StakingType.FLEXI) {
                                const month = bandsCount - bandId - 1;
                                let shares = month > 0 ? sharesInMonths[month - 1] : BIGINT_ZERO;

                                allStakerIsolatedFlexiShares[i][bandLevel] =
                                    allStakerIsolatedFlexiShares[i][bandLevel].plus(shares);
                                allPoolIsolatedFlexiShares[bandLevel] =
                                    allPoolIsolatedFlexiShares[bandLevel].plus(shares);

                                for (let k = 0; k < bandLevel + 1; k++) {
                                    allStakerFlexiShares[i][k] = allStakerFlexiShares[i][k].plus(shares);
                                    allPoolTotalFlexiShares[k] = allPoolTotalFlexiShares[k].plus(shares);
                                }
                            } else {
                                const shares = sharesInMonths[bandId];

                                allStakerIsolatedFixedShares[i][bandLevel] =
                                    allStakerIsolatedFixedShares[i][bandLevel].plus(shares);
                                allPoolIsolatedFixedShares[bandLevel] =
                                    allPoolIsolatedFixedShares[bandLevel].plus(shares);

                                for (let k = 0; k < bandLevel + 1; k++) {
                                    allStakerFixedShares[i][k] = allStakerFixedShares[i][k].plus(shares);
                                    allPoolTotalFixedShares[k] = allPoolTotalFixedShares[k].plus(shares);
                                }
                            }

                            bandId++;
                        }
                    }
                });

                beforeEach(() => {
                    let bandId = 0;
                    totalStaked = BIGINT_ZERO;

                    for (let i = 0; i < stakersCount; i++) {
                        const staker = stakers[i];
                        const bands = stakerBands[i];
                        const stakerBandsCount = bands.length;

                        for (let j = 0; j < stakerBandsCount; j++) {
                            const bandLevel = bands[j];
                            const id = bandIds[bandId];
                            const date = monthsAfterInit[bandId + 1];
                            const month = months[bandId + 1];

                            if (stakerTokensAreVested[i][j]) {
                                if (stakerBandsTypes[i][j] === StakingType.FLEXI) {
                                    stakeVestedFlexi(staker, bandLevel, id, date);
                                } else {
                                    stakeVestedFixed(staker, bandLevel, id, month, date);
                                }
                            } else {
                                if (stakerBandsTypes[i][j] === StakingType.FLEXI) {
                                    stakeStandardFlexi(staker, bandLevel, id, date);
                                } else {
                                    stakeStandardFixed(staker, bandLevel, id, month, date);
                                }
                            }
                            totalStaked = totalStaked.plus(bandLevelPrices[bandLevel.toI32() - 1]);
                            bandId++;
                        }
                    }
                });

                test("Should create new bands", () => {
                    assert.entityCount("Band", bandsCount);
                    for (let i = 0; i < bandsCount; i++) {
                        assert.fieldEquals("Band", ids[i], "id", ids[i]);
                    }
                });

                test("Should set band values correctly", () => {
                    let bandId = 0;

                    for (let i = 0; i < stakersCount; i++) {
                        const bands = stakerBands[i];
                        const stakerBandsCount = bands.length;

                        for (let j = 0; j < stakerBandsCount; j++) {
                            const fixedMonth =
                                stakerBandsTypes[i][j] === StakingType.FLEXI ? "0" : months[bandId + 1].toString();

                            assert.fieldEquals("Band", ids[bandId], "owner", stakers[i].toHex());
                            assert.fieldEquals(
                                "Band",
                                ids[bandId],
                                "stakingStartDate",
                                monthsAfterInit[bandId + 1].toString(),
                            );
                            assert.fieldEquals("Band", ids[bandId], "bandLevel", bands[j].toString());
                            assert.fieldEquals(
                                "Band",
                                ids[bandId],
                                "stakingType",
                                stringifyStakingType(stakerBandsTypes[i][j]),
                            );
                            assert.fieldEquals("Band", ids[bandId], "fixedMonths", fixedMonth);
                            assert.fieldEquals(
                                "Band",
                                ids[bandId],
                                "areTokensVested",
                                stakerTokensAreVested[i][j].toString(),
                            );

                            bandId++;
                        }
                    }
                });

                test("Should updated staking contract details", () => {
                    assert.fieldEquals("StakingContract", ids[0], "stakers", convertAddressArrayToString(stakers));
                    assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
                    assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
                });

                test("Should update staker details", () => {
                    let bandId = 0;

                    for (let i = 0; i < stakersCount; i++) {
                        const staker = stakers[i].toHex();
                        const bandsWithLevels = stakerBands[i];
                        const stakerBandsCount = bandsWithLevels.length;
                        const fixedBands: BigInt[] = [];
                        const flexiBands: BigInt[] = [];
                        let stakedAmount: BigInt = BIGINT_ZERO;

                        for (let j = 0; j < stakerBandsCount; j++) {
                            stakedAmount = stakedAmount.plus(bandLevelPrices[bandsWithLevels[j].toI32() - 1]);

                            if (stakerBandsTypes[i][j] === StakingType.FIX) {
                                fixedBands.push(BigInt.fromI32(bandId));
                            } else {
                                flexiBands.push(BigInt.fromI32(bandId));
                            }
                            bandId++;
                        }

                        assert.fieldEquals("Staker", staker, "fixedBands", convertBigIntArrayToString(fixedBands));
                        assert.fieldEquals("Staker", staker, "flexiBands", convertBigIntArrayToString(flexiBands));
                        assert.fieldEquals("Staker", staker, "bandsCount", stakerBandsCount.toString());
                        assert.fieldEquals("Staker", staker, "stakedAmount", stakedAmount.toString());
                    }
                });

                describe("Shares calculations", () => {
                    test("Should set band shares", () => {
                        let bandId = 0;
                        for (let i = 0; i < stakersCount; i++) {
                            const bandsWithLevels = stakerBands[i];
                            const stakerBandsCount = bandsWithLevels.length;

                            for (let j = 0; j < stakerBandsCount; j++) {
                                let shares: BigInt = BIGINT_ZERO;
                                if (stakerBandsTypes[i][j] === StakingType.FLEXI) {
                                    const month = bandsCount - bandId - 1;
                                    shares = month > 0 ? sharesInMonths[month - 1] : BIGINT_ZERO;
                                } else {
                                    shares = sharesInMonths[bandId];
                                }
                                assert.fieldEquals("Band", ids[bandId], "sharesAmount", shares.toString());

                                bandId++;
                            }
                        }
                    });

                    test("Should set staker FLEXI shares", () => {
                        for (let i = 0; i < stakersCount; i++) {
                            const staker = stakers[i].toHex();
                            assert.fieldEquals(
                                "Staker",
                                staker,
                                "flexiSharesPerPool",
                                convertBigIntArrayToString(allStakerFlexiShares[i]),
                            );
                            assert.fieldEquals(
                                "Staker",
                                staker,
                                "isolatedFlexiSharesPerPool",
                                convertBigIntArrayToString(allStakerIsolatedFlexiShares[i]),
                            );
                        }
                    });

                    test("Should set staker FIXED shares", () => {
                        for (let i = 0; i < stakersCount; i++) {
                            const staker = stakers[i].toHex();
                            assert.fieldEquals(
                                "Staker",
                                staker,
                                "fixedSharesPerPool",
                                convertBigIntArrayToString(allStakerFixedShares[i]),
                            );
                            assert.fieldEquals(
                                "Staker",
                                staker,
                                "isolatedFixedSharesPerPool",
                                convertBigIntArrayToString(allStakerIsolatedFixedShares[i]),
                            );
                        }
                    });

                    test("Should set pool FLEXI shares", () => {
                        for (let i = 1; i <= totalPools.toI32(); i++) {
                            const totalFlexiShares = allPoolTotalFlexiShares[i - 1];
                            const totalIsolatedFlexiShares = allPoolIsolatedFlexiShares[i - 1];
                            assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", totalFlexiShares.toString());
                            assert.fieldEquals(
                                "Pool",
                                ids[i],
                                "isolatedFlexiSharesAmount",
                                totalIsolatedFlexiShares.toString(),
                            );
                        }
                    });

                    test("Should set pool FIXED shares", () => {
                        for (let i = 1; i <= totalPools.toI32(); i++) {
                            const totalFlexiShares = allPoolTotalFixedShares[i - 1];
                            const totalIsolatedFlexiShares = allPoolIsolatedFixedShares[i - 1];
                            assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", totalFlexiShares.toString());
                            assert.fieldEquals(
                                "Pool",
                                ids[i],
                                "isolatedFixedSharesAmount",
                                totalIsolatedFlexiShares.toString(),
                            );
                        }
                    });
                });
            });
        });
    });
});
