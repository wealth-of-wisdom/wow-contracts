import { BigInt, log } from "@graphprotocol/graph-ts";
import {
    describe,
    test,
    beforeAll,
    beforeEach,
    afterAll,
    afterEach,
    clearStore,
    assert,
} from "matchstick-as/assembly/index";
import { StakerAndPoolShares, updateSharesForPoolsAndStakers } from "../../src/utils/staking/sharesSync";
import {
    initialize,
    setPool,
    setBandLevel,
    setSharesInMonth,
    stakeStandardFixed,
    stakeStandardFlexi,
    stakeVestedFixed,
    stakeVestedFlexi,
    createDistribution,
    distributeRewards,
} from "./helpers/helper";
import {
    stakingAddress,
    usdtToken,
    usdcToken,
    wowToken,
    alice,
    bob,
    charlie,
    totalPools,
    totalBandLevels,
    usd100k,
    initDate,
    zeroStr,
    poolDistributionPercentages,
    bandLevelPrices,
    bandLevelAccessiblePools,
    bandLevels,
    ids,
    bandIds,
    months,
    monthsInSeconds,
    sharesInMonths,
} from "../utils/constants";
import { getOrInitStakingContract } from "../../src/helpers/staking.helpers";
import { BIGINT_ZERO } from "../../src/utils/constants";
import { convertBigIntArrayToString } from "../utils/arrays";

let level = 0;
let month = 0;
let testNum = 0;
let shares: BigInt = BIGINT_ZERO;
let stakerSharesPerPool: BigInt[] = [];
let fixedMonths = [0];
let fixedMonth = 0;
let syncMonths = [0];
let syncMonth = 0;

describe("updateSharesForPoolsAndStakers() tests", () => {
    beforeEach(() => {
        clearStore();

        initialize();

        for (let i = 0; i < totalPools.toI32(); i++) {
            const poolId: BigInt = BigInt.fromI32(i + 1);
            setPool(poolId, poolDistributionPercentages[i]);
        }

        for (let i = 0; i < totalBandLevels.toI32(); i++) {
            const bandLevel: BigInt = BigInt.fromI32(i + 1);
            setBandLevel(bandLevel, bandLevelPrices[i], bandLevelAccessiblePools[i]);
        }

        setSharesInMonth(sharesInMonths);
    });

    describe("1 Staker", () => {
        describe("1 Band level", () => {
            describe("1 FIXED band", () => {
                describe("Standard staking", () => {
                    // This is the full test template
                    // test() functions are only used to set different values for the variables
                    afterEach(() => {
                        // ARRANGE
                        shares = sharesInMonths[fixedMonth - 1];

                        // Staker should have the same amount of shares in all accessible pools
                        // Example: [100, 100, 100, 0, 0, 0, 0, 0, 0]
                        stakerSharesPerPool = new Array<BigInt>(totalPools.toI32())
                            .fill(shares)
                            .fill(BIGINT_ZERO, level);

                        // Staker stakes in the accessible pool of the band level
                        stakeStandardFixed(alice, bandLevels[level - 1], bandIds[0], months[fixedMonth]);

                        // ACT
                        const stakingContract = getOrInitStakingContract();

                        // Try to sync and update the shares
                        updateSharesForPoolsAndStakers(stakingContract, initDate.plus(monthsInSeconds[syncMonth]));

                        // ASSERT band
                        assert.fieldEquals("Band", ids[0], "sharesAmount", shares.toString());

                        // ASSERT staker
                        assert.fieldEquals(
                            "Staker",
                            alice.toHex(),
                            "sharesPerPool",
                            convertBigIntArrayToString(stakerSharesPerPool),
                        );

                        // ASSERT pools
                        for (let i = 0; i <= level; i++) {
                            assert.fieldEquals("Pool", ids[1], "totalSharesAmount", shares.toString());
                        }
                        for (let i = level + 1; i < totalPools.toI32(); i++) {
                            assert.fieldEquals("Pool", ids[i], "totalSharesAmount", zeroStr);
                        }
                    });

                    describe("Band level 1", () => {
                        beforeAll(() => {
                            level = 1;
                        });

                        describe("Fixed for 1 month", () => {
                            beforeAll(() => {
                                fixedMonth = 1;
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

                        describe("Fixed for 12 month", () => {
                            beforeAll(() => {
                                fixedMonth = 12;
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

                        describe("Fixed for 24 month", () => {
                            beforeAll(() => {
                                fixedMonth = 24;
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

                    describe("Band level 5", () => {
                        beforeAll(() => {
                            level = 5;
                        });

                        describe("Fixed for 1 month", () => {
                            beforeAll(() => {
                                fixedMonth = 1;
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

                        describe("Fixed for 12 month", () => {
                            beforeAll(() => {
                                fixedMonth = 12;
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

                        describe("Fixed for 24 month", () => {
                            beforeAll(() => {
                                fixedMonth = 24;
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

                    describe("Band level 9", () => {
                        beforeAll(() => {
                            level = 9;
                        });

                        describe("Fixed for 1 month", () => {
                            beforeAll(() => {
                                fixedMonth = 1;
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

                        describe("Fixed for 12 month", () => {
                            beforeAll(() => {
                                fixedMonth = 12;
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

                        describe("Fixed for 24 month", () => {
                            beforeAll(() => {
                                fixedMonth = 24;
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

                describe("Vested staking", () => {});
            });
        });
    });
});
