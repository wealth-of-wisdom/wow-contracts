import { Address, BigInt, log } from "@graphprotocol/graph-ts";
import { describe, test, beforeEach, beforeAll, assert, clearStore, afterEach } from "matchstick-as/assembly/index";
import {
    initializeAndSetUp,
    stakeStandardFixed,
    stakeStandardFlexi,
    stakeVestedFixed,
    stakeVestedFlexi,
} from "./helpers/helper";
import { bandIds, alice, bob, totalPools, charlie } from "../utils/data/constants";
import { monthsAfterInit, dayInSeconds } from "../utils/data/dates";
import { sharesInMonths, bandLevels, months } from "../utils/data/data";
import { convertBigIntArrayToString, createEmptyArray } from "../utils/arrays";
import { BIGINT_ZERO } from "../../src/utils/constants";
import { StakerAndPoolShares } from "../../src/utils/utils";
import { syncAndCalculateAllShares } from "../../src/utils/staking/sharesSync";
import { StakingContract } from "../../generated/schema";
import { getOrInitStakingContract } from "../../src/helpers/staking.helpers";

let bandLevel = 0;
let bandsCount = 0;
let fixedMonth = 0;
let syncMonth = 0;
let shares: BigInt;
let stakers: string[] = [];
let stakersCount = 0;
let sharesForStakers: BigInt[][];
let sharesForStakersCount = 0;
let sharesForPools: BigInt[];
let sharesForPoolsCount = 0;
let expectedStakers: Address[];
let expectedStakersCount = 0;
let expectedSharesForStakers: BigInt[][];
let expectedSharesForStakersCount = 0;
let expectedSharesForPools: BigInt[];
let expectedSharesForPoolsCount = 0;

describe("syncAndCalculateAllShares() tests", () => {
    beforeEach(() => {
        clearStore();
        initializeAndSetUp();
    });

    describe("Only FIXED bands", () => {
        beforeAll(() => {
            syncMonth = 10;
        });

        describe("1 Staker", () => {
            beforeAll(() => {
                expectedStakers = [alice];
                expectedStakersCount = expectedStakers.length;
            });

            afterEach(() => {
                /*//////////////////////////////////////////////////////////////////////////
                                              GET ASSERTION DATA
                //////////////////////////////////////////////////////////////////////////*/

                shares = sharesInMonths[fixedMonth - 1].times(BigInt.fromI32(bandsCount));

                expectedSharesForStakers = [createEmptyArray(totalPools).fill(shares, 0, bandLevel)];
                expectedSharesForStakersCount = expectedSharesForStakers.length;

                expectedSharesForPools = expectedSharesForStakers[0];
                expectedSharesForPoolsCount = expectedSharesForPools.length;

                const stakingContract: StakingContract = getOrInitStakingContract();
                const sharesData: StakerAndPoolShares = syncAndCalculateAllShares(
                    stakingContract,
                    monthsAfterInit[syncMonth],
                );

                stakers = sharesData.stakers;
                stakersCount = stakers.length;
                sharesForStakers = sharesData.sharesForStakers;
                sharesForStakersCount = sharesForStakers.length;
                sharesForPools = sharesData.sharesForPools;
                sharesForPoolsCount = sharesForPools.length;

                /*//////////////////////////////////////////////////////////////////////////
                                              ASSERT MAIN DATA
                //////////////////////////////////////////////////////////////////////////*/

                log.debug("Should return stakers array", []);
                assert.i32Equals(stakersCount, expectedStakersCount);
                for (let i = 0; i < stakersCount; i++) {
                    assert.stringEquals(stakers[i], expectedStakers[i].toHex());
                }

                log.debug("Should return all stakers' shares", []);
                assert.i32Equals(sharesForStakersCount, expectedSharesForStakersCount);
                for (let i = 0; i < sharesForStakersCount; i++) {
                    assert.stringEquals(
                        convertBigIntArrayToString(sharesForStakers[i]),
                        convertBigIntArrayToString(expectedSharesForStakers[i]),
                    );
                }

                log.debug("Should return all pools's shares", []);
                assert.i32Equals(sharesForPoolsCount, expectedSharesForPoolsCount);
                for (let i = 0; i < sharesForPoolsCount; i++) {
                    assert.bigIntEquals(sharesForPools[i], expectedSharesForPools[i]);
                }
            });

            describe("Standard staking", () => {
                afterEach(() => {
                    for (let i = 0; i < bandsCount; i++) {
                        stakeStandardFixed(
                            alice,
                            bandLevels[bandLevel - 1],
                            bandIds[i],
                            months[fixedMonth],
                            monthsAfterInit[syncMonth],
                        );
                    }
                });

                describe("1 Band", () => {
                    beforeAll(() => {
                        bandsCount = 1;
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            bandLevel = 1;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            bandLevel = 5;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            bandLevel = 9;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });
                });

                describe("3 Bands", () => {
                    beforeAll(() => {
                        bandsCount = 3;
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            bandLevel = 1;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            bandLevel = 5;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            bandLevel = 9;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });
                });
            });

            describe("Vested staking", () => {
                afterEach(() => {
                    for (let i = 0; i < bandsCount; i++) {
                        stakeVestedFixed(
                            alice,
                            bandLevels[bandLevel - 1],
                            bandIds[i],
                            months[fixedMonth],
                            monthsAfterInit[syncMonth],
                        );
                    }
                });

                describe("1 Band", () => {
                    beforeAll(() => {
                        bandsCount = 1;
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            bandLevel = 1;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            bandLevel = 5;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            bandLevel = 9;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });
                });

                describe("3 Bands", () => {
                    beforeAll(() => {
                        bandsCount = 3;
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            bandLevel = 1;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            bandLevel = 5;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            bandLevel = 9;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });
                });
            });
        });

        describe("3 Staker", () => {
            beforeAll(() => {
                expectedStakers = [alice, bob, charlie];
                expectedStakersCount = expectedStakers.length;
            });

            afterEach(() => {
                shares = sharesInMonths[fixedMonth - 1].times(BigInt.fromI32(bandsCount));

                const singleStakerShares = createEmptyArray(totalPools).fill(shares, 0, bandLevel);
                expectedSharesForStakers = [];
                for (let i = 0; i < expectedStakersCount; i++) {
                    expectedSharesForStakers[i] = singleStakerShares;
                }
                expectedSharesForStakersCount = expectedSharesForStakers.length;

                expectedSharesForPools = createEmptyArray(totalPools);
                for (let i = 0; i < totalPools.toI32(); i++) {
                    expectedSharesForPools[i] = expectedSharesForStakers[0][i].times(
                        BigInt.fromI32(expectedStakersCount),
                    );
                }
                expectedSharesForPoolsCount = expectedSharesForPools.length;

                const stakingContract: StakingContract = getOrInitStakingContract();
                const sharesData: StakerAndPoolShares = syncAndCalculateAllShares(
                    stakingContract,
                    monthsAfterInit[syncMonth],
                );

                stakers = sharesData.stakers;
                stakersCount = stakers.length;
                sharesForStakers = sharesData.sharesForStakers;
                sharesForStakersCount = sharesForStakers.length;
                sharesForPools = sharesData.sharesForPools;
                sharesForPoolsCount = sharesForPools.length;

                /*//////////////////////////////////////////////////////////////////////////
                                                ASSERT MAIN DATA
                //////////////////////////////////////////////////////////////////////////*/

                log.debug("Should return stakers array", []);
                assert.i32Equals(stakersCount, expectedStakersCount);
                for (let i = 0; i < stakersCount; i++) {
                    assert.stringEquals(stakers[i], expectedStakers[i].toHex());
                }

                log.debug("Should return all stakers' shares", []);
                assert.i32Equals(sharesForStakersCount, expectedSharesForStakersCount);
                for (let i = 0; i < sharesForStakersCount; i++) {
                    assert.stringEquals(
                        convertBigIntArrayToString(sharesForStakers[i]),
                        convertBigIntArrayToString(expectedSharesForStakers[i]),
                    );
                }

                log.debug("Should return all pools's shares", []);
                assert.i32Equals(sharesForPoolsCount, expectedSharesForPoolsCount);
                for (let i = 0; i < sharesForPoolsCount; i++) {
                    assert.bigIntEquals(sharesForPools[i], expectedSharesForPools[i]);
                }
            });

            describe("Standard staking", () => {
                afterEach(() => {
                    for (let i = 0; i < expectedStakersCount; i++) {
                        for (let j = 0; j < bandsCount; j++) {
                            stakeStandardFixed(
                                expectedStakers[i],
                                bandLevels[bandLevel - 1],
                                bandIds[i * bandsCount + j],
                                months[fixedMonth],
                                monthsAfterInit[syncMonth],
                            );
                        }
                    }
                });

                describe("1 Band", () => {
                    beforeAll(() => {
                        bandsCount = 1;
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            bandLevel = 1;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            bandLevel = 5;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            bandLevel = 9;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });
                });

                describe("3 Bands", () => {
                    beforeAll(() => {
                        bandsCount = 3;
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            bandLevel = 1;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            bandLevel = 5;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            bandLevel = 9;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });
                });
            });

            describe("Vested staking", () => {
                afterEach(() => {
                    for (let i = 0; i < expectedStakersCount; i++) {
                        for (let j = 0; j < bandsCount; j++) {
                            stakeVestedFixed(
                                expectedStakers[i],
                                bandLevels[bandLevel - 1],
                                bandIds[i * bandsCount + j],
                                months[fixedMonth],
                                monthsAfterInit[syncMonth],
                            );
                        }
                    }
                });

                describe("1 Band", () => {
                    beforeAll(() => {
                        bandsCount = 1;
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            bandLevel = 1;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            bandLevel = 5;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            bandLevel = 9;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });
                });

                describe("3 Bands", () => {
                    beforeAll(() => {
                        bandsCount = 3;
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            bandLevel = 1;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            bandLevel = 5;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            bandLevel = 9;
                        });

                        test("Fixed month - 1", () => {
                            fixedMonth = 1;
                        });

                        test("Fixed month - 12", () => {
                            fixedMonth = 12;
                        });

                        test("Fixed month - 24", () => {
                            fixedMonth = 24;
                        });
                    });
                });
            });
        });
    });

    describe("Only FLEXI bands", () => {
        beforeAll(() => {
            syncMonth = 12;
        });

        describe("1 Staker", () => {
            beforeAll(() => {
                expectedStakers = [alice];
                expectedStakersCount = expectedStakers.length;
            });

            afterEach(() => {
                /*//////////////////////////////////////////////////////////////////////////
                                            GET ASSERION DATA
                //////////////////////////////////////////////////////////////////////////*/

                shares = sharesInMonths[syncMonth - 1].times(BigInt.fromI32(bandsCount));

                expectedSharesForStakers = [createEmptyArray(totalPools).fill(shares, 0, bandLevel)];
                expectedSharesForStakersCount = expectedSharesForStakers.length;

                expectedSharesForPools = expectedSharesForStakers[0];
                expectedSharesForPoolsCount = expectedSharesForPools.length;

                const stakingContract: StakingContract = getOrInitStakingContract();
                const sharesData: StakerAndPoolShares = syncAndCalculateAllShares(
                    stakingContract,
                    monthsAfterInit[syncMonth + 1],
                );

                stakers = sharesData.stakers;
                stakersCount = stakers.length;
                sharesForStakers = sharesData.sharesForStakers;
                sharesForStakersCount = sharesForStakers.length;
                sharesForPools = sharesData.sharesForPools;
                sharesForPoolsCount = sharesForPools.length;

                /*//////////////////////////////////////////////////////////////////////////
                                                ASSERT MAIN DATA
                //////////////////////////////////////////////////////////////////////////*/

                log.debug("Should return stakers array", []);
                assert.i32Equals(stakersCount, expectedStakersCount);
                for (let i = 0; i < stakersCount; i++) {
                    assert.stringEquals(stakers[i], expectedStakers[i].toHex());
                }

                log.debug("Should return all stakers' shares", []);
                assert.i32Equals(sharesForStakersCount, expectedSharesForStakersCount);
                for (let i = 0; i < sharesForStakersCount; i++) {
                    assert.stringEquals(
                        convertBigIntArrayToString(sharesForStakers[i]),
                        convertBigIntArrayToString(expectedSharesForStakers[i]),
                    );
                }

                log.debug("Should return all pools's shares", []);
                assert.i32Equals(sharesForPoolsCount, expectedSharesForPoolsCount);
                for (let i = 0; i < sharesForPoolsCount; i++) {
                    assert.bigIntEquals(sharesForPools[i], expectedSharesForPools[i]);
                }
            });

            describe("Single band level", () => {
                describe("Standard staking", () => {
                    afterEach(() => {
                        for (let i = 0; i < bandsCount; i++) {
                            stakeStandardFlexi(alice, bandLevels[bandLevel - 1], bandIds[i], monthsAfterInit[1]);
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
                    afterEach(() => {
                        // Staker stakes in the accessible pool of the band level
                        for (let i = 0; i < bandsCount; i++) {
                            stakeVestedFlexi(alice, bandLevels[bandLevel - 1], bandIds[i], monthsAfterInit[1]);
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
                expectedStakers = [alice, bob, charlie];
                expectedStakersCount = expectedStakers.length;
            });

            afterEach(() => {
                /*//////////////////////////////////////////////////////////////////////////
                                            GET ASSERION DATA
                //////////////////////////////////////////////////////////////////////////*/

                shares = sharesInMonths[syncMonth - 1].times(BigInt.fromI32(bandsCount));

                const singleStakerShares = createEmptyArray(totalPools).fill(shares, 0, bandLevel);
                expectedSharesForStakers = [];
                for (let i = 0; i < expectedStakersCount; i++) {
                    expectedSharesForStakers[i] = singleStakerShares;
                }
                expectedSharesForStakersCount = expectedSharesForStakers.length;

                expectedSharesForPools = createEmptyArray(totalPools);
                for (let i = 0; i < totalPools.toI32(); i++) {
                    expectedSharesForPools[i] = expectedSharesForStakers[0][i].times(
                        BigInt.fromI32(expectedStakersCount),
                    );
                }
                expectedSharesForPoolsCount = expectedSharesForPools.length;

                const stakingContract: StakingContract = getOrInitStakingContract();
                const sharesData: StakerAndPoolShares = syncAndCalculateAllShares(
                    stakingContract,
                    monthsAfterInit[syncMonth + 1],
                );

                stakers = sharesData.stakers;
                stakersCount = stakers.length;
                sharesForStakers = sharesData.sharesForStakers;
                sharesForStakersCount = sharesForStakers.length;
                sharesForPools = sharesData.sharesForPools;
                sharesForPoolsCount = sharesForPools.length;

                /*//////////////////////////////////////////////////////////////////////////
                                                ASSERT SHARES
                //////////////////////////////////////////////////////////////////////////*/

                log.debug("Should return stakers array", []);
                assert.i32Equals(stakersCount, expectedStakersCount);
                for (let i = 0; i < stakersCount; i++) {
                    assert.stringEquals(stakers[i], expectedStakers[i].toHex());
                }

                log.debug("Should return all stakers' shares", []);
                assert.i32Equals(sharesForStakersCount, expectedSharesForStakersCount);
                for (let i = 0; i < sharesForStakersCount; i++) {
                    assert.stringEquals(
                        convertBigIntArrayToString(sharesForStakers[i]),
                        convertBigIntArrayToString(expectedSharesForStakers[i]),
                    );
                }

                log.debug("Should return all pools's shares", []);
                assert.i32Equals(sharesForPoolsCount, expectedSharesForPoolsCount);
                for (let i = 0; i < sharesForPoolsCount; i++) {
                    assert.bigIntEquals(sharesForPools[i], expectedSharesForPools[i]);
                }
            });

            describe("Single band level", () => {
                describe("Standard staking", () => {
                    afterEach(() => {
                        for (let i = 0; i < bandsCount; i++) {
                            for (let j = 0; j < expectedStakersCount; j++) {
                                stakeStandardFlexi(
                                    expectedStakers[j],
                                    bandLevels[bandLevel - 1],
                                    bandIds[i * stakersCount + j],
                                    monthsAfterInit[1],
                                );
                            }
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
                    afterEach(() => {
                        for (let i = 0; i < bandsCount; i++) {
                            for (let j = 0; j < expectedStakersCount; j++) {
                                stakeVestedFlexi(
                                    expectedStakers[j],
                                    bandLevels[bandLevel - 1],
                                    bandIds[i * stakersCount + j],
                                    monthsAfterInit[1],
                                );
                            }
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

    describe("FIXED and FLEXI bands", () => {
        describe("1 staker, 1 FIXED and 1 FLEXI", () => {
            describe("More than 2 months", () => {
                beforeEach(() => {
                    stakeStandardFixed(alice, bandLevels[4], bandIds[0], months[10], monthsAfterInit[1]);
                    stakeStandardFlexi(alice, bandLevels[7], bandIds[1], monthsAfterInit[1].plus(dayInSeconds));

                    const fixedShares = sharesInMonths[9];
                    const flexiShares = sharesInMonths[0];
                    const totalShares = fixedShares.plus(flexiShares);

                    expectedStakers = [alice];
                    expectedStakersCount = expectedStakers.length;
                    expectedSharesForStakers = [
                        [
                            totalShares,
                            totalShares,
                            totalShares,
                            totalShares,
                            totalShares,
                            flexiShares,
                            flexiShares,
                            flexiShares,
                            BIGINT_ZERO,
                        ],
                    ];
                    expectedSharesForStakersCount = expectedSharesForStakers.length;
                    expectedSharesForPools = expectedSharesForStakers[0];
                    expectedSharesForPoolsCount = expectedSharesForPools.length;

                    const stakingContract: StakingContract = getOrInitStakingContract();
                    const sharesData: StakerAndPoolShares = syncAndCalculateAllShares(
                        stakingContract,
                        monthsAfterInit[2].plus(dayInSeconds),
                    );

                    stakers = sharesData.stakers;
                    stakersCount = stakers.length;
                    sharesForStakers = sharesData.sharesForStakers;
                    sharesForStakersCount = sharesForStakers.length;
                    sharesForPools = sharesData.sharesForPools;
                    sharesForPoolsCount = sharesForPools.length;
                });

                /*//////////////////////////////////////////////////////////////////////////
                                                ASSERT MAIN DATA
                //////////////////////////////////////////////////////////////////////////*/

                test("Should return stakers array", () => {
                    assert.i32Equals(stakersCount, expectedStakersCount);
                    for (let i = 0; i < stakersCount; i++) {
                        assert.stringEquals(stakers[i], expectedStakers[i].toHex());
                    }
                });

                test("Should return all stakers' shares", () => {
                    assert.i32Equals(sharesForStakersCount, expectedSharesForStakersCount);
                    for (let i = 0; i < sharesForStakersCount; i++) {
                        assert.stringEquals(
                            convertBigIntArrayToString(sharesForStakers[i]),
                            convertBigIntArrayToString(expectedSharesForStakers[i]),
                        );
                    }
                });

                test("Should return all pools' shares", () => {
                    assert.i32Equals(sharesForPoolsCount, expectedSharesForPoolsCount);
                    for (let i = 0; i < sharesForPoolsCount; i++) {
                        assert.bigIntEquals(sharesForPools[i], expectedSharesForPools[i]);
                    }
                });
            });

            describe("2 months", () => {
                beforeEach(() => {
                    stakeStandardFixed(alice, bandLevels[4], bandIds[0], months[10], monthsAfterInit[1]);
                    stakeStandardFlexi(alice, bandLevels[7], bandIds[1], monthsAfterInit[1].plus(dayInSeconds));

                    const fixedShares = sharesInMonths[9];
                    const flexiShares = BIGINT_ZERO;
                    const totalShares = fixedShares.plus(flexiShares);

                    expectedStakers = [alice];
                    expectedStakersCount = expectedStakers.length;
                    expectedSharesForStakers = [
                        [
                            totalShares,
                            totalShares,
                            totalShares,
                            totalShares,
                            totalShares,
                            flexiShares,
                            flexiShares,
                            flexiShares,
                            BIGINT_ZERO,
                        ],
                    ];
                    expectedSharesForStakersCount = expectedSharesForStakers.length;
                    expectedSharesForPools = expectedSharesForStakers[0];
                    expectedSharesForPoolsCount = expectedSharesForPools.length;

                    const stakingContract: StakingContract = getOrInitStakingContract();
                    const sharesData: StakerAndPoolShares = syncAndCalculateAllShares(
                        stakingContract,
                        monthsAfterInit[2],
                    );

                    stakers = sharesData.stakers;
                    stakersCount = stakers.length;
                    sharesForStakers = sharesData.sharesForStakers;
                    sharesForStakersCount = sharesForStakers.length;
                    sharesForPools = sharesData.sharesForPools;
                    sharesForPoolsCount = sharesForPools.length;
                });

                /*//////////////////////////////////////////////////////////////////////////
                                                ASSERT MAIN DATA
                //////////////////////////////////////////////////////////////////////////*/

                test("Should return stakers array", () => {
                    assert.i32Equals(stakersCount, expectedStakersCount);
                    for (let i = 0; i < stakersCount; i++) {
                        assert.stringEquals(stakers[i], expectedStakers[i].toHex());
                    }
                });

                test("Should return all stakers' shares", () => {
                    assert.i32Equals(sharesForStakersCount, expectedSharesForStakersCount);
                    for (let i = 0; i < sharesForStakersCount; i++) {
                        assert.stringEquals(
                            convertBigIntArrayToString(sharesForStakers[i]),
                            convertBigIntArrayToString(expectedSharesForStakers[i]),
                        );
                    }
                });

                test("Should return all pools' shares", () => {
                    assert.i32Equals(sharesForPoolsCount, expectedSharesForPoolsCount);
                    for (let i = 0; i < sharesForPoolsCount; i++) {
                        assert.bigIntEquals(sharesForPools[i], expectedSharesForPools[i]);
                    }
                });
            });
        });

        describe("2 staker, 2 FIXED and 2 FLEXI", () => {
            describe("More than 5 months", () => {
                beforeEach(() => {
                    stakeStandardFixed(alice, bandLevels[0], bandIds[0], months[10], monthsAfterInit[1]);
                    stakeVestedFixed(bob, bandLevels[4], bandIds[1], months[24], monthsAfterInit[2]);
                    stakeVestedFlexi(alice, bandLevels[2], bandIds[2], monthsAfterInit[3].plus(dayInSeconds));
                    stakeStandardFlexi(bob, bandLevels[6], bandIds[3], monthsAfterInit[4]);

                    const fixedShares1 = sharesInMonths[9];
                    const flexiShares1 = sharesInMonths[1];
                    const totalShares1 = fixedShares1.plus(flexiShares1);
                    const fixedShares2 = sharesInMonths[23];
                    const flexiShares2 = sharesInMonths[0];
                    const totalShares2 = fixedShares2.plus(flexiShares2);

                    expectedStakers = [alice, bob];
                    expectedStakersCount = expectedStakers.length;
                    expectedSharesForStakers = [
                        [
                            totalShares1,
                            flexiShares1,
                            flexiShares1,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                        ],
                        [
                            totalShares2,
                            totalShares2,
                            totalShares2,
                            totalShares2,
                            totalShares2,
                            flexiShares2,
                            flexiShares2,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                        ],
                    ];
                    expectedSharesForStakersCount = expectedSharesForStakers.length;

                    expectedSharesForPools = createEmptyArray(totalPools);
                    for (let i = 0; i < totalPools.toI32(); i++) {
                        for (let j = 0; j < expectedStakersCount; j++) {
                            expectedSharesForPools[i] = expectedSharesForPools[i].plus(expectedSharesForStakers[j][i]);
                        }
                    }
                    expectedSharesForPoolsCount = expectedSharesForPools.length;

                    const stakingContract: StakingContract = getOrInitStakingContract();
                    const sharesData: StakerAndPoolShares = syncAndCalculateAllShares(
                        stakingContract,
                        monthsAfterInit[5].plus(dayInSeconds),
                    );

                    stakers = sharesData.stakers;
                    stakersCount = stakers.length;
                    sharesForStakers = sharesData.sharesForStakers;
                    sharesForStakersCount = sharesForStakers.length;
                    sharesForPools = sharesData.sharesForPools;
                    sharesForPoolsCount = sharesForPools.length;
                });

                /*//////////////////////////////////////////////////////////////////////////
                                                ASSERT MAIN DATA
                //////////////////////////////////////////////////////////////////////////*/

                test("Should return stakers array", () => {
                    assert.i32Equals(stakersCount, expectedStakersCount);
                    for (let i = 0; i < stakersCount; i++) {
                        assert.stringEquals(stakers[i], expectedStakers[i].toHex());
                    }
                });

                test("Should return all stakers' shares", () => {
                    assert.i32Equals(sharesForStakersCount, expectedSharesForStakersCount);
                    for (let i = 0; i < sharesForStakersCount; i++) {
                        assert.stringEquals(
                            convertBigIntArrayToString(sharesForStakers[i]),
                            convertBigIntArrayToString(expectedSharesForStakers[i]),
                        );
                    }
                });

                test("Should return all pools' shares", () => {
                    assert.i32Equals(sharesForPoolsCount, expectedSharesForPoolsCount);
                    for (let i = 0; i < sharesForPoolsCount; i++) {
                        assert.bigIntEquals(sharesForPools[i], expectedSharesForPools[i]);
                    }
                });
            });

            describe("5 months", () => {
                beforeEach(() => {
                    stakeStandardFixed(alice, bandLevels[0], bandIds[0], months[10], monthsAfterInit[1]);
                    stakeVestedFixed(bob, bandLevels[4], bandIds[1], months[24], monthsAfterInit[2]);
                    stakeVestedFlexi(alice, bandLevels[2], bandIds[2], monthsAfterInit[3].plus(dayInSeconds));
                    stakeStandardFlexi(bob, bandLevels[6], bandIds[3], monthsAfterInit[4]);

                    const fixedShares1 = sharesInMonths[9];
                    const flexiShares1 = sharesInMonths[0];
                    const totalShares1 = fixedShares1.plus(flexiShares1);
                    const fixedShares2 = sharesInMonths[23];
                    const flexiShares2 = sharesInMonths[0];
                    const totalShares2 = fixedShares2.plus(flexiShares2);

                    expectedStakers = [alice, bob];
                    expectedStakersCount = expectedStakers.length;
                    expectedSharesForStakers = [
                        [
                            totalShares1,
                            flexiShares1,
                            flexiShares1,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                        ],
                        [
                            totalShares2,
                            totalShares2,
                            totalShares2,
                            totalShares2,
                            totalShares2,
                            flexiShares2,
                            flexiShares2,
                            BIGINT_ZERO,
                            BIGINT_ZERO,
                        ],
                    ];
                    expectedSharesForStakersCount = expectedSharesForStakers.length;

                    expectedSharesForPools = createEmptyArray(totalPools);
                    for (let i = 0; i < totalPools.toI32(); i++) {
                        for (let j = 0; j < expectedStakersCount; j++) {
                            expectedSharesForPools[i] = expectedSharesForPools[i].plus(expectedSharesForStakers[j][i]);
                        }
                    }
                    expectedSharesForPoolsCount = expectedSharesForPools.length;

                    const stakingContract: StakingContract = getOrInitStakingContract();
                    const sharesData: StakerAndPoolShares = syncAndCalculateAllShares(
                        stakingContract,
                        monthsAfterInit[5],
                    );

                    stakers = sharesData.stakers;
                    stakersCount = stakers.length;
                    sharesForStakers = sharesData.sharesForStakers;
                    sharesForStakersCount = sharesForStakers.length;
                    sharesForPools = sharesData.sharesForPools;
                    sharesForPoolsCount = sharesForPools.length;
                });

                /*//////////////////////////////////////////////////////////////////////////
                                                ASSERT MAIN DATA
                //////////////////////////////////////////////////////////////////////////*/

                test("Should return stakers array", () => {
                    assert.i32Equals(stakersCount, expectedStakersCount);
                    for (let i = 0; i < stakersCount; i++) {
                        assert.stringEquals(stakers[i], expectedStakers[i].toHex());
                    }
                });

                test("Should return all stakers' shares", () => {
                    assert.i32Equals(sharesForStakersCount, expectedSharesForStakersCount);
                    for (let i = 0; i < sharesForStakersCount; i++) {
                        assert.stringEquals(
                            convertBigIntArrayToString(sharesForStakers[i]),
                            convertBigIntArrayToString(expectedSharesForStakers[i]),
                        );
                    }
                });

                test("Should return all pools' shares", () => {
                    assert.i32Equals(sharesForPoolsCount, expectedSharesForPoolsCount);
                    for (let i = 0; i < sharesForPoolsCount; i++) {
                        assert.bigIntEquals(sharesForPools[i], expectedSharesForPools[i]);
                    }
                });
            });
        });
    });
});
