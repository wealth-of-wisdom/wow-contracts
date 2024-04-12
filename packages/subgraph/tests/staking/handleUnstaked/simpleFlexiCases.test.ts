import { Address, BigInt, log } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, beforeAll, afterEach, clearStore, assert } from "matchstick-as/assembly/index";
import {
    initializeAndSetUp,
    stakeStandardFixed,
    stakeStandardFlexi,
    stakeVestedFixed,
    unstakeStandard,
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
import { BIGINT_ONE, BIGINT_ZERO } from "../../../src/utils/constants";

let stakedBandsCount = 0;
let unstakedBandsCount = 0;
let stakersCount = 0;
let shares: BigInt;
let stakers: Address[];
let fixedMonths: BigInt = BigInt.fromI32(20);
let bandLevel = 0;
let totalStaked: BigInt;
let totalUnstaked: BigInt;
let totalShares: BigInt;
let areTokensVested: boolean;
let stakedBandsArray: BigInt[];
let unstakedBandsArray: BigInt[];
let expectedLeftBands: BigInt[];

// Flexi bands data
let flexiStakerSharesPerPool: BigInt[];
let isolatedFlexiSharesPerPool: BigInt[];

describe("handleUnstaked()", () => {
    beforeEach(() => {
        clearStore();
        initializeAndSetUp();
    });

    describe("Simple cases", () => {
        describe("Only FLEXI bands", () => {
            describe("1 Staker", () => {
                beforeAll(() => {
                    stakersCount = 1;
                });

                afterEach(() => {
                    /*//////////////////////////////////////////////////////////////////////////
                                                GET ASSERION DATA
                    //////////////////////////////////////////////////////////////////////////*/

                    const emptySharesArray = convertBigIntArrayToString(createEmptyArray(totalPools));

                    shares = sharesInMonths[0];
                    totalShares = shares.times(BigInt.fromI32(stakedBandsCount - unstakedBandsCount));

                    flexiStakerSharesPerPool = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

                    isolatedFlexiSharesPerPool = createEmptyArray(totalPools);
                    isolatedFlexiSharesPerPool[bandLevel - 1] = totalShares;

                    /*//////////////////////////////////////////////////////////////////////////
                                                  ASSERT MAIN DATA
                    //////////////////////////////////////////////////////////////////////////*/

                    log.debug("Should reduce total staked amount", []);
                    assert.fieldEquals(
                        "StakingContract",
                        ids[0],
                        "totalStakedAmount",
                        totalStaked.minus(totalUnstaked).toString(),
                    );

                    const leftBands = stakedBandsCount - unstakedBandsCount;

                    if (leftBands === 0) {
                        log.debug("Should remove staker from all stakers array", []);
                        assert.fieldEquals("StakingContract", ids[0], "stakers", "[]");

                        log.debug("Should remove staker entity", []);
                        assert.notInStore("Staker", alice.toHex());
                        assert.entityCount("Staker", 0);
                    } else {
                        log.debug("Should remove band from staker bands array", []);
                        assert.fieldEquals("Staker", alice.toHex(), "fixedBands", "[]");
                        assert.fieldEquals(
                            "Staker",
                            alice.toHex(),
                            "flexiBands",
                            convertBigIntArrayToString(expectedLeftBands),
                        );
                        assert.fieldEquals("Staker", alice.toHex(), "bandsCount", leftBands.toString());

                        log.debug("Should reduce staker's staked amount", []);
                        assert.fieldEquals(
                            "Staker",
                            alice.toHex(),
                            "stakedAmount",
                            totalStaked.minus(totalUnstaked).toString(),
                        );
                    }

                    log.debug("Should remove band entity", []);
                    for (let i = 0; i < unstakedBandsCount; i++) {
                        const id = unstakedBandsArray[i].toString();
                        assert.notInStore("Band", id);
                    }
                    assert.entityCount("Band", leftBands);

                    /*//////////////////////////////////////////////////////////////////////////
                                                    ASSERT SHARES
                    //////////////////////////////////////////////////////////////////////////*/

                    if (stakedBandsCount !== unstakedBandsCount) {
                        log.debug("Should not update staker fixed shares", []);
                        assert.fieldEquals("Staker", alice.toHex(), "fixedSharesPerPool", emptySharesArray);
                        assert.fieldEquals("Staker", alice.toHex(), "isolatedFixedSharesPerPool", emptySharesArray);

                        log.debug("Should update staker flexi shares", []);
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
                    }

                    log.debug("Should not update pool fixed shares", []);
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", "0");
                        assert.fieldEquals("Pool", ids[i], "isolatedFixedSharesAmount", "0");
                    }

                    log.debug("Should update pool flexi shares", []);
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        log.debug("Pool id: {}", [i.toString()]);
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
                });

                describe("Single band level", () => {
                    describe("Standard staking", () => {
                        beforeAll(() => {
                            areTokensVested = false;
                        });

                        afterEach(() => {
                            stakedBandsCount = stakedBandsArray.length;
                            unstakedBandsCount = unstakedBandsArray.length;

                            // Staker stakes in the accessible pool of the band level
                            totalStaked = BIGINT_ZERO;
                            for (let i = 0; i < stakedBandsCount; i++) {
                                stakeStandardFlexi(
                                    alice,
                                    bandLevels[bandLevel - 1],
                                    stakedBandsArray[i],
                                    monthsAfterInit[1],
                                );
                                totalStaked = totalStaked.plus(bandLevelPrices[bandLevel - 1]);
                            }

                            // Staker unstakes from the band level
                            totalUnstaked = BIGINT_ZERO;
                            for (let i = 0; i < unstakedBandsCount; i++) {
                                unstakeStandard(alice, unstakedBandsArray[i], monthsAfterInit[2]);
                                totalUnstaked = totalUnstaked.plus(bandLevelPrices[bandLevel - 1]);
                            }
                        });

                        describe("Band level 1", () => {
                            beforeAll(() => {
                                bandLevel = 1;
                            });

                            test("1 FLEXI band staked", () => {
                                stakedBandsArray = [bandIds[0]];
                                unstakedBandsArray = [bandIds[0]];
                                expectedLeftBands = [];
                            });

                            describe("2 FLEXI bands staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                });

                                test("1 band unstaked (with id 0)", () => {
                                    unstakedBandsArray = [bandIds[0]];
                                    expectedLeftBands = [bandIds[1]];
                                });

                                test("1 band unstaked (with id 1)", () => {
                                    unstakedBandsArray = [bandIds[1]];
                                    expectedLeftBands = [bandIds[0]];
                                });

                                test("2 bands unstaked", () => {
                                    unstakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                    expectedLeftBands = [];
                                });
                            });

                            describe("3 FLEXI bands", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                });

                                test("1 band unstaked (with id 0)", () => {
                                    unstakedBandsArray = [bandIds[0]];
                                    // When popping last item (we copy the last element to the removed one)
                                    expectedLeftBands = createArray(bandIds[1], bandIds[2]).reverse();
                                });

                                test("1 band unstaked (with id 1)", () => {
                                    unstakedBandsArray = [bandIds[1]];
                                    expectedLeftBands = [bandIds[0], bandIds[2]];
                                });

                                test("1 band unstaked (with id 2)", () => {
                                    unstakedBandsArray = [bandIds[2]];
                                    expectedLeftBands = createArray(bandIds[0], bandIds[1]);
                                });

                                test("2 bands unstaked (with ids 0, 1)", () => {
                                    unstakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                    expectedLeftBands = [bandIds[2]];
                                });

                                test("2 bands unstaked (with ids 1, 2)", () => {
                                    unstakedBandsArray = createArray(bandIds[1], bandIds[2]);
                                    expectedLeftBands = [bandIds[0]];
                                });

                                test("2 bands unstaked (with ids 0, 2)", () => {
                                    unstakedBandsArray = [bandIds[0], bandIds[2]];
                                    expectedLeftBands = [bandIds[1]];
                                });

                                test("3 bands unstaked (with ids 0, 1, 2)", () => {
                                    unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                    expectedLeftBands = [];
                                });
                            });
                        });
                    });
                });
            });
        });
    });
});
