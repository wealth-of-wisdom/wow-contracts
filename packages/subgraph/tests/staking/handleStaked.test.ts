import { Address, BigInt, Bytes, log } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, beforeAll, afterEach, clearStore, assert } from "matchstick-as/assembly/index";
import {
    initializeAndSetUp,
    stakeStandardFixed,
    stakeStandardFlexi,
    stakeVestedFixed,
    stakeVestedFlexi,
} from "./helpers/helper";
import { ids, bandIds, alice, bob, charlie, users, totalPools, totalBandLevels, dan } from "../utils/data/constants";
import { initDate, monthsAfterInit } from "../utils/data/dates";
import { sharesInMonths, bandLevels, months, bandLevelPrices } from "../utils/data/data";
import {
    convertAddressArrayToString,
    convertBigIntArrayToString,
    createArray,
    createArrayWithMultiplication,
    createDoubleEmptyArray,
    createEmptyArray,
} from "../utils/arrays";
import { stringifyStakingType } from "../../src/utils/utils";
import { BIGDEC_ZERO, BIGINT_TWO, BIGINT_ZERO, StakingType } from "../../src/utils/constants";
import { getOrInitBand } from "../../src/helpers/staking.helpers";

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

    // describe("Simple cases", () => {
    //     afterEach(() => {
    //         // This helps to debug the tests
    //         log.debug("Stakers: {}, Bands: {}, Band Level: {}, Total Staker Shares: {}", [
    //             stakersCount.toString(),
    //             bandsCount.toString(),
    //             bandLevel.toString(),
    //             totalShares.toString(),
    //         ]);
    //     });

    //     describe("1 Staker", () => {
    //         beforeAll(() => {
    //             stakersCount = 1;
    //         });

    //         afterEach(() => {
    //             /*//////////////////////////////////////////////////////////////////////////
    //                                       GET ASSERION DATA
    //             //////////////////////////////////////////////////////////////////////////*/

    //             shares = sharesInMonths[fixedMonths.toI32() - 1];
    //             totalShares = shares.times(BigInt.fromI32(bandsCount));

    //             fixedStakerSharesPerPool = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

    //             isolatedFixedSharesPerPool = createEmptyArray(totalPools);
    //             isolatedFixedSharesPerPool[bandLevel - 1] = totalShares;

    //             /*//////////////////////////////////////////////////////////////////////////
    //                                       ASSERT MAIN DATA
    //             //////////////////////////////////////////////////////////////////////////*/

    //             log.debug("Should create new bands", []);
    //             assert.entityCount("Band", bandsCount);
    //             for (let i = 0; i < bandsCount; i++) {
    //                 assert.fieldEquals("Band", ids[i], "id", ids[i]);
    //             }

    //             log.debug("Should set band values correctly", []);
    //             for (let i = 0; i < bandsCount; i++) {
    //                 assert.fieldEquals("Band", ids[i], "owner", alice.toHex());
    //                 assert.fieldEquals("Band", ids[i], "stakingStartDate", monthsAfterInit[1].toString());
    //                 assert.fieldEquals("Band", ids[i], "bandLevel", bandLevel.toString());
    //                 assert.fieldEquals("Band", ids[i], "stakingType", stringifyStakingType(StakingType.FIX));
    //                 assert.fieldEquals("Band", ids[i], "fixedMonths", fixedMonths.toString());
    //                 assert.fieldEquals("Band", ids[i], "areTokensVested", areTokensVested.toString());
    //             }

    //             log.debug("Should add staker to all stakers", []);
    //             const stakersArray = `[${alice.toHex()}]`;
    //             assert.fieldEquals("StakingContract", ids[0], "stakers", stakersArray);

    //             log.debug("Should updated staking contract details", []);
    //             assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
    //             assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());

    //             log.debug("Should add band to staker bands array", []);
    //             const bands = convertBigIntArrayToString(createArray(bandIds[0], BigInt.fromI32(bandsCount - 1)));
    //             assert.fieldEquals("Staker", alice.toHex(), "fixedBands", bands);
    //             assert.fieldEquals("Staker", alice.toHex(), "flexiBands", "[]");

    //             log.debug("Should update staker details", []);
    //             assert.fieldEquals("Staker", alice.toHex(), "bandsCount", bandsCount.toString());
    //             assert.fieldEquals("Staker", alice.toHex(), "stakedAmount", totalStaked.toString());

    //             /*//////////////////////////////////////////////////////////////////////////
    //                                         ASSERT SHARES
    //             //////////////////////////////////////////////////////////////////////////*/

    //             log.debug("Should set band shares", []);
    //             for (let i = 0; i < bandsCount; i++) {
    //                 assert.fieldEquals("Band", ids[i], "sharesAmount", shares.toString());
    //             }

    //             log.debug("Should set staker shares", []);
    //             assert.fieldEquals(
    //                 "Staker",
    //                 alice.toHex(),
    //                 "fixedSharesPerPool",
    //                 convertBigIntArrayToString(fixedStakerSharesPerPool),
    //             );
    //             assert.fieldEquals(
    //                 "Staker",
    //                 alice.toHex(),
    //                 "isolatedFixedSharesPerPool",
    //                 convertBigIntArrayToString(isolatedFixedSharesPerPool),
    //             );

    //             log.debug("Should set pool shares", []);
    //             for (let i = 1; i <= totalPools.toI32(); i++) {
    //                 assert.fieldEquals(
    //                     "Pool",
    //                     ids[i],
    //                     "totalFixedSharesAmount",
    //                     fixedStakerSharesPerPool[i - 1].toString(),
    //                 );
    //                 assert.fieldEquals(
    //                     "Pool",
    //                     ids[i],
    //                     "isolatedFixedSharesAmount",
    //                     isolatedFixedSharesPerPool[i - 1].toString(),
    //                 );
    //             }
    //         });

    //         describe("Single band level", () => {
    //             describe("Standard staking", () => {
    //                 beforeAll(() => {
    //                     areTokensVested = false;
    //                 });

    //                 afterEach(() => {
    //                     // Staker stakes in the accessible pool of the band level
    //                     totalStaked = BIGINT_ZERO;
    //                     for (let i = 0; i < bandsCount; i++) {
    //                         stakeStandardFixed(
    //                             alice,
    //                             bandLevels[bandLevel - 1],
    //                             bandIds[i],
    //                             fixedMonths,
    //                             monthsAfterInit[1],
    //                         );
    //                         totalStaked = totalStaked.plus(bandLevelPrices[bandLevel - 1]);
    //                     }
    //                 });

    //                 describe("Band level 1", () => {
    //                     beforeAll(() => {
    //                         bandLevel = 1;
    //                     });

    //                     describe("1 FIXED band", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 1;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = months[1];
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = months[12];
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = months[24];
    //                         });
    //                     });

    //                     describe("2 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 2;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = months[1];
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = months[12];
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = months[24];
    //                         });
    //                     });

    //                     describe("3 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 3;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = months[1];
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = months[12];
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = months[24];
    //                         });
    //                     });
    //                 });

    //                 describe("Band level 5", () => {
    //                     beforeAll(() => {
    //                         bandLevel = 5;
    //                     });

    //                     describe("1 FIXED band", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 1;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = months[1];
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = months[12];
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = months[24];
    //                         });
    //                     });

    //                     describe("2 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 2;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = months[1];
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = months[12];
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = months[24];
    //                         });
    //                     });

    //                     describe("3 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 3;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = months[1];
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = months[12];
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = months[24];
    //                         });
    //                     });
    //                 });

    //                 describe("Band level 9", () => {
    //                     beforeAll(() => {
    //                         bandLevel = 9;
    //                     });

    //                     describe("1 FIXED band", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 1;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = months[1];
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = months[12];
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = months[24];
    //                         });
    //                     });

    //                     describe("2 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 2;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = months[1];
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = months[12];
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = months[24];
    //                         });
    //                     });

    //                     describe("3 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 3;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = months[1];
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = months[12];
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = months[24];
    //                         });
    //                     });
    //                 });
    //             });

    //             describe("Vested staking", () => {
    //                 beforeAll(() => {
    //                     areTokensVested = true;
    //                 });

    //                 afterEach(() => {
    //                     // Staker stakes in the accessible pool of the band level
    //                     totalStaked = BIGINT_ZERO;
    //                     for (let i = 0; i < bandsCount; i++) {
    //                         stakeVestedFixed(
    //                             alice,
    //                             bandLevels[bandLevel - 1],
    //                             bandIds[i],
    //                             fixedMonths,
    //                             monthsAfterInit[1],
    //                         );
    //                         totalStaked = totalStaked.plus(bandLevelPrices[bandLevel - 1]);
    //                     }
    //                 });

    //                 describe("Band level 1", () => {
    //                     beforeAll(() => {
    //                         bandLevel = 1;
    //                     });

    //                     describe("1 FIXED band", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 1;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = months[1];
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = months[12];
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = months[24];
    //                         });
    //                     });

    //                     describe("2 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 2;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = months[1];
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = months[12];
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = months[24];
    //                         });
    //                     });

    //                     describe("3 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 3;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = months[1];
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = months[12];
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = months[24];
    //                         });
    //                     });
    //                 });

    //                 describe("Band level 5", () => {
    //                     beforeAll(() => {
    //                         bandLevel = 5;
    //                     });

    //                     describe("1 FIXED band", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 1;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = months[1];
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = months[12];
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = months[24];
    //                         });
    //                     });

    //                     describe("2 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 2;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = months[1];
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = months[12];
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = months[24];
    //                         });
    //                     });

    //                     describe("3 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 3;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = months[1];
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = months[12];
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = months[24];
    //                         });
    //                     });
    //                 });

    //                 describe("Band level 9", () => {
    //                     beforeAll(() => {
    //                         bandLevel = 9;
    //                     });

    //                     describe("1 FIXED band", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 1;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = months[1];
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = months[12];
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = months[24];
    //                         });
    //                     });

    //                     describe("2 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 2;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = months[1];
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = months[12];
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = months[24];
    //                         });
    //                     });

    //                     describe("3 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 3;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = months[1];
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = months[12];
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = months[24];
    //                         });
    //                     });
    //                 });
    //             });
    //         });
    //     });

    //     describe("3 Stakers", () => {
    //         beforeAll(() => {
    //             stakers = [alice, bob, charlie];
    //             stakersCount = stakers.length;
    //         });

    //         afterEach(() => {
    //             /*//////////////////////////////////////////////////////////////////////////
    //                                       ASSERT MAIN DATA
    //             //////////////////////////////////////////////////////////////////////////*/

    //             log.debug("Should create new bands", []);
    //             assert.entityCount("Band", bandsCount * stakersCount);
    //             for (let i = 0; i < bandsCount * stakersCount; i++) {
    //                 assert.fieldEquals("Band", ids[i], "id", ids[i]);
    //             }

    //             log.debug("Should set band values correctly", []);
    //             for (let i = 0; i < bandsCount; i++) {
    //                 for (let j = 0; j < stakersCount; j++) {
    //                     assert.fieldEquals("Band", ids[i * stakersCount + j], "owner", stakers[j].toHex());
    //                     assert.fieldEquals(
    //                         "Band",
    //                         ids[i * stakersCount + j],
    //                         "stakingStartDate",
    //                         monthsAfterInit[1].toString(),
    //                     );
    //                     assert.fieldEquals("Band", ids[i * stakersCount + j], "bandLevel", bandLevel.toString());
    //                     assert.fieldEquals(
    //                         "Band",
    //                         ids[i * stakersCount + j],
    //                         "stakingType",
    //                         stringifyStakingType(StakingType.FIX),
    //                     );
    //                     assert.fieldEquals("Band", ids[i * stakersCount + j], "fixedMonths", fixedMonths.toString());
    //                     assert.fieldEquals(
    //                         "Band",
    //                         ids[i * stakersCount + j],
    //                         "areTokensVested",
    //                         areTokensVested.toString(),
    //                     );
    //                 }
    //             }

    //             log.debug("Should updated staking contract details", []);
    //             assert.fieldEquals("StakingContract", ids[0], "stakers", convertAddressArrayToString(stakers));
    //             assert.fieldEquals("StakingContract", ids[0], "nextBandId", (bandsCount * stakersCount).toString());
    //             assert.fieldEquals(
    //                 "StakingContract",
    //                 ids[0],
    //                 "totalStakedAmount",
    //                 totalStaked.times(BigInt.fromI32(stakersCount)).toString(),
    //             );

    //             log.debug("Should update staker details", []);
    //             for (let i = 0; i < stakersCount; i++) {
    //                 const staker = stakers[i].toHex();
    //                 const bands = convertBigIntArrayToString(
    //                     createArrayWithMultiplication(
    //                         bandIds[i],
    //                         BigInt.fromI32(bandsCount + i - 1),
    //                         BigInt.fromI32(stakersCount),
    //                     ),
    //                 );

    //                 assert.fieldEquals("Staker", staker, "fixedBands", bands);
    //                 assert.fieldEquals("Staker", staker, "flexiBands", "[]");
    //                 assert.fieldEquals("Staker", staker, "bandsCount", bandsCount.toString());
    //                 assert.fieldEquals("Staker", staker, "stakedAmount", totalStaked.toString());
    //             }

    //             /*//////////////////////////////////////////////////////////////////////////
    //                                         ASSERT SHARES
    //             //////////////////////////////////////////////////////////////////////////*/

    //             log.debug("Should set band shares", []);
    //             for (let i = 0; i < bandsCount * stakersCount; i++) {
    //                 assert.fieldEquals("Band", ids[i], "sharesAmount", shares.toString());
    //             }

    //             log.debug("Should set staker shares", []);
    //             for (let i = 0; i < stakersCount; i++) {
    //                 const stakerId = stakers[i].toHex();
    //                 assert.fieldEquals(
    //                     "Staker",
    //                     stakerId,
    //                     "fixedSharesPerPool",
    //                     convertBigIntArrayToString(fixedStakerSharesPerPool),
    //                 );
    //                 assert.fieldEquals(
    //                     "Staker",
    //                     stakerId,
    //                     "isolatedFixedSharesPerPool",
    //                     convertBigIntArrayToString(isolatedFixedSharesPerPool),
    //                 );
    //             }

    //             log.debug("Should set pool shares", []);
    //             for (let i = 1; i <= totalPools.toI32(); i++) {
    //                 const totalFixedShares = fixedStakerSharesPerPool[i - 1].times(BigInt.fromI32(stakersCount));
    //                 const totalIsolatedFixedShares = isolatedFixedSharesPerPool[i - 1].times(
    //                     BigInt.fromI32(stakersCount),
    //                 );

    //                 assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", totalFixedShares.toString());
    //                 assert.fieldEquals(
    //                     "Pool",
    //                     ids[i],
    //                     "isolatedFixedSharesAmount",
    //                     totalIsolatedFixedShares.toString(),
    //                 );
    //             }
    //         });

    //         describe("Single band level", () => {
    //             describe("Standard staking", () => {
    //                 beforeAll(() => {
    //                     areTokensVested = false;
    //                 });

    //                 afterEach(() => {
    //                     shares = sharesInMonths[fixedMonths.toI32() - 1];
    //                     totalShares = shares.times(BigInt.fromI32(bandsCount));

    //                     fixedStakerSharesPerPool = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

    //                     isolatedFixedSharesPerPool = createEmptyArray(totalPools);
    //                     isolatedFixedSharesPerPool[bandLevel - 1] = totalShares;

    //                     // Staker stakes in the accessible pool of the band level
    //                     totalStaked = BIGINT_ZERO;
    //                     for (let i = 0; i < bandsCount; i++) {
    //                         for (let j = 0; j < stakersCount; j++) {
    //                             stakeStandardFixed(
    //                                 stakers[j],
    //                                 bandLevels[bandLevel - 1],
    //                                 bandIds[i * stakersCount + j],
    //                                 fixedMonths,
    //                                 monthsAfterInit[1],
    //                             );
    //                         }
    //                         totalStaked = totalStaked.plus(bandLevelPrices[bandLevel - 1]);
    //                     }
    //                 });

    //                 describe("Band level 1", () => {
    //                     beforeAll(() => {
    //                         bandLevel = 1;
    //                     });

    //                     describe("1 FIXED band", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 1;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = BigInt.fromI32(1);
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = BigInt.fromI32(12);
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = BigInt.fromI32(24);
    //                         });
    //                     });

    //                     describe("2 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 2;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = BigInt.fromI32(1);
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = BigInt.fromI32(12);
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = BigInt.fromI32(24);
    //                         });
    //                     });

    //                     describe("3 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 3;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = BigInt.fromI32(1);
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = BigInt.fromI32(12);
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = BigInt.fromI32(24);
    //                         });
    //                     });
    //                 });

    //                 describe("Band level 5", () => {
    //                     beforeAll(() => {
    //                         bandLevel = 5;
    //                     });

    //                     describe("1 FIXED band", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 1;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = BigInt.fromI32(1);
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = BigInt.fromI32(12);
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = BigInt.fromI32(24);
    //                         });
    //                     });

    //                     describe("2 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 2;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = BigInt.fromI32(1);
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = BigInt.fromI32(12);
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = BigInt.fromI32(24);
    //                         });
    //                     });

    //                     describe("3 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 3;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = BigInt.fromI32(1);
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = BigInt.fromI32(12);
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = BigInt.fromI32(24);
    //                         });
    //                     });
    //                 });

    //                 describe("Band level 9", () => {
    //                     beforeAll(() => {
    //                         bandLevel = 9;
    //                     });

    //                     describe("1 FIXED band", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 1;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = BigInt.fromI32(1);
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = BigInt.fromI32(12);
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = BigInt.fromI32(24);
    //                         });
    //                     });

    //                     describe("2 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 2;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = BigInt.fromI32(1);
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = BigInt.fromI32(12);
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = BigInt.fromI32(24);
    //                         });
    //                     });

    //                     describe("3 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 3;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = BigInt.fromI32(1);
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = BigInt.fromI32(12);
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = BigInt.fromI32(24);
    //                         });
    //                     });
    //                 });
    //             });

    //             describe("Vested staking", () => {
    //                 beforeAll(() => {
    //                     areTokensVested = true;
    //                 });

    //                 afterEach(() => {
    //                     shares = sharesInMonths[fixedMonths.toI32() - 1];
    //                     totalShares = shares.times(BigInt.fromI32(bandsCount));

    //                     fixedStakerSharesPerPool = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

    //                     isolatedFixedSharesPerPool = createEmptyArray(totalPools);
    //                     isolatedFixedSharesPerPool[bandLevel - 1] = totalShares;

    //                     // Staker stakes in the accessible pool of the band level
    //                     totalStaked = BIGINT_ZERO;
    //                     for (let i = 0; i < bandsCount; i++) {
    //                         for (let j = 0; j < stakersCount; j++) {
    //                             stakeVestedFixed(
    //                                 stakers[j],
    //                                 bandLevels[bandLevel - 1],
    //                                 bandIds[i * stakersCount + j],
    //                                 fixedMonths,
    //                                 monthsAfterInit[1],
    //                             );
    //                         }
    //                         totalStaked = totalStaked.plus(bandLevelPrices[bandLevel - 1]);
    //                     }
    //                 });

    //                 describe("Band level 1", () => {
    //                     beforeAll(() => {
    //                         bandLevel = 1;
    //                     });

    //                     describe("1 FIXED band", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 1;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = BigInt.fromI32(1);
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = BigInt.fromI32(12);
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = BigInt.fromI32(24);
    //                         });
    //                     });

    //                     describe("2 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 2;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = BigInt.fromI32(1);
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = BigInt.fromI32(12);
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = BigInt.fromI32(24);
    //                         });
    //                     });

    //                     describe("3 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 3;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = BigInt.fromI32(1);
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = BigInt.fromI32(12);
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = BigInt.fromI32(24);
    //                         });
    //                     });
    //                 });

    //                 describe("Band level 5", () => {
    //                     beforeAll(() => {
    //                         bandLevel = 5;
    //                     });

    //                     describe("1 FIXED band", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 1;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = BigInt.fromI32(1);
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = BigInt.fromI32(12);
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = BigInt.fromI32(24);
    //                         });
    //                     });

    //                     describe("2 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 2;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = BigInt.fromI32(1);
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = BigInt.fromI32(12);
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = BigInt.fromI32(24);
    //                         });
    //                     });

    //                     describe("3 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 3;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = BigInt.fromI32(1);
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = BigInt.fromI32(12);
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = BigInt.fromI32(24);
    //                         });
    //                     });
    //                 });

    //                 describe("Band level 9", () => {
    //                     beforeAll(() => {
    //                         bandLevel = 9;
    //                     });

    //                     describe("1 FIXED band", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 1;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = BigInt.fromI32(1);
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = BigInt.fromI32(12);
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = BigInt.fromI32(24);
    //                         });
    //                     });

    //                     describe("2 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 2;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = BigInt.fromI32(1);
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = BigInt.fromI32(12);
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = BigInt.fromI32(24);
    //                         });
    //                     });

    //                     describe("3 FIXED bands", () => {
    //                         beforeAll(() => {
    //                             bandsCount = 3;
    //                         });

    //                         test("Fixed months - 1", () => {
    //                             fixedMonths = BigInt.fromI32(1);
    //                         });

    //                         test("Fixed months - 12", () => {
    //                             fixedMonths = BigInt.fromI32(12);
    //                         });

    //                         test("Fixed months - 24", () => {
    //                             fixedMonths = BigInt.fromI32(24);
    //                         });
    //                     });
    //                 });
    //             });
    //         });
    //     });
    // });

    describe("Complex cases", () => {
        // describe("Only FIXED bands", () => {
        //     describe("Single type stakes (standard or vested)", () => {
        //         describe("9 stakers, each staker with different band levels", () => {
        //             beforeAll(() => {
        //                 bandsCount = 9;
        //                 stakersCount = 9;

        //                 // Calculations for testing shares
        //                 allPoolTotalFixedShares = createEmptyArray(totalPools);
        //                 allPoolIsolatedFixedShares = createEmptyArray(totalPools);
        //                 allStakerFixedShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);
        //                 allStakerIsolatedFixedShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);

        //                 for (let i = 0; i < stakersCount; i++) {
        //                     allStakerIsolatedFixedShares[i][i] = sharesInMonths[i];
        //                     allPoolIsolatedFixedShares[i] = allPoolIsolatedFixedShares[i].plus(sharesInMonths[i]);

        //                     for (let j = 0; j < i + 1; j++) {
        //                         allStakerFixedShares[i][j] = sharesInMonths[i];
        //                         allPoolTotalFixedShares[j] = allPoolTotalFixedShares[j].plus(sharesInMonths[i]);
        //                     }
        //                 }
        //             });

        //             describe("Standard FIXED bands", () => {
        //                 beforeAll(() => {
        //                     areTokensVested = false;
        //                 });

        //                 beforeEach(() => {
        //                     totalStaked = BIGINT_ZERO;

        //                     // Stake in all bands
        //                     for (let i = 0; i < totalBandLevels.toI32(); i++) {
        //                         stakeStandardFixed(
        //                             users[i],
        //                             bandLevels[i],
        //                             bandIds[i],
        //                             months[i + 1],
        //                             monthsAfterInit[i + 1],
        //                         );
        //                         totalStaked = totalStaked.plus(bandLevelPrices[i]);
        //                     }
        //                 });

        //                 test("Should create new bands", () => {
        //                     assert.entityCount("Band", bandsCount);
        //                     for (let i = 0; i < bandsCount; i++) {
        //                         assert.fieldEquals("Band", ids[i], "id", ids[i]);
        //                     }
        //                 });

        //                 test("Should set band values correctly", () => {
        //                     for (let i = 0; i < bandsCount; i++) {
        //                         assert.fieldEquals("Band", ids[i], "owner", users[i].toHex());
        //                         assert.fieldEquals(
        //                             "Band",
        //                             ids[i],
        //                             "stakingStartDate",
        //                             monthsAfterInit[i + 1].toString(),
        //                         );
        //                         assert.fieldEquals("Band", ids[i], "bandLevel", bandLevels[i].toString());
        //                         assert.fieldEquals(
        //                             "Band",
        //                             ids[i],
        //                             "stakingType",
        //                             stringifyStakingType(StakingType.FIX),
        //                         );
        //                         assert.fieldEquals("Band", ids[i], "fixedMonths", months[i + 1].toString());
        //                         assert.fieldEquals("Band", ids[i], "areTokensVested", areTokensVested.toString());
        //                     }
        //                 });

        //                 test("Should updated staking contract details", () => {
        //                     assert.fieldEquals(
        //                         "StakingContract",
        //                         ids[0],
        //                         "stakers",
        //                         convertAddressArrayToString(users),
        //                     );
        //                     assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
        //                     assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
        //                 });

        //                 test("Should update staker details", () => {
        //                     for (let i = 0; i < stakersCount; i++) {
        //                         const staker = users[i].toHex();
        //                         const bands = `[${ids[i]}]`;

        //                         assert.fieldEquals("Staker", staker, "fixedBands", bands);
        //                         assert.fieldEquals("Staker", staker, "flexiBands", "[]");
        //                         assert.fieldEquals("Staker", staker, "bandsCount", "1");
        //                         assert.fieldEquals("Staker", staker, "stakedAmount", bandLevelPrices[i].toString());
        //                     }
        //                 });

        //                 describe("Shares calculations", () => {
        //                     test("Should set band shares", () => {
        //                         for (let i = 0; i < bandsCount; i++) {
        //                             assert.fieldEquals("Band", ids[i], "sharesAmount", sharesInMonths[i].toString());
        //                         }
        //                     });

        //                     test("Should set staker FIXED shares", () => {
        //                         for (let i = 0; i < stakersCount; i++) {
        //                             const staker = users[i].toHex();

        //                             assert.fieldEquals(
        //                                 "Staker",
        //                                 staker,
        //                                 "fixedSharesPerPool",
        //                                 convertBigIntArrayToString(allStakerFixedShares[i]),
        //                             );
        //                             assert.fieldEquals(
        //                                 "Staker",
        //                                 staker,
        //                                 "isolatedFixedSharesPerPool",
        //                                 convertBigIntArrayToString(allStakerIsolatedFixedShares[i]),
        //                             );
        //                         }
        //                     });

        //                     test("Should not set staker FLEXI shares", () => {
        //                         const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));

        //                         for (let i = 0; i < stakersCount; i++) {
        //                             const staker = users[i].toHex();
        //                             assert.fieldEquals("Staker", staker, "flexiSharesPerPool", stringifiedEmptyArray);
        //                             assert.fieldEquals(
        //                                 "Staker",
        //                                 staker,
        //                                 "isolatedFlexiSharesPerPool",
        //                                 stringifiedEmptyArray,
        //                             );
        //                         }
        //                     });

        //                     test("Should set pool FIXED shares", () => {
        //                         for (let i = 1; i <= totalPools.toI32(); i++) {
        //                             const totalFixedShares = allPoolTotalFixedShares[i - 1];
        //                             const totalIsolatedFixedShares = allPoolIsolatedFixedShares[i - 1];

        //                             assert.fieldEquals(
        //                                 "Pool",
        //                                 ids[i],
        //                                 "totalFixedSharesAmount",
        //                                 totalFixedShares.toString(),
        //                             );
        //                             assert.fieldEquals(
        //                                 "Pool",
        //                                 ids[i],
        //                                 "isolatedFixedSharesAmount",
        //                                 totalIsolatedFixedShares.toString(),
        //                             );
        //                         }
        //                     });

        //                     test("Should not set pool FLEXI shares", () => {
        //                         for (let i = 1; i <= totalPools.toI32(); i++) {
        //                             assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", "0");
        //                             assert.fieldEquals("Pool", ids[i], "isolatedFlexiSharesAmount", "0");
        //                         }
        //                     });
        //                 });
        //             });

        //             describe("Vested FIXED bands", () => {
        //                 beforeAll(() => {
        //                     areTokensVested = true;
        //                 });

        //                 beforeEach(() => {
        //                     totalStaked = BIGINT_ZERO;

        //                     // Stake in all bands
        //                     for (let i = 0; i < totalBandLevels.toI32(); i++) {
        //                         stakeVestedFixed(
        //                             users[i],
        //                             bandLevels[i],
        //                             bandIds[i],
        //                             months[i + 1],
        //                             monthsAfterInit[i + 1],
        //                         );
        //                         totalStaked = totalStaked.plus(bandLevelPrices[i]);
        //                     }
        //                 });

        //                 test("Should create new bands", () => {
        //                     assert.entityCount("Band", bandsCount);
        //                     for (let i = 0; i < bandsCount; i++) {
        //                         assert.fieldEquals("Band", ids[i], "id", ids[i]);
        //                     }
        //                 });

        //                 test("Should set band values correctly", () => {
        //                     for (let i = 0; i < bandsCount; i++) {
        //                         assert.fieldEquals("Band", ids[i], "owner", users[i].toHex());
        //                         assert.fieldEquals(
        //                             "Band",
        //                             ids[i],
        //                             "stakingStartDate",
        //                             monthsAfterInit[i + 1].toString(),
        //                         );
        //                         assert.fieldEquals("Band", ids[i], "bandLevel", bandLevels[i].toString());
        //                         assert.fieldEquals(
        //                             "Band",
        //                             ids[i],
        //                             "stakingType",
        //                             stringifyStakingType(StakingType.FIX),
        //                         );
        //                         assert.fieldEquals("Band", ids[i], "fixedMonths", months[i + 1].toString());
        //                         assert.fieldEquals("Band", ids[i], "areTokensVested", areTokensVested.toString());
        //                     }
        //                 });

        //                 test("Should updated staking contract details", () => {
        //                     assert.fieldEquals(
        //                         "StakingContract",
        //                         ids[0],
        //                         "stakers",
        //                         convertAddressArrayToString(users),
        //                     );
        //                     assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
        //                     assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
        //                 });

        //                 test("Should update staker details", () => {
        //                     for (let i = 0; i < stakersCount; i++) {
        //                         const staker = users[i].toHex();
        //                         const bands = `[${ids[i]}]`;

        //                         assert.fieldEquals("Staker", staker, "fixedBands", bands);
        //                         assert.fieldEquals("Staker", staker, "flexiBands", "[]");
        //                         assert.fieldEquals("Staker", staker, "bandsCount", "1");
        //                         assert.fieldEquals("Staker", staker, "stakedAmount", bandLevelPrices[i].toString());
        //                     }
        //                 });

        //                 describe("Shares calculations", () => {
        //                     test("Should set band shares", () => {
        //                         for (let i = 0; i < bandsCount; i++) {
        //                             assert.fieldEquals("Band", ids[i], "sharesAmount", sharesInMonths[i].toString());
        //                         }
        //                     });

        //                     test("Should set staker FIXED shares", () => {
        //                         for (let i = 0; i < stakersCount; i++) {
        //                             const staker = users[i].toHex();

        //                             assert.fieldEquals(
        //                                 "Staker",
        //                                 staker,
        //                                 "fixedSharesPerPool",
        //                                 convertBigIntArrayToString(allStakerFixedShares[i]),
        //                             );
        //                             assert.fieldEquals(
        //                                 "Staker",
        //                                 staker,
        //                                 "isolatedFixedSharesPerPool",
        //                                 convertBigIntArrayToString(allStakerIsolatedFixedShares[i]),
        //                             );
        //                         }
        //                     });

        //                     test("Should not set staker FLEXI shares", () => {
        //                         const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));

        //                         for (let i = 0; i < stakersCount; i++) {
        //                             const staker = users[i].toHex();
        //                             assert.fieldEquals("Staker", staker, "flexiSharesPerPool", stringifiedEmptyArray);
        //                             assert.fieldEquals(
        //                                 "Staker",
        //                                 staker,
        //                                 "isolatedFlexiSharesPerPool",
        //                                 stringifiedEmptyArray,
        //                             );
        //                         }
        //                     });

        //                     test("Should set pool FIXED shares", () => {
        //                         for (let i = 1; i <= totalPools.toI32(); i++) {
        //                             const totalFixedShares = allPoolTotalFixedShares[i - 1];
        //                             const totalIsolatedFixedShares = allPoolIsolatedFixedShares[i - 1];

        //                             assert.fieldEquals(
        //                                 "Pool",
        //                                 ids[i],
        //                                 "totalFixedSharesAmount",
        //                                 totalFixedShares.toString(),
        //                             );
        //                             assert.fieldEquals(
        //                                 "Pool",
        //                                 ids[i],
        //                                 "isolatedFixedSharesAmount",
        //                                 totalIsolatedFixedShares.toString(),
        //                             );
        //                         }
        //                     });

        //                     test("Should not set pool FLEXI shares", () => {
        //                         for (let i = 1; i <= totalPools.toI32(); i++) {
        //                             assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", "0");
        //                             assert.fieldEquals("Pool", ids[i], "isolatedFlexiSharesAmount", "0");
        //                         }
        //                     });
        //                 });
        //             });
        //         });

        //         describe("1 staker with 9 bands, each band with different band levels", () => {
        //             beforeAll(() => {
        //                 bandsCount = 9;
        //                 stakersCount = 1;

        //                 // Calculations for testing shares
        //                 allPoolTotalFixedShares = createEmptyArray(totalPools);
        //                 allPoolIsolatedFixedShares = createEmptyArray(totalPools);

        //                 for (let i = 0; i < bandsCount; i++) {
        //                     allPoolIsolatedFixedShares[i] = allPoolIsolatedFixedShares[i].plus(sharesInMonths[i]);

        //                     for (let j = 0; j < i + 1; j++) {
        //                         allPoolTotalFixedShares[j] = allPoolTotalFixedShares[j].plus(sharesInMonths[i]);
        //                     }
        //                 }
        //             });

        //             describe("Standard FIXED band", () => {
        //                 beforeAll(() => {
        //                     areTokensVested = false;
        //                 });

        //                 beforeEach(() => {
        //                     totalStaked = BIGINT_ZERO;

        //                     // Stake in all bands
        //                     for (let i = 0; i < totalBandLevels.toI32(); i++) {
        //                         stakeStandardFixed(
        //                             alice,
        //                             bandLevels[i],
        //                             bandIds[i],
        //                             months[i + 1],
        //                             monthsAfterInit[i + 1],
        //                         );
        //                         totalStaked = totalStaked.plus(bandLevelPrices[i]);
        //                     }
        //                 });

        //                 test("Should create new bands", () => {
        //                     assert.entityCount("Band", bandsCount);
        //                     for (let i = 0; i < bandsCount; i++) {
        //                         assert.fieldEquals("Band", ids[i], "id", ids[i]);
        //                     }
        //                 });

        //                 test("Should set band values correctly", () => {
        //                     for (let i = 0; i < bandsCount; i++) {
        //                         assert.fieldEquals("Band", ids[i], "owner", alice.toHex());
        //                         assert.fieldEquals(
        //                             "Band",
        //                             ids[i],
        //                             "stakingStartDate",
        //                             monthsAfterInit[i + 1].toString(),
        //                         );
        //                         assert.fieldEquals("Band", ids[i], "bandLevel", bandLevels[i].toString());
        //                         assert.fieldEquals(
        //                             "Band",
        //                             ids[i],
        //                             "stakingType",
        //                             stringifyStakingType(StakingType.FIX),
        //                         );
        //                         assert.fieldEquals("Band", ids[i], "fixedMonths", months[i + 1].toString());
        //                         assert.fieldEquals("Band", ids[i], "areTokensVested", areTokensVested.toString());
        //                     }
        //                 });

        //                 test("Should updated staking contract details", () => {
        //                     const stakers: string = `[${alice.toHex()}]`;
        //                     assert.fieldEquals("StakingContract", ids[0], "stakers", stakers);
        //                     assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
        //                     assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
        //                 });

        //                 test("Should update staker details", () => {
        //                     const staker = alice.toHex();
        //                     const bands = createArray(BIGINT_ZERO, BigInt.fromI32(bandsCount - 1));

        //                     assert.fieldEquals("Staker", staker, "fixedBands", convertBigIntArrayToString(bands));
        //                     assert.fieldEquals("Staker", staker, "flexiBands", "[]");
        //                     assert.fieldEquals("Staker", staker, "bandsCount", "9");
        //                     assert.fieldEquals("Staker", staker, "stakedAmount", totalStaked.toString());
        //                 });

        //                 describe("Shares calculations", () => {
        //                     test("Should set band shares", () => {
        //                         for (let i = 0; i < bandsCount; i++) {
        //                             assert.fieldEquals("Band", ids[i], "sharesAmount", sharesInMonths[i].toString());
        //                         }
        //                     });

        //                     test("Should set staker FIXED shares", () => {
        //                         const staker = alice.toHex();

        //                         assert.fieldEquals(
        //                             "Staker",
        //                             staker,
        //                             "fixedSharesPerPool",
        //                             convertBigIntArrayToString(allPoolTotalFixedShares),
        //                         );
        //                         assert.fieldEquals(
        //                             "Staker",
        //                             staker,
        //                             "isolatedFixedSharesPerPool",
        //                             convertBigIntArrayToString(allPoolIsolatedFixedShares),
        //                         );
        //                     });

        //                     test("Should not set staker FLEXI shares", () => {
        //                         const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));
        //                         const staker = alice.toHex();

        //                         assert.fieldEquals("Staker", staker, "flexiSharesPerPool", stringifiedEmptyArray);
        //                         assert.fieldEquals(
        //                             "Staker",
        //                             staker,
        //                             "isolatedFlexiSharesPerPool",
        //                             stringifiedEmptyArray,
        //                         );
        //                     });

        //                     test("Should set pool FIXED shares", () => {
        //                         for (let i = 1; i <= totalPools.toI32(); i++) {
        //                             const totalFixedShares = allPoolTotalFixedShares[i - 1];
        //                             const totalIsolatedFixedShares = allPoolIsolatedFixedShares[i - 1];

        //                             assert.fieldEquals(
        //                                 "Pool",
        //                                 ids[i],
        //                                 "totalFixedSharesAmount",
        //                                 totalFixedShares.toString(),
        //                             );
        //                             assert.fieldEquals(
        //                                 "Pool",
        //                                 ids[i],
        //                                 "isolatedFixedSharesAmount",
        //                                 totalIsolatedFixedShares.toString(),
        //                             );
        //                         }
        //                     });

        //                     test("Should not set pool FLEXI shares", () => {
        //                         for (let i = 1; i <= totalPools.toI32(); i++) {
        //                             assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", "0");
        //                             assert.fieldEquals("Pool", ids[i], "isolatedFlexiSharesAmount", "0");
        //                         }
        //                     });
        //                 });
        //             });

        //             describe("Vested FIXED band", () => {
        //                 beforeAll(() => {
        //                     areTokensVested = true;
        //                 });

        //                 beforeEach(() => {
        //                     totalStaked = BIGINT_ZERO;

        //                     // Stake in all bands
        //                     for (let i = 0; i < totalBandLevels.toI32(); i++) {
        //                         stakeVestedFixed(
        //                             alice,
        //                             bandLevels[i],
        //                             bandIds[i],
        //                             months[i + 1],
        //                             monthsAfterInit[i + 1],
        //                         );
        //                         totalStaked = totalStaked.plus(bandLevelPrices[i]);
        //                     }
        //                 });

        //                 test("Should create new bands", () => {
        //                     assert.entityCount("Band", bandsCount);
        //                     for (let i = 0; i < bandsCount; i++) {
        //                         assert.fieldEquals("Band", ids[i], "id", ids[i]);
        //                     }
        //                 });

        //                 test("Should set band values correctly", () => {
        //                     for (let i = 0; i < bandsCount; i++) {
        //                         assert.fieldEquals("Band", ids[i], "owner", alice.toHex());
        //                         assert.fieldEquals(
        //                             "Band",
        //                             ids[i],
        //                             "stakingStartDate",
        //                             monthsAfterInit[i + 1].toString(),
        //                         );
        //                         assert.fieldEquals("Band", ids[i], "bandLevel", bandLevels[i].toString());
        //                         assert.fieldEquals(
        //                             "Band",
        //                             ids[i],
        //                             "stakingType",
        //                             stringifyStakingType(StakingType.FIX),
        //                         );
        //                         assert.fieldEquals("Band", ids[i], "fixedMonths", months[i + 1].toString());
        //                         assert.fieldEquals("Band", ids[i], "areTokensVested", areTokensVested.toString());
        //                     }
        //                 });

        //                 test("Should updated staking contract details", () => {
        //                     const stakers: string = `[${alice.toHex()}]`;
        //                     assert.fieldEquals("StakingContract", ids[0], "stakers", stakers);
        //                     assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
        //                     assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
        //                 });

        //                 test("Should update staker details", () => {
        //                     const staker = alice.toHex();
        //                     const bands = createArray(BIGINT_ZERO, BigInt.fromI32(bandsCount - 1));

        //                     assert.fieldEquals("Staker", staker, "fixedBands", convertBigIntArrayToString(bands));
        //                     assert.fieldEquals("Staker", staker, "flexiBands", "[]");
        //                     assert.fieldEquals("Staker", staker, "bandsCount", "9");
        //                     assert.fieldEquals("Staker", staker, "stakedAmount", totalStaked.toString());
        //                 });

        //                 describe("Shares calculations", () => {
        //                     test("Should set band shares", () => {
        //                         for (let i = 0; i < bandsCount; i++) {
        //                             assert.fieldEquals("Band", ids[i], "sharesAmount", sharesInMonths[i].toString());
        //                         }
        //                     });

        //                     test("Should set staker FIXED shares", () => {
        //                         const staker = alice.toHex();

        //                         assert.fieldEquals(
        //                             "Staker",
        //                             staker,
        //                             "fixedSharesPerPool",
        //                             convertBigIntArrayToString(allPoolTotalFixedShares),
        //                         );
        //                         assert.fieldEquals(
        //                             "Staker",
        //                             staker,
        //                             "isolatedFixedSharesPerPool",
        //                             convertBigIntArrayToString(allPoolIsolatedFixedShares),
        //                         );
        //                     });

        //                     test("Should not set staker FLEXI shares", () => {
        //                         const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));
        //                         const staker = alice.toHex();

        //                         assert.fieldEquals("Staker", staker, "flexiSharesPerPool", stringifiedEmptyArray);
        //                         assert.fieldEquals(
        //                             "Staker",
        //                             staker,
        //                             "isolatedFlexiSharesPerPool",
        //                             stringifiedEmptyArray,
        //                         );
        //                     });

        //                     test("Should set pool FIXED shares", () => {
        //                         for (let i = 1; i <= totalPools.toI32(); i++) {
        //                             const totalFixedShares = allPoolTotalFixedShares[i - 1];
        //                             const totalIsolatedFixedShares = allPoolIsolatedFixedShares[i - 1];

        //                             assert.fieldEquals(
        //                                 "Pool",
        //                                 ids[i],
        //                                 "totalFixedSharesAmount",
        //                                 totalFixedShares.toString(),
        //                             );
        //                             assert.fieldEquals(
        //                                 "Pool",
        //                                 ids[i],
        //                                 "isolatedFixedSharesAmount",
        //                                 totalIsolatedFixedShares.toString(),
        //                             );
        //                         }
        //                     });

        //                     test("Should not set pool FLEXI shares", () => {
        //                         for (let i = 1; i <= totalPools.toI32(); i++) {
        //                             assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", "0");
        //                             assert.fieldEquals("Pool", ids[i], "isolatedFlexiSharesAmount", "0");
        //                         }
        //                     });
        //                 });
        //             });
        //         });

        //         describe("4 stakers, 8 bands, all random stakes", () => {
        //             beforeAll(() => {
        //                 bandsCount = 8;
        //                 stakersCount = 4;
        //                 stakers = [alice, bob, charlie, dan];
        //                 stakerBands = [
        //                     [bandLevels[0]],
        //                     [bandLevels[3], bandLevels[1], bandLevels[1]],
        //                     [bandLevels[3], bandLevels[7], bandLevels[5]],
        //                     [bandLevels[8]],
        //                 ];

        //                 // Calculations for testing shares
        //                 allPoolTotalFixedShares = createEmptyArray(totalPools);
        //                 allPoolIsolatedFixedShares = createEmptyArray(totalPools);
        //                 allStakerFixedShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);
        //                 allStakerIsolatedFixedShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);
        //                 let bandId = 0;

        //                 for (let i = 0; i < stakersCount; i++) {
        //                     const bands = stakerBands[i];
        //                     const bandsCount = bands.length;

        //                     for (let j = 0; j < bandsCount; j++) {
        //                         const bandLevel = bands[j].toI32() - 1;
        //                         const shares = sharesInMonths[bandId];

        //                         allStakerIsolatedFixedShares[i][bandLevel] =
        //                             allStakerIsolatedFixedShares[i][bandLevel].plus(shares);
        //                         allPoolIsolatedFixedShares[bandLevel] =
        //                             allPoolIsolatedFixedShares[bandLevel].plus(shares);

        //                         for (let k = 0; k < bandLevel + 1; k++) {
        //                             allStakerFixedShares[i][k] = allStakerFixedShares[i][k].plus(shares);
        //                             allPoolTotalFixedShares[k] = allPoolTotalFixedShares[k].plus(shares);
        //                         }

        //                         bandId++;
        //                     }
        //                 }
        //             });

        //             describe("Standard FIXED bands", () => {
        //                 beforeAll(() => {
        //                     areTokensVested = false;
        //                 });

        //                 beforeEach(() => {
        //                     let bandId = 0;
        //                     totalStaked = BIGINT_ZERO;

        //                     for (let i = 0; i < stakersCount; i++) {
        //                         const bands = stakerBands[i];
        //                         const bandsCount = bands.length;

        //                         for (let j = 0; j < bandsCount; j++) {
        //                             const bandLevel = bands[j];

        //                             stakeStandardFixed(
        //                                 stakers[i],
        //                                 bandLevel,
        //                                 bandIds[bandId],
        //                                 months[bandId + 1],
        //                                 monthsAfterInit[bandId + 1],
        //                             );
        //                             totalStaked = totalStaked.plus(bandLevelPrices[bandLevel.toI32() - 1]);
        //                             bandId++;
        //                         }
        //                     }

        //                     // Stake in all bands
        //                     for (let i = 0; i < totalBandLevels.toI32(); i++) {}
        //                 });

        //                 test("Should create new bands", () => {
        //                     assert.entityCount("Band", bandsCount);
        //                     for (let i = 0; i < bandsCount; i++) {
        //                         assert.fieldEquals("Band", ids[i], "id", ids[i]);
        //                     }
        //                 });

        //                 test("Should set band values correctly", () => {
        //                     let bandId = 0;

        //                     for (let i = 0; i < stakersCount; i++) {
        //                         const bands = stakerBands[i];
        //                         const stakerBandsCount = bands.length;

        //                         for (let j = 0; j < stakerBandsCount; j++) {
        //                             assert.fieldEquals("Band", ids[bandId], "owner", stakers[i].toHex());
        //                             assert.fieldEquals(
        //                                 "Band",
        //                                 ids[bandId],
        //                                 "stakingStartDate",
        //                                 monthsAfterInit[bandId + 1].toString(),
        //                             );
        //                             assert.fieldEquals("Band", ids[bandId], "bandLevel", bands[j].toString());
        //                             assert.fieldEquals(
        //                                 "Band",
        //                                 ids[bandId],
        //                                 "stakingType",
        //                                 stringifyStakingType(StakingType.FIX),
        //                             );
        //                             assert.fieldEquals(
        //                                 "Band",
        //                                 ids[bandId],
        //                                 "fixedMonths",
        //                                 months[bandId + 1].toString(),
        //                             );
        //                             assert.fieldEquals(
        //                                 "Band",
        //                                 ids[bandId],
        //                                 "areTokensVested",
        //                                 areTokensVested.toString(),
        //                             );

        //                             bandId++;
        //                         }
        //                     }
        //                 });

        //                 test("Should updated staking contract details", () => {
        //                     assert.fieldEquals(
        //                         "StakingContract",
        //                         ids[0],
        //                         "stakers",
        //                         convertAddressArrayToString(stakers),
        //                     );
        //                     assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
        //                     assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
        //                 });

        //                 test("Should update staker details", () => {
        //                     let bandId = 0;

        //                     for (let i = 0; i < stakersCount; i++) {
        //                         const staker = stakers[i].toHex();
        //                         const bandsWithLevels = stakerBands[i];
        //                         const stakerBandsCount = bandsWithLevels.length;
        //                         const bands: BigInt[] = [];
        //                         let stakedAmount: BigInt = BIGINT_ZERO;

        //                         for (let j = 0; j < stakerBandsCount; j++) {
        //                             stakedAmount = stakedAmount.plus(bandLevelPrices[bandsWithLevels[j].toI32() - 1]);
        //                             bands.push(BigInt.fromI32(bandId));
        //                             bandId++;
        //                         }

        //                         assert.fieldEquals("Staker", staker, "fixedBands", convertBigIntArrayToString(bands));
        //                         assert.fieldEquals("Staker", staker, "flexiBands", "[]");
        //                         assert.fieldEquals("Staker", staker, "bandsCount", stakerBandsCount.toString());
        //                         assert.fieldEquals("Staker", staker, "stakedAmount", stakedAmount.toString());
        //                     }
        //                 });

        //                 describe("Shares calculations", () => {
        //                     test("Should set band shares", () => {
        //                         let bandId = 0;
        //                         for (let i = 0; i < stakersCount; i++) {
        //                             const bandsWithLevels = stakerBands[i];
        //                             const stakerBandsCount = bandsWithLevels.length;

        //                             for (let j = 0; j < stakerBandsCount; j++) {
        //                                 assert.fieldEquals(
        //                                     "Band",
        //                                     ids[bandId],
        //                                     "sharesAmount",
        //                                     sharesInMonths[bandId].toString(),
        //                                 );
        //                             }
        //                         }
        //                     });

        //                     test("Should set staker FIXED shares", () => {
        //                         for (let i = 0; i < stakersCount; i++) {
        //                             const staker = stakers[i].toHex();
        //                             assert.fieldEquals(
        //                                 "Staker",
        //                                 staker,
        //                                 "fixedSharesPerPool",
        //                                 convertBigIntArrayToString(allStakerFixedShares[i]),
        //                             );
        //                             assert.fieldEquals(
        //                                 "Staker",
        //                                 staker,
        //                                 "isolatedFixedSharesPerPool",
        //                                 convertBigIntArrayToString(allStakerIsolatedFixedShares[i]),
        //                             );
        //                         }
        //                     });

        //                     test("Should not set staker FLEXI shares", () => {
        //                         const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));
        //                         for (let i = 0; i < stakersCount; i++) {
        //                             const staker = stakers[i].toHex();
        //                             assert.fieldEquals("Staker", staker, "flexiSharesPerPool", stringifiedEmptyArray);
        //                             assert.fieldEquals(
        //                                 "Staker",
        //                                 staker,
        //                                 "isolatedFlexiSharesPerPool",
        //                                 stringifiedEmptyArray,
        //                             );
        //                         }
        //                     });

        //                     test("Should set pool FIXED shares", () => {
        //                         for (let i = 1; i <= totalPools.toI32(); i++) {
        //                             const totalFixedShares = allPoolTotalFixedShares[i - 1];
        //                             const totalIsolatedFixedShares = allPoolIsolatedFixedShares[i - 1];
        //                             assert.fieldEquals(
        //                                 "Pool",
        //                                 ids[i],
        //                                 "totalFixedSharesAmount",
        //                                 totalFixedShares.toString(),
        //                             );
        //                             assert.fieldEquals(
        //                                 "Pool",
        //                                 ids[i],
        //                                 "isolatedFixedSharesAmount",
        //                                 totalIsolatedFixedShares.toString(),
        //                             );
        //                         }
        //                     });

        //                     test("Should not set pool FLEXI shares", () => {
        //                         for (let i = 1; i <= totalPools.toI32(); i++) {
        //                             assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", "0");
        //                             assert.fieldEquals("Pool", ids[i], "isolatedFlexiSharesAmount", "0");
        //                         }
        //                     });
        //                 });
        //             });

        //             describe("Vested FIXED bands", () => {
        //                 beforeAll(() => {
        //                     areTokensVested = true;
        //                 });

        //                 beforeEach(() => {
        //                     let bandId = 0;
        //                     totalStaked = BIGINT_ZERO;

        //                     for (let i = 0; i < stakersCount; i++) {
        //                         const bands = stakerBands[i];
        //                         const bandsCount = bands.length;

        //                         for (let j = 0; j < bandsCount; j++) {
        //                             const bandLevel = bands[j];

        //                             stakeVestedFixed(
        //                                 stakers[i],
        //                                 bandLevel,
        //                                 bandIds[bandId],
        //                                 months[bandId + 1],
        //                                 monthsAfterInit[bandId + 1],
        //                             );
        //                             totalStaked = totalStaked.plus(bandLevelPrices[bandLevel.toI32() - 1]);
        //                             bandId++;
        //                         }
        //                     }

        //                     // Stake in all bands
        //                     for (let i = 0; i < totalBandLevels.toI32(); i++) {}
        //                 });

        //                 test("Should create new bands", () => {
        //                     assert.entityCount("Band", bandsCount);
        //                     for (let i = 0; i < bandsCount; i++) {
        //                         assert.fieldEquals("Band", ids[i], "id", ids[i]);
        //                     }
        //                 });

        //                 test("Should set band values correctly", () => {
        //                     let bandId = 0;

        //                     for (let i = 0; i < stakersCount; i++) {
        //                         const bands = stakerBands[i];
        //                         const stakerBandsCount = bands.length;

        //                         for (let j = 0; j < stakerBandsCount; j++) {
        //                             assert.fieldEquals("Band", ids[bandId], "owner", stakers[i].toHex());
        //                             assert.fieldEquals(
        //                                 "Band",
        //                                 ids[bandId],
        //                                 "stakingStartDate",
        //                                 monthsAfterInit[bandId + 1].toString(),
        //                             );
        //                             assert.fieldEquals("Band", ids[bandId], "bandLevel", bands[j].toString());
        //                             assert.fieldEquals(
        //                                 "Band",
        //                                 ids[bandId],
        //                                 "stakingType",
        //                                 stringifyStakingType(StakingType.FIX),
        //                             );
        //                             assert.fieldEquals(
        //                                 "Band",
        //                                 ids[bandId],
        //                                 "fixedMonths",
        //                                 months[bandId + 1].toString(),
        //                             );
        //                             assert.fieldEquals(
        //                                 "Band",
        //                                 ids[bandId],
        //                                 "areTokensVested",
        //                                 areTokensVested.toString(),
        //                             );

        //                             bandId++;
        //                         }
        //                     }
        //                 });

        //                 test("Should updated staking contract details", () => {
        //                     assert.fieldEquals(
        //                         "StakingContract",
        //                         ids[0],
        //                         "stakers",
        //                         convertAddressArrayToString(stakers),
        //                     );
        //                     assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
        //                     assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
        //                 });

        //                 test("Should update staker details", () => {
        //                     let bandId = 0;

        //                     for (let i = 0; i < stakersCount; i++) {
        //                         const staker = stakers[i].toHex();
        //                         const bandsWithLevels = stakerBands[i];
        //                         const stakerBandsCount = bandsWithLevels.length;
        //                         const bands: BigInt[] = [];
        //                         let stakedAmount: BigInt = BIGINT_ZERO;

        //                         for (let j = 0; j < stakerBandsCount; j++) {
        //                             stakedAmount = stakedAmount.plus(bandLevelPrices[bandsWithLevels[j].toI32() - 1]);
        //                             bands.push(BigInt.fromI32(bandId));
        //                             bandId++;
        //                         }

        //                         assert.fieldEquals("Staker", staker, "fixedBands", convertBigIntArrayToString(bands));
        //                         assert.fieldEquals("Staker", staker, "flexiBands", "[]");
        //                         assert.fieldEquals("Staker", staker, "bandsCount", stakerBandsCount.toString());
        //                         assert.fieldEquals("Staker", staker, "stakedAmount", stakedAmount.toString());
        //                     }
        //                 });

        //                 describe("Shares calculations", () => {
        //                     test("Should set band shares", () => {
        //                         let bandId = 0;
        //                         for (let i = 0; i < stakersCount; i++) {
        //                             const bandsWithLevels = stakerBands[i];
        //                             const stakerBandsCount = bandsWithLevels.length;

        //                             for (let j = 0; j < stakerBandsCount; j++) {
        //                                 assert.fieldEquals(
        //                                     "Band",
        //                                     ids[bandId],
        //                                     "sharesAmount",
        //                                     sharesInMonths[bandId].toString(),
        //                                 );
        //                             }
        //                         }
        //                     });

        //                     test("Should set staker FIXED shares", () => {
        //                         for (let i = 0; i < stakersCount; i++) {
        //                             const staker = stakers[i].toHex();
        //                             assert.fieldEquals(
        //                                 "Staker",
        //                                 staker,
        //                                 "fixedSharesPerPool",
        //                                 convertBigIntArrayToString(allStakerFixedShares[i]),
        //                             );
        //                             assert.fieldEquals(
        //                                 "Staker",
        //                                 staker,
        //                                 "isolatedFixedSharesPerPool",
        //                                 convertBigIntArrayToString(allStakerIsolatedFixedShares[i]),
        //                             );
        //                         }
        //                     });

        //                     test("Should not set staker FLEXI shares", () => {
        //                         const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));
        //                         for (let i = 0; i < stakersCount; i++) {
        //                             const staker = stakers[i].toHex();
        //                             assert.fieldEquals("Staker", staker, "flexiSharesPerPool", stringifiedEmptyArray);
        //                             assert.fieldEquals(
        //                                 "Staker",
        //                                 staker,
        //                                 "isolatedFlexiSharesPerPool",
        //                                 stringifiedEmptyArray,
        //                             );
        //                         }
        //                     });

        //                     test("Should set pool FIXED shares", () => {
        //                         for (let i = 1; i <= totalPools.toI32(); i++) {
        //                             const totalFixedShares = allPoolTotalFixedShares[i - 1];
        //                             const totalIsolatedFixedShares = allPoolIsolatedFixedShares[i - 1];
        //                             assert.fieldEquals(
        //                                 "Pool",
        //                                 ids[i],
        //                                 "totalFixedSharesAmount",
        //                                 totalFixedShares.toString(),
        //                             );
        //                             assert.fieldEquals(
        //                                 "Pool",
        //                                 ids[i],
        //                                 "isolatedFixedSharesAmount",
        //                                 totalIsolatedFixedShares.toString(),
        //                             );
        //                         }
        //                     });

        //                     test("Should not set pool FLEXI shares", () => {
        //                         for (let i = 1; i <= totalPools.toI32(); i++) {
        //                             assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", "0");
        //                             assert.fieldEquals("Pool", ids[i], "isolatedFlexiSharesAmount", "0");
        //                         }
        //                     });
        //                 });
        //             });
        //         });
        //     });

        //     describe("Mixed FIXED bands (standard and vested)", () => {
        //         describe("4 stakers, 4 vested stakes + 4 standard stakes", () => {
        //             beforeAll(() => {
        //                 bandsCount = 8;
        //                 stakersCount = 4;
        //                 stakers = [alice, bob, charlie, dan];
        //                 stakerBands = [
        //                     [bandLevels[0]],
        //                     [bandLevels[3], bandLevels[1], bandLevels[1]],
        //                     [bandLevels[3], bandLevels[7], bandLevels[5]],
        //                     [bandLevels[8]],
        //                 ];
        //                 stakerTokensAreVested = [
        //                     [true],
        //                     [false, false, true],
        //                     [true, true, false],
        //                     [false]
        //                 ]

        //                 // Calculations for testing shares
        //                 allPoolTotalFixedShares = createEmptyArray(totalPools);
        //                 allPoolIsolatedFixedShares = createEmptyArray(totalPools);
        //                 allStakerFixedShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);
        //                 allStakerIsolatedFixedShares = createDoubleEmptyArray(BigInt.fromI32(stakersCount), totalPools);
        //                 let bandId = 0;

        //                 for (let i = 0; i < stakersCount; i++) {
        //                     const bands = stakerBands[i];
        //                     const bandsCount = bands.length;

        //                     for (let j = 0; j < bandsCount; j++) {
        //                         const bandLevel = bands[j].toI32() - 1;
        //                         const shares = sharesInMonths[bandId];

        //                         allStakerIsolatedFixedShares[i][bandLevel] =
        //                             allStakerIsolatedFixedShares[i][bandLevel].plus(shares);
        //                         allPoolIsolatedFixedShares[bandLevel] =
        //                             allPoolIsolatedFixedShares[bandLevel].plus(shares);

        //                         for (let k = 0; k < bandLevel + 1; k++) {
        //                             allStakerFixedShares[i][k] = allStakerFixedShares[i][k].plus(shares);
        //                             allPoolTotalFixedShares[k] = allPoolTotalFixedShares[k].plus(shares);
        //                         }

        //                         bandId++;
        //                     }
        //                 }
        //             });

        //             describe("Standard FIXED bands", () => {
        //                 beforeAll(() => {
        //                     areTokensVested = false;
        //                 });

        //                 beforeEach(() => {
        //                     let bandId = 0;
        //                     totalStaked = BIGINT_ZERO;

        //                     for (let i = 0; i < stakersCount; i++) {
        //                         const bands = stakerBands[i];
        //                         const bandsCount = bands.length;

        //                         for (let j = 0; j < bandsCount; j++) {
        //                             const bandLevel = bands[j];

        //                             if (stakerTokensAreVested[i][j]) {
        //                                 stakeVestedFixed(
        //                                     stakers[i],
        //                                     bandLevel,
        //                                     bandIds[bandId],
        //                                     months[bandId + 1],
        //                                     monthsAfterInit[bandId + 1],
        //                                 );
        //                             } else {
        //                                 stakeStandardFixed(
        //                                     stakers[i],
        //                                     bandLevel,
        //                                     bandIds[bandId],
        //                                     months[bandId + 1],
        //                                     monthsAfterInit[bandId + 1],
        //                                 );
        //                             }
        //                             totalStaked = totalStaked.plus(bandLevelPrices[bandLevel.toI32() - 1]);
        //                             bandId++;
        //                         }
        //                     }

        //                     // Stake in all bands
        //                     for (let i = 0; i < totalBandLevels.toI32(); i++) {}
        //                 });

        //                 test("Should create new bands", () => {
        //                     assert.entityCount("Band", bandsCount);
        //                     for (let i = 0; i < bandsCount; i++) {
        //                         assert.fieldEquals("Band", ids[i], "id", ids[i]);
        //                     }
        //                 });

        //                 test("Should set band values correctly", () => {
        //                     let bandId = 0;

        //                     for (let i = 0; i < stakersCount; i++) {
        //                         const bands = stakerBands[i];
        //                         const stakerBandsCount = bands.length;

        //                         for (let j = 0; j < stakerBandsCount; j++) {
        //                             assert.fieldEquals("Band", ids[bandId], "owner", stakers[i].toHex());
        //                             assert.fieldEquals(
        //                                 "Band",
        //                                 ids[bandId],
        //                                 "stakingStartDate",
        //                                 monthsAfterInit[bandId + 1].toString(),
        //                             );
        //                             assert.fieldEquals("Band", ids[bandId], "bandLevel", bands[j].toString());
        //                             assert.fieldEquals(
        //                                 "Band",
        //                                 ids[bandId],
        //                                 "stakingType",
        //                                 stringifyStakingType(StakingType.FIX),
        //                             );
        //                             assert.fieldEquals(
        //                                 "Band",
        //                                 ids[bandId],
        //                                 "fixedMonths",
        //                                 months[bandId + 1].toString(),
        //                             );
        //                             assert.fieldEquals(
        //                                 "Band",
        //                                 ids[bandId],
        //                                 "areTokensVested",
        //                                 stakerTokensAreVested[i][j].toString(),
        //                             );

        //                             bandId++;
        //                         }
        //                     }
        //                 });

        //                 test("Should updated staking contract details", () => {
        //                     assert.fieldEquals(
        //                         "StakingContract",
        //                         ids[0],
        //                         "stakers",
        //                         convertAddressArrayToString(stakers),
        //                     );
        //                     assert.fieldEquals("StakingContract", ids[0], "nextBandId", bandsCount.toString());
        //                     assert.fieldEquals("StakingContract", ids[0], "totalStakedAmount", totalStaked.toString());
        //                 });

        //                 test("Should update staker details", () => {
        //                     let bandId = 0;

        //                     for (let i = 0; i < stakersCount; i++) {
        //                         const staker = stakers[i].toHex();
        //                         const bandsWithLevels = stakerBands[i];
        //                         const stakerBandsCount = bandsWithLevels.length;
        //                         const bands: BigInt[] = [];
        //                         let stakedAmount: BigInt = BIGINT_ZERO;

        //                         for (let j = 0; j < stakerBandsCount; j++) {
        //                             stakedAmount = stakedAmount.plus(bandLevelPrices[bandsWithLevels[j].toI32() - 1]);
        //                             bands.push(BigInt.fromI32(bandId));
        //                             bandId++;
        //                         }

        //                         assert.fieldEquals("Staker", staker, "fixedBands", convertBigIntArrayToString(bands));
        //                         assert.fieldEquals("Staker", staker, "flexiBands", "[]");
        //                         assert.fieldEquals("Staker", staker, "bandsCount", stakerBandsCount.toString());
        //                         assert.fieldEquals("Staker", staker, "stakedAmount", stakedAmount.toString());
        //                     }
        //                 });

        //                 describe("Shares calculations", () => {
        //                     test("Should set band shares", () => {
        //                         let bandId = 0;
        //                         for (let i = 0; i < stakersCount; i++) {
        //                             const bandsWithLevels = stakerBands[i];
        //                             const stakerBandsCount = bandsWithLevels.length;

        //                             for (let j = 0; j < stakerBandsCount; j++) {
        //                                 assert.fieldEquals(
        //                                     "Band",
        //                                     ids[bandId],
        //                                     "sharesAmount",
        //                                     sharesInMonths[bandId].toString(),
        //                                 );
        //                             }
        //                         }
        //                     });

        //                     test("Should set staker FIXED shares", () => {
        //                         for (let i = 0; i < stakersCount; i++) {
        //                             const staker = stakers[i].toHex();
        //                             assert.fieldEquals(
        //                                 "Staker",
        //                                 staker,
        //                                 "fixedSharesPerPool",
        //                                 convertBigIntArrayToString(allStakerFixedShares[i]),
        //                             );
        //                             assert.fieldEquals(
        //                                 "Staker",
        //                                 staker,
        //                                 "isolatedFixedSharesPerPool",
        //                                 convertBigIntArrayToString(allStakerIsolatedFixedShares[i]),
        //                             );
        //                         }
        //                     });

        //                     test("Should not set staker FLEXI shares", () => {
        //                         const stringifiedEmptyArray = convertBigIntArrayToString(createEmptyArray(totalPools));
        //                         for (let i = 0; i < stakersCount; i++) {
        //                             const staker = stakers[i].toHex();
        //                             assert.fieldEquals("Staker", staker, "flexiSharesPerPool", stringifiedEmptyArray);
        //                             assert.fieldEquals(
        //                                 "Staker",
        //                                 staker,
        //                                 "isolatedFlexiSharesPerPool",
        //                                 stringifiedEmptyArray,
        //                             );
        //                         }
        //                     });

        //                     test("Should set pool FIXED shares", () => {
        //                         for (let i = 1; i <= totalPools.toI32(); i++) {
        //                             const totalFixedShares = allPoolTotalFixedShares[i - 1];
        //                             const totalIsolatedFixedShares = allPoolIsolatedFixedShares[i - 1];
        //                             assert.fieldEquals(
        //                                 "Pool",
        //                                 ids[i],
        //                                 "totalFixedSharesAmount",
        //                                 totalFixedShares.toString(),
        //                             );
        //                             assert.fieldEquals(
        //                                 "Pool",
        //                                 ids[i],
        //                                 "isolatedFixedSharesAmount",
        //                                 totalIsolatedFixedShares.toString(),
        //                             );
        //                         }
        //                     });

        //                     test("Should not set pool FLEXI shares", () => {
        //                         for (let i = 1; i <= totalPools.toI32(); i++) {
        //                             assert.fieldEquals("Pool", ids[i], "totalFlexiSharesAmount", "0");
        //                             assert.fieldEquals("Pool", ids[i], "isolatedFlexiSharesAmount", "0");
        //                         }
        //                     });
        //                 });
        //             });
        //         });
        //     });
        // });

        describe("Only FLEXI bands", () => {
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

                        let shares = BIGINT_ZERO;
                        if (month > 0) {
                            shares = sharesInMonths[month - 1];
                        }

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
                            assert.fieldEquals("Band", ids[i], "stakingStartDate", monthsAfterInit[i + 1].toString());
                            assert.fieldEquals("Band", ids[i], "bandLevel", bandLevels[i].toString());
                            assert.fieldEquals("Band", ids[i], "stakingType", stringifyStakingType(StakingType.FLEXI));
                            assert.fieldEquals("Band", ids[i], "fixedMonths", "0");
                            assert.fieldEquals("Band", ids[i], "areTokensVested", areTokensVested.toString());
                        }
                    });

                    test("Should updated staking contract details", () => {
                        assert.fieldEquals("StakingContract", ids[0], "stakers", convertAddressArrayToString(users));
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

                                let shares = BIGINT_ZERO;
                                if (month > 0) {
                                    shares = sharesInMonths[month - 1];
                                }

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
                            assert.fieldEquals("Band", ids[i], "stakingStartDate", monthsAfterInit[i + 1].toString());
                            assert.fieldEquals("Band", ids[i], "bandLevel", bandLevels[i].toString());
                            assert.fieldEquals("Band", ids[i], "stakingType", stringifyStakingType(StakingType.FLEXI));
                            assert.fieldEquals("Band", ids[i], "fixedMonths", "0");
                            assert.fieldEquals("Band", ids[i], "areTokensVested", areTokensVested.toString());
                        }
                    });

                    test("Should updated staking contract details", () => {
                        assert.fieldEquals("StakingContract", ids[0], "stakers", convertAddressArrayToString(users));
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

                                let shares = BIGINT_ZERO;
                                if (month > 0) {
                                    shares = sharesInMonths[month - 1];
                                }

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

                        let shares = BIGINT_ZERO;
                        if (month > 0) {
                            shares = sharesInMonths[month - 1];
                        }

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
                            assert.fieldEquals("Band", ids[i], "stakingStartDate", monthsAfterInit[i + 1].toString());
                            assert.fieldEquals("Band", ids[i], "bandLevel", bandLevels[i].toString());
                            assert.fieldEquals("Band", ids[i], "stakingType", stringifyStakingType(StakingType.FLEXI));
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

                                let shares = BIGINT_ZERO;
                                if (month > 0) {
                                    shares = sharesInMonths[month - 1];
                                }

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
                            assert.fieldEquals("Band", ids[i], "stakingStartDate", monthsAfterInit[i + 1].toString());
                            assert.fieldEquals("Band", ids[i], "bandLevel", bandLevels[i].toString());
                            assert.fieldEquals("Band", ids[i], "stakingType", stringifyStakingType(StakingType.FLEXI));
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

                                let shares = BIGINT_ZERO;
                                if (month > 0) {
                                    shares = sharesInMonths[month - 1];
                                }

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

            describe("3 stakers, 1 staker with flexi band level 1, 1 staker with flexi band different levels (4, 5, 6), 1 staker with flexi band level 9", () => {});

            describe("Mixed FLEXI bands", () => {
                describe("3 stakers, 1 staker with standard flexi band level 1, 1 staker with standard flexi band levels 4 and vested flexi band levels 6, 1 staker with vested flexi band level 9", () => {});
            });
        });

        describe("All Mixed bands", () => {
            describe("5 stakers, 1 staker with standard fixed band level 1, 1 staker with standard flexi band level 2, 1 staker with vested fixed band level 3, 1 staker with vested flexi band level 4, 1 staker with standard fixed (lvl 6), standard flexi (lvl 7), vested fixed (lvl 8), vested flexi (lvl 9)", () => {});
        });
    });
});
