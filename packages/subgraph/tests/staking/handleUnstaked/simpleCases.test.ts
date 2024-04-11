import { Address, BigInt, Bytes, log } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, beforeAll, afterEach, clearStore, assert } from "matchstick-as/assembly/index";
import {
    initializeAndSetUp,
    stakeStandardFixed,
    stakeStandardFlexi,
    stakeVestedFixed,
    stakeVestedFlexi,
    triggerSharesSync,
    unstakeStandard,
    unstakeVested,
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
                    totalShares = shares.times(BigInt.fromI32(stakedBandsCount - unstakedBandsCount));

                    fixedStakerSharesPerPool = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

                    isolatedFixedSharesPerPool = createEmptyArray(totalPools);
                    isolatedFixedSharesPerPool[bandLevel - 1] = totalShares;

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
                    } else {
                        log.debug("Should remove band from staker bands array", []);
                        assert.fieldEquals(
                            "Staker",
                            alice.toHex(),
                            "fixedBands",
                            convertBigIntArrayToString(expectedLeftBands),
                        );
                        assert.fieldEquals("Staker", alice.toHex(), "flexiBands", "[]");
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
                        log.debug("Should update staker fixed shares", []);
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

                        log.debug("Should not update staker flexi shares", []);
                        assert.fieldEquals("Staker", alice.toHex(), "flexiSharesPerPool", emptySharesArray);
                        assert.fieldEquals("Staker", alice.toHex(), "isolatedFlexiSharesPerPool", emptySharesArray);
                    }

                    log.debug("Should update pool fixed shares", []);
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

                    log.debug("Should not update pool flexi shares", []);
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
                            stakedBandsCount = stakedBandsArray.length;
                            unstakedBandsCount = unstakedBandsArray.length;

                            // Staker stakes in the accessible pool of the band level
                            totalStaked = BIGINT_ZERO;
                            for (let i = 0; i < stakedBandsCount; i++) {
                                stakeStandardFixed(
                                    alice,
                                    bandLevels[bandLevel - 1],
                                    stakedBandsArray[i],
                                    fixedMonths,
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

                            describe("1 FIXED band staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = [bandIds[0]];
                                });

                                describe("1 band unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0]];
                                        expectedLeftBands = [];
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

                            describe("2 FIXED bands staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0]];
                                        expectedLeftBands = [bandIds[1]];
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[1]];
                                        expectedLeftBands = [bandIds[0]];
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

                                describe("2 bands unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                        expectedLeftBands = [];
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

                            describe("3 FIXED bands", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0]];
                                        // When popping last item (we copy the last element to the removed one)
                                        expectedLeftBands = createArray(bandIds[1], bandIds[2]).reverse();
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[1]];
                                        expectedLeftBands = [bandIds[0], bandIds[2]];
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

                                describe("1 band unstaked (with id 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[2]];
                                        expectedLeftBands = createArray(bandIds[0], bandIds[1]);
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

                                describe("2 bands unstaked (with ids 0, 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                        expectedLeftBands = [bandIds[2]];
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

                                describe("2 bands unstaked (with ids 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[1], bandIds[2]);
                                        expectedLeftBands = [bandIds[0]];
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

                                describe("2 bands unstaked (with ids 0, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0], bandIds[2]];
                                        expectedLeftBands = [bandIds[1]];
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

                                describe("3 bands unstaked (with ids 0, 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        expectedLeftBands = [];
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

                        describe("Band level 5", () => {
                            beforeAll(() => {
                                bandLevel = 5;
                            });

                            describe("1 FIXED band staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = [bandIds[0]];
                                });

                                describe("1 band unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0]];
                                        expectedLeftBands = [];
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

                            describe("2 FIXED bands staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0]];
                                        expectedLeftBands = [bandIds[1]];
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[1]];
                                        expectedLeftBands = [bandIds[0]];
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

                                describe("2 bands unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                        expectedLeftBands = [];
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

                            describe("3 FIXED bands", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0]];
                                        // When popping last item (we copy the last element to the removed one)
                                        expectedLeftBands = createArray(bandIds[1], bandIds[2]).reverse();
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[1]];
                                        expectedLeftBands = [bandIds[0], bandIds[2]];
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

                                describe("1 band unstaked (with id 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[2]];
                                        expectedLeftBands = createArray(bandIds[0], bandIds[1]);
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

                                describe("2 bands unstaked (with ids 0, 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                        expectedLeftBands = [bandIds[2]];
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

                                describe("2 bands unstaked (with ids 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[1], bandIds[2]);
                                        expectedLeftBands = [bandIds[0]];
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

                                describe("2 bands unstaked (with ids 0, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0], bandIds[2]];
                                        expectedLeftBands = [bandIds[1]];
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

                                describe("3 bands unstaked (with ids 0, 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        expectedLeftBands = [];
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

                        describe("Band level 9", () => {
                            beforeAll(() => {
                                bandLevel = 9;
                            });

                            describe("1 FIXED band staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = [bandIds[0]];
                                });

                                describe("1 band unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0]];
                                        expectedLeftBands = [];
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

                            describe("2 FIXED bands staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0]];
                                        expectedLeftBands = [bandIds[1]];
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[1]];
                                        expectedLeftBands = [bandIds[0]];
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

                                describe("2 bands unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                        expectedLeftBands = [];
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

                            describe("3 FIXED bands", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0]];
                                        // When popping last item (we copy the last element to the removed one)
                                        expectedLeftBands = createArray(bandIds[1], bandIds[2]).reverse();
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[1]];
                                        expectedLeftBands = [bandIds[0], bandIds[2]];
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

                                describe("1 band unstaked (with id 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[2]];
                                        expectedLeftBands = createArray(bandIds[0], bandIds[1]);
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

                                describe("2 bands unstaked (with ids 0, 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                        expectedLeftBands = [bandIds[2]];
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

                                describe("2 bands unstaked (with ids 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[1], bandIds[2]);
                                        expectedLeftBands = [bandIds[0]];
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

                                describe("2 bands unstaked (with ids 0, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0], bandIds[2]];
                                        expectedLeftBands = [bandIds[1]];
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

                                describe("3 bands unstaked (with ids 0, 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        expectedLeftBands = [];
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

                    describe("Vested staking", () => {
                        beforeAll(() => {
                            areTokensVested = true;
                        });

                        afterEach(() => {
                            stakedBandsCount = stakedBandsArray.length;
                            unstakedBandsCount = unstakedBandsArray.length;

                            // Staker stakes in the accessible pool of the band level
                            totalStaked = BIGINT_ZERO;
                            for (let i = 0; i < stakedBandsCount; i++) {
                                stakeVestedFixed(
                                    alice,
                                    bandLevels[bandLevel - 1],
                                    stakedBandsArray[i],
                                    fixedMonths,
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

                            describe("1 FIXED band staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = [bandIds[0]];
                                });

                                describe("1 band unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0]];
                                        expectedLeftBands = [];
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

                            describe("2 FIXED bands staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0]];
                                        expectedLeftBands = [bandIds[1]];
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[1]];
                                        expectedLeftBands = [bandIds[0]];
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

                                describe("2 bands unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                        expectedLeftBands = [];
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

                            describe("3 FIXED bands", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0]];
                                        // When popping last item (we copy the last element to the removed one)
                                        expectedLeftBands = createArray(bandIds[1], bandIds[2]).reverse();
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[1]];
                                        expectedLeftBands = [bandIds[0], bandIds[2]];
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

                                describe("1 band unstaked (with id 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[2]];
                                        expectedLeftBands = createArray(bandIds[0], bandIds[1]);
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

                                describe("2 bands unstaked (with ids 0, 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                        expectedLeftBands = [bandIds[2]];
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

                                describe("2 bands unstaked (with ids 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[1], bandIds[2]);
                                        expectedLeftBands = [bandIds[0]];
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

                                describe("2 bands unstaked (with ids 0, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0], bandIds[2]];
                                        expectedLeftBands = [bandIds[1]];
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

                                describe("3 bands unstaked (with ids 0, 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        expectedLeftBands = [];
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

                        describe("Band level 5", () => {
                            beforeAll(() => {
                                bandLevel = 5;
                            });

                            describe("1 FIXED band staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = [bandIds[0]];
                                });

                                describe("1 band unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0]];
                                        expectedLeftBands = [];
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

                            describe("2 FIXED bands staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0]];
                                        expectedLeftBands = [bandIds[1]];
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[1]];
                                        expectedLeftBands = [bandIds[0]];
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

                                describe("2 bands unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                        expectedLeftBands = [];
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

                            describe("3 FIXED bands", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0]];
                                        // When popping last item (we copy the last element to the removed one)
                                        expectedLeftBands = createArray(bandIds[1], bandIds[2]).reverse();
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[1]];
                                        expectedLeftBands = [bandIds[0], bandIds[2]];
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

                                describe("1 band unstaked (with id 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[2]];
                                        expectedLeftBands = createArray(bandIds[0], bandIds[1]);
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

                                describe("2 bands unstaked (with ids 0, 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                        expectedLeftBands = [bandIds[2]];
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

                                describe("2 bands unstaked (with ids 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[1], bandIds[2]);
                                        expectedLeftBands = [bandIds[0]];
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

                                describe("2 bands unstaked (with ids 0, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0], bandIds[2]];
                                        expectedLeftBands = [bandIds[1]];
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

                                describe("3 bands unstaked (with ids 0, 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        expectedLeftBands = [];
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

                        describe("Band level 9", () => {
                            beforeAll(() => {
                                bandLevel = 9;
                            });

                            describe("1 FIXED band staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = [bandIds[0]];
                                });

                                describe("1 band unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0]];
                                        expectedLeftBands = [];
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

                            describe("2 FIXED bands staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0]];
                                        expectedLeftBands = [bandIds[1]];
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[1]];
                                        expectedLeftBands = [bandIds[0]];
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

                                describe("2 bands unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                        expectedLeftBands = [];
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

                            describe("3 FIXED bands", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0]];
                                        // When popping last item (we copy the last element to the removed one)
                                        expectedLeftBands = createArray(bandIds[1], bandIds[2]).reverse();
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[1]];
                                        expectedLeftBands = [bandIds[0], bandIds[2]];
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

                                describe("1 band unstaked (with id 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[2]];
                                        expectedLeftBands = createArray(bandIds[0], bandIds[1]);
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

                                describe("2 bands unstaked (with ids 0, 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[1]);
                                        expectedLeftBands = [bandIds[2]];
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

                                describe("2 bands unstaked (with ids 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[1], bandIds[2]);
                                        expectedLeftBands = [bandIds[0]];
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

                                describe("2 bands unstaked (with ids 0, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [bandIds[0], bandIds[2]];
                                        expectedLeftBands = [bandIds[1]];
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

                                describe("3 bands unstaked (with ids 0, 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        expectedLeftBands = [];
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
            });

            describe("3 Staker", () => {
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
                    totalShares = shares.times(BigInt.fromI32(stakedBandsCount - unstakedBandsCount));

                    fixedStakerSharesPerPool = createEmptyArray(totalPools).fill(totalShares, 0, bandLevel);

                    isolatedFixedSharesPerPool = createEmptyArray(totalPools);
                    isolatedFixedSharesPerPool[bandLevel - 1] = totalShares;

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

                    if (stakedBandsCount - unstakedBandsCount === 0) {
                        log.debug("Should remove staker from all stakers array", []);
                        assert.fieldEquals("StakingContract", ids[0], "stakers", "[]");

                        log.debug("Should remove staker entity", []);
                        for (let i = 0; i < stakersCount; i++) {
                            assert.notInStore("Staker", stakers[i].toHex());
                        }
                    } else {
                        log.debug("Should remove band from staker bands array", []);
                        for (let i = 0; i < stakersCount; i++) {
                            const staker = stakers[i].toHex();
                            const stakerBandsCount = expectedLeftBands.length / stakersCount;
                            const bands: BigInt[] = [];

                            for (let j = 0; j < stakerBandsCount; j++) {
                                bands.push(expectedLeftBands[i * stakerBandsCount + j]);
                            }

                            assert.fieldEquals("Staker", staker, "fixedBands", convertBigIntArrayToString(bands));
                            assert.fieldEquals("Staker", staker, "flexiBands", "[]");
                            assert.fieldEquals("Staker", staker, "bandsCount", stakerBandsCount.toString());

                            let stakedAmount = totalStaked.minus(totalUnstaked);
                            if (stakedAmount.notEqual(BIGINT_ZERO)) {
                                stakedAmount = stakedAmount.div(BigInt.fromI32(stakersCount));
                            }

                            assert.fieldEquals("Staker", staker, "stakedAmount", stakedAmount.toString());
                        }
                    }

                    log.debug("Should remove band entity", []);
                    for (let i = 0; i < unstakedBandsCount * stakersCount; i++) {
                        const id = unstakedBandsArray[i].toString();
                        assert.notInStore("Band", id);
                    }
                    assert.entityCount("Band", stakersCount * (stakedBandsCount - unstakedBandsCount));

                    /*//////////////////////////////////////////////////////////////////////////
                                                    ASSERT SHARES
                    //////////////////////////////////////////////////////////////////////////*/

                    if (stakedBandsCount !== unstakedBandsCount) {
                        log.debug("Should update staker fixed shares", []);
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

                        log.debug("Should not update staker flexi shares", []);
                        assert.fieldEquals("Staker", alice.toHex(), "flexiSharesPerPool", emptySharesArray);
                        assert.fieldEquals("Staker", alice.toHex(), "isolatedFlexiSharesPerPool", emptySharesArray);
                    }

                    log.debug("Should update pool fixed shares", []);
                    for (let i = 1; i <= totalPools.toI32(); i++) {
                        const poolShares = fixedStakerSharesPerPool[i - 1].times(BigInt.fromI32(stakersCount));
                        const isolatedPoolShares = isolatedFixedSharesPerPool[i - 1].times(
                            BigInt.fromI32(stakersCount),
                        );
                        assert.fieldEquals("Pool", ids[i], "totalFixedSharesAmount", poolShares.toString());
                        assert.fieldEquals("Pool", ids[i], "isolatedFixedSharesAmount", isolatedPoolShares.toString());
                    }

                    log.debug("Should not update pool flexi shares", []);
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
                            stakedBandsCount = stakedBandsArray.length / stakersCount;
                            unstakedBandsCount = unstakedBandsArray.length / stakersCount;

                            // Staker stakes in the accessible pool of the band level
                            totalStaked = bandLevelPrices[bandLevel - 1]
                                .times(BigInt.fromI32(stakedBandsCount))
                                .times(BigInt.fromI32(stakersCount));

                            for (let i = 0; i < stakedBandsCount; i++) {
                                for (let j = 0; j < stakersCount; j++) {
                                    stakeStandardFixed(
                                        stakers[j],
                                        bandLevels[bandLevel - 1],
                                        stakedBandsArray[i * stakersCount + j],
                                        fixedMonths,
                                        monthsAfterInit[1],
                                    );
                                }
                            }

                            // Staker unstakes from the band level
                            totalUnstaked = bandLevelPrices[bandLevel - 1]
                                .times(BigInt.fromI32(unstakedBandsCount))
                                .times(BigInt.fromI32(stakersCount));

                            for (let i = 0; i < unstakedBandsCount; i++) {
                                for (let j = 0; j < stakersCount; j++) {
                                    unstakeStandard(
                                        stakers[j],
                                        unstakedBandsArray[i * stakersCount + j],
                                        monthsAfterInit[2],
                                    );
                                }
                            }
                        });

                        describe("Band level 1", () => {
                            beforeAll(() => {
                                bandLevel = 1;
                            });

                            describe("1 FIXED band staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                });

                                describe("1 band unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        expectedLeftBands = [];
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

                            describe("2 FIXED bands staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[5]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        expectedLeftBands = createArray(bandIds[3], bandIds[5]);
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[3], bandIds[5]);
                                        expectedLeftBands = createArray(bandIds[0], bandIds[2]);
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

                                describe("2 bands unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[5]);
                                        expectedLeftBands = [];
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

                            describe("3 FIXED bands", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[8]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        // When popping last item (we copy the last element to the removed one)
                                        expectedLeftBands = [
                                            bandIds[6],
                                            bandIds[3],
                                            bandIds[7],
                                            bandIds[4],
                                            bandIds[8],
                                            bandIds[5],
                                        ];
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[3], bandIds[5]);
                                        expectedLeftBands = [
                                            bandIds[0],
                                            bandIds[6],
                                            bandIds[1],
                                            bandIds[7],
                                            bandIds[2],
                                            bandIds[8],
                                        ];
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

                                describe("1 band unstaked (with id 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[6], bandIds[8]);
                                        expectedLeftBands = [
                                            bandIds[0],
                                            bandIds[3],
                                            bandIds[1],
                                            bandIds[4],
                                            bandIds[2],
                                            bandIds[5],
                                        ];
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

                                describe("2 bands unstaked (with ids 0, 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[5]);
                                        expectedLeftBands = createArray(bandIds[6], bandIds[8]);
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

                                describe("2 bands unstaked (with ids 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[3], bandIds[8]);
                                        expectedLeftBands = createArray(bandIds[0], bandIds[2]);
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

                                describe("2 bands unstaked (with ids 0, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [
                                            bandIds[0],
                                            bandIds[1],
                                            bandIds[2],
                                            bandIds[6],
                                            bandIds[7],
                                            bandIds[8],
                                        ];
                                        expectedLeftBands = createArray(bandIds[3], bandIds[5]);
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

                                describe("3 bands unstaked (with ids 0, 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[8]);
                                        expectedLeftBands = [];
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

                        describe("Band level 5", () => {
                            beforeAll(() => {
                                bandLevel = 5;
                            });

                            describe("1 FIXED band staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                });

                                describe("1 band unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        expectedLeftBands = [];
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

                            describe("2 FIXED bands staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[5]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        expectedLeftBands = createArray(bandIds[3], bandIds[5]);
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[3], bandIds[5]);
                                        expectedLeftBands = createArray(bandIds[0], bandIds[2]);
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

                                describe("2 bands unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[5]);
                                        expectedLeftBands = [];
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

                            describe("3 FIXED bands", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[8]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        // When popping last item (we copy the last element to the removed one)
                                        expectedLeftBands = [
                                            bandIds[6],
                                            bandIds[3],
                                            bandIds[7],
                                            bandIds[4],
                                            bandIds[8],
                                            bandIds[5],
                                        ];
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[3], bandIds[5]);
                                        expectedLeftBands = [
                                            bandIds[0],
                                            bandIds[6],
                                            bandIds[1],
                                            bandIds[7],
                                            bandIds[2],
                                            bandIds[8],
                                        ];
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

                                describe("1 band unstaked (with id 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[6], bandIds[8]);
                                        expectedLeftBands = [
                                            bandIds[0],
                                            bandIds[3],
                                            bandIds[1],
                                            bandIds[4],
                                            bandIds[2],
                                            bandIds[5],
                                        ];
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

                                describe("2 bands unstaked (with ids 0, 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[5]);
                                        expectedLeftBands = createArray(bandIds[6], bandIds[8]);
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

                                describe("2 bands unstaked (with ids 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[3], bandIds[8]);
                                        expectedLeftBands = createArray(bandIds[0], bandIds[2]);
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

                                describe("2 bands unstaked (with ids 0, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [
                                            bandIds[0],
                                            bandIds[1],
                                            bandIds[2],
                                            bandIds[6],
                                            bandIds[7],
                                            bandIds[8],
                                        ];
                                        expectedLeftBands = createArray(bandIds[3], bandIds[5]);
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

                                describe("3 bands unstaked (with ids 0, 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[8]);
                                        expectedLeftBands = [];
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

                        describe("Band level 9", () => {
                            beforeAll(() => {
                                bandLevel = 9;
                            });

                            describe("1 FIXED band staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                });

                                describe("1 band unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        expectedLeftBands = [];
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

                            describe("2 FIXED bands staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[5]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        expectedLeftBands = createArray(bandIds[3], bandIds[5]);
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[3], bandIds[5]);
                                        expectedLeftBands = createArray(bandIds[0], bandIds[2]);
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

                                describe("2 bands unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[5]);
                                        expectedLeftBands = [];
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

                            describe("3 FIXED bands", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[8]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        // When popping last item (we copy the last element to the removed one)
                                        expectedLeftBands = [
                                            bandIds[6],
                                            bandIds[3],
                                            bandIds[7],
                                            bandIds[4],
                                            bandIds[8],
                                            bandIds[5],
                                        ];
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[3], bandIds[5]);
                                        expectedLeftBands = [
                                            bandIds[0],
                                            bandIds[6],
                                            bandIds[1],
                                            bandIds[7],
                                            bandIds[2],
                                            bandIds[8],
                                        ];
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

                                describe("1 band unstaked (with id 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[6], bandIds[8]);
                                        expectedLeftBands = [
                                            bandIds[0],
                                            bandIds[3],
                                            bandIds[1],
                                            bandIds[4],
                                            bandIds[2],
                                            bandIds[5],
                                        ];
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

                                describe("2 bands unstaked (with ids 0, 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[5]);
                                        expectedLeftBands = createArray(bandIds[6], bandIds[8]);
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

                                describe("2 bands unstaked (with ids 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[3], bandIds[8]);
                                        expectedLeftBands = createArray(bandIds[0], bandIds[2]);
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

                                describe("2 bands unstaked (with ids 0, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [
                                            bandIds[0],
                                            bandIds[1],
                                            bandIds[2],
                                            bandIds[6],
                                            bandIds[7],
                                            bandIds[8],
                                        ];
                                        expectedLeftBands = createArray(bandIds[3], bandIds[5]);
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

                                describe("3 bands unstaked (with ids 0, 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[8]);
                                        expectedLeftBands = [];
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

                    describe("Vested staking", () => {
                        beforeAll(() => {
                            areTokensVested = true;
                        });

                        afterEach(() => {
                            stakedBandsCount = stakedBandsArray.length / stakersCount;
                            unstakedBandsCount = unstakedBandsArray.length / stakersCount;

                            // Staker stakes in the accessible pool of the band level
                            totalStaked = bandLevelPrices[bandLevel - 1]
                                .times(BigInt.fromI32(stakedBandsCount))
                                .times(BigInt.fromI32(stakersCount));

                            for (let i = 0; i < stakedBandsCount; i++) {
                                for (let j = 0; j < stakersCount; j++) {
                                    stakeVestedFixed(
                                        stakers[j],
                                        bandLevels[bandLevel - 1],
                                        stakedBandsArray[i * stakersCount + j],
                                        fixedMonths,
                                        monthsAfterInit[1],
                                    );
                                }
                            }

                            // Staker unstakes from the band level
                            totalUnstaked = bandLevelPrices[bandLevel - 1]
                                .times(BigInt.fromI32(unstakedBandsCount))
                                .times(BigInt.fromI32(stakersCount));

                            for (let i = 0; i < unstakedBandsCount; i++) {
                                for (let j = 0; j < stakersCount; j++) {
                                    unstakeStandard(
                                        stakers[j],
                                        unstakedBandsArray[i * stakersCount + j],
                                        monthsAfterInit[2],
                                    );
                                }
                            }
                        });

                        describe("Band level 1", () => {
                            beforeAll(() => {
                                bandLevel = 1;
                            });

                            describe("1 FIXED band staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                });

                                describe("1 band unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        expectedLeftBands = [];
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

                            describe("2 FIXED bands staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[5]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        expectedLeftBands = createArray(bandIds[3], bandIds[5]);
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[3], bandIds[5]);
                                        expectedLeftBands = createArray(bandIds[0], bandIds[2]);
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

                                describe("2 bands unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[5]);
                                        expectedLeftBands = [];
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

                            describe("3 FIXED bands", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[8]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        // When popping last item (we copy the last element to the removed one)
                                        expectedLeftBands = [
                                            bandIds[6],
                                            bandIds[3],
                                            bandIds[7],
                                            bandIds[4],
                                            bandIds[8],
                                            bandIds[5],
                                        ];
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[3], bandIds[5]);
                                        expectedLeftBands = [
                                            bandIds[0],
                                            bandIds[6],
                                            bandIds[1],
                                            bandIds[7],
                                            bandIds[2],
                                            bandIds[8],
                                        ];
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

                                describe("1 band unstaked (with id 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[6], bandIds[8]);
                                        expectedLeftBands = [
                                            bandIds[0],
                                            bandIds[3],
                                            bandIds[1],
                                            bandIds[4],
                                            bandIds[2],
                                            bandIds[5],
                                        ];
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

                                describe("2 bands unstaked (with ids 0, 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[5]);
                                        expectedLeftBands = createArray(bandIds[6], bandIds[8]);
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

                                describe("2 bands unstaked (with ids 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[3], bandIds[8]);
                                        expectedLeftBands = createArray(bandIds[0], bandIds[2]);
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

                                describe("2 bands unstaked (with ids 0, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [
                                            bandIds[0],
                                            bandIds[1],
                                            bandIds[2],
                                            bandIds[6],
                                            bandIds[7],
                                            bandIds[8],
                                        ];
                                        expectedLeftBands = createArray(bandIds[3], bandIds[5]);
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

                                describe("3 bands unstaked (with ids 0, 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[8]);
                                        expectedLeftBands = [];
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

                        describe("Band level 5", () => {
                            beforeAll(() => {
                                bandLevel = 5;
                            });

                            describe("1 FIXED band staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                });

                                describe("1 band unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        expectedLeftBands = [];
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

                            describe("2 FIXED bands staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[5]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        expectedLeftBands = createArray(bandIds[3], bandIds[5]);
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[3], bandIds[5]);
                                        expectedLeftBands = createArray(bandIds[0], bandIds[2]);
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

                                describe("2 bands unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[5]);
                                        expectedLeftBands = [];
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

                            describe("3 FIXED bands", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[8]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        // When popping last item (we copy the last element to the removed one)
                                        expectedLeftBands = [
                                            bandIds[6],
                                            bandIds[3],
                                            bandIds[7],
                                            bandIds[4],
                                            bandIds[8],
                                            bandIds[5],
                                        ];
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[3], bandIds[5]);
                                        expectedLeftBands = [
                                            bandIds[0],
                                            bandIds[6],
                                            bandIds[1],
                                            bandIds[7],
                                            bandIds[2],
                                            bandIds[8],
                                        ];
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

                                describe("1 band unstaked (with id 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[6], bandIds[8]);
                                        expectedLeftBands = [
                                            bandIds[0],
                                            bandIds[3],
                                            bandIds[1],
                                            bandIds[4],
                                            bandIds[2],
                                            bandIds[5],
                                        ];
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

                                describe("2 bands unstaked (with ids 0, 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[5]);
                                        expectedLeftBands = createArray(bandIds[6], bandIds[8]);
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

                                describe("2 bands unstaked (with ids 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[3], bandIds[8]);
                                        expectedLeftBands = createArray(bandIds[0], bandIds[2]);
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

                                describe("2 bands unstaked (with ids 0, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [
                                            bandIds[0],
                                            bandIds[1],
                                            bandIds[2],
                                            bandIds[6],
                                            bandIds[7],
                                            bandIds[8],
                                        ];
                                        expectedLeftBands = createArray(bandIds[3], bandIds[5]);
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

                                describe("3 bands unstaked (with ids 0, 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[8]);
                                        expectedLeftBands = [];
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

                        describe("Band level 9", () => {
                            beforeAll(() => {
                                bandLevel = 9;
                            });

                            describe("1 FIXED band staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                });

                                describe("1 band unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        expectedLeftBands = [];
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

                            describe("2 FIXED bands staked", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[5]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        expectedLeftBands = createArray(bandIds[3], bandIds[5]);
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[3], bandIds[5]);
                                        expectedLeftBands = createArray(bandIds[0], bandIds[2]);
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

                                describe("2 bands unstaked", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[5]);
                                        expectedLeftBands = [];
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

                            describe("3 FIXED bands", () => {
                                beforeAll(() => {
                                    stakedBandsArray = createArray(bandIds[0], bandIds[8]);
                                });

                                describe("1 band unstaked (with id 0)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[2]);
                                        // When popping last item (we copy the last element to the removed one)
                                        expectedLeftBands = [
                                            bandIds[6],
                                            bandIds[3],
                                            bandIds[7],
                                            bandIds[4],
                                            bandIds[8],
                                            bandIds[5],
                                        ];
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

                                describe("1 band unstaked (with id 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[3], bandIds[5]);
                                        expectedLeftBands = [
                                            bandIds[0],
                                            bandIds[6],
                                            bandIds[1],
                                            bandIds[7],
                                            bandIds[2],
                                            bandIds[8],
                                        ];
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

                                describe("1 band unstaked (with id 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[6], bandIds[8]);
                                        expectedLeftBands = [
                                            bandIds[0],
                                            bandIds[3],
                                            bandIds[1],
                                            bandIds[4],
                                            bandIds[2],
                                            bandIds[5],
                                        ];
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

                                describe("2 bands unstaked (with ids 0, 1)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[5]);
                                        expectedLeftBands = createArray(bandIds[6], bandIds[8]);
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

                                describe("2 bands unstaked (with ids 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[3], bandIds[8]);
                                        expectedLeftBands = createArray(bandIds[0], bandIds[2]);
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

                                describe("2 bands unstaked (with ids 0, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = [
                                            bandIds[0],
                                            bandIds[1],
                                            bandIds[2],
                                            bandIds[6],
                                            bandIds[7],
                                            bandIds[8],
                                        ];
                                        expectedLeftBands = createArray(bandIds[3], bandIds[5]);
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

                                describe("3 bands unstaked (with ids 0, 1, 2)", () => {
                                    beforeAll(() => {
                                        unstakedBandsArray = createArray(bandIds[0], bandIds[8]);
                                        expectedLeftBands = [];
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
            });
        });
    });
});
