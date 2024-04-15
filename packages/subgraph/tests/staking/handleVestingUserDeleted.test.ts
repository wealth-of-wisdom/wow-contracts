import { describe, test, beforeEach, assert, clearStore } from "matchstick-as/assembly/index";
import {
    deleteVestingUser,
    initializeAndSetUp,
    stakeStandardFixed,
    stakeStandardFlexi,
    createDistribution,
    distributeRewards,
} from "./helpers/helper";
import { ids, bandIds, alice, usdcToken, bob, usdtToken, usd100k } from "../utils/data/constants";
import { bandLevels, months } from "../utils/data/data";
import { monthsAfterInit } from "../utils/data/dates";

describe("handleVestingUserDeleted() tests", () => {
    beforeEach(() => {
        clearStore();
        initializeAndSetUp();
    });

    describe("1 Staker", () => {
        describe("1 Standard FIXED band", () => {
            beforeEach(() => {
                stakeStandardFixed(alice, bandLevels[1], bandIds[0], months[12], monthsAfterInit[1]);
                createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdtToken, monthsAfterInit[2]);
                createDistribution(usdcToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdcToken, monthsAfterInit[2]);
                deleteVestingUser(alice);
            });

            test("Should remove staker from all stakers", () => {
                assert.fieldEquals("StakingContract", ids[0], "stakers", "[]");
                assert.notInStore("Staker", alice.toHex());
                assert.entityCount("Staker", 0);
            });

            test("Should remove band from all bands", () => {
                assert.notInStore("Band", bandIds[0].toString());
                assert.entityCount("Band", 0);
            });

            test("Should remove staker rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                const usdcId = `${alice.toHex()}-${usdcToken.toHex()}`;

                assert.notInStore("StakerRewards", usdtId);
                assert.notInStore("StakerRewards", usdcId);
                assert.entityCount("StakerRewards", 0);
            });
        });

        describe("2 Standard FIXED bands", () => {
            beforeEach(() => {
                stakeStandardFixed(alice, bandLevels[1], bandIds[0], months[12], monthsAfterInit[1]);
                stakeStandardFixed(alice, bandLevels[4], bandIds[1], months[10], monthsAfterInit[1]);
                createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdtToken, monthsAfterInit[2]);
                createDistribution(usdcToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdcToken, monthsAfterInit[2]);
                deleteVestingUser(alice);
            });

            test("Should remove staker from all stakers", () => {
                assert.fieldEquals("StakingContract", ids[0], "stakers", "[]");
                assert.notInStore("Staker", alice.toHex());
                assert.entityCount("Staker", 0);
            });

            test("Should remove bands from all bands", () => {
                assert.notInStore("Band", bandIds[0].toString());
                assert.notInStore("Band", bandIds[1].toString());
                assert.entityCount("Band", 0);
            });

            test("Should remove staker rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                const usdcId = `${alice.toHex()}-${usdcToken.toHex()}`;

                assert.notInStore("StakerRewards", usdtId);
                assert.notInStore("StakerRewards", usdcId);
                assert.entityCount("StakerRewards", 0);
            });
        });

        describe("1 Standard FLEXI band", () => {
            beforeEach(() => {
                stakeStandardFlexi(alice, bandLevels[1], bandIds[0], monthsAfterInit[1]);
                createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdtToken, monthsAfterInit[2]);
                createDistribution(usdcToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdcToken, monthsAfterInit[2]);
                deleteVestingUser(alice);
            });

            test("Should remove staker from all stakers", () => {
                assert.fieldEquals("StakingContract", ids[0], "stakers", "[]");
                assert.notInStore("Staker", alice.toHex());
                assert.entityCount("Staker", 0);
            });

            test("Should remove band from all bands", () => {
                assert.notInStore("Band", bandIds[0].toString());
                assert.entityCount("Band", 0);
            });

            test("Should remove staker rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                const usdcId = `${alice.toHex()}-${usdcToken.toHex()}`;

                assert.notInStore("StakerRewards", usdtId);
                assert.notInStore("StakerRewards", usdcId);
                assert.entityCount("StakerRewards", 0);
            });
        });

        describe("2 Standard FLEXI bands", () => {
            beforeEach(() => {
                stakeStandardFlexi(alice, bandLevels[1], bandIds[0], monthsAfterInit[1]);
                stakeStandardFlexi(alice, bandLevels[4], bandIds[1], monthsAfterInit[1]);
                createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdtToken, monthsAfterInit[2]);
                createDistribution(usdcToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdcToken, monthsAfterInit[2]);
                deleteVestingUser(alice);
            });

            test("Should remove staker from all stakers", () => {
                assert.fieldEquals("StakingContract", ids[0], "stakers", "[]");
                assert.notInStore("Staker", alice.toHex());
                assert.entityCount("Staker", 0);
            });

            test("Should remove bands from all bands", () => {
                assert.notInStore("Band", bandIds[0].toString());
                assert.notInStore("Band", bandIds[1].toString());
                assert.entityCount("Band", 0);
            });

            test("Should remove staker rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                const usdcId = `${alice.toHex()}-${usdcToken.toHex()}`;

                assert.notInStore("StakerRewards", usdtId);
                assert.notInStore("StakerRewards", usdcId);
                assert.entityCount("StakerRewards", 0);
            });
        });

        describe("1 Standard FIXED band and 1 Standard FLEXI band", () => {
            beforeEach(() => {
                stakeStandardFixed(alice, bandLevels[1], bandIds[0], months[10], monthsAfterInit[1]);
                stakeStandardFlexi(alice, bandLevels[4], bandIds[1], monthsAfterInit[1]);
                createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdtToken, monthsAfterInit[2]);
                createDistribution(usdcToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdcToken, monthsAfterInit[2]);
                deleteVestingUser(alice);
            });

            test("Should remove staker from all stakers", () => {
                assert.fieldEquals("StakingContract", ids[0], "stakers", "[]");
                assert.notInStore("Staker", alice.toHex());
                assert.entityCount("Staker", 0);
            });

            test("Should remove bands from all bands", () => {
                assert.notInStore("Band", bandIds[0].toString());
                assert.notInStore("Band", bandIds[1].toString());
                assert.entityCount("Band", 0);
            });

            test("Should remove staker rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                const usdcId = `${alice.toHex()}-${usdcToken.toHex()}`;

                assert.notInStore("StakerRewards", usdtId);
                assert.notInStore("StakerRewards", usdcId);
                assert.entityCount("StakerRewards", 0);
            });
        });
    });

    describe("2 Stakers", () => {
        describe("1 Standard FIXED bands for each staker", () => {
            beforeEach(() => {
                stakeStandardFixed(alice, bandLevels[1], bandIds[0], months[12], monthsAfterInit[1]);
                stakeStandardFixed(bob, bandLevels[4], bandIds[1], months[10], monthsAfterInit[1]);
                createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdtToken, monthsAfterInit[2]);
                createDistribution(usdcToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdcToken, monthsAfterInit[2]);
                deleteVestingUser(alice);
            });

            test("Should remove alice from all stakers", () => {
                const stakers = `[${bob.toHex()}]`;
                assert.fieldEquals("StakingContract", ids[0], "stakers", stakers);
                assert.notInStore("Staker", alice.toHex());
            });

            test("Should leave bob staker", () => {
                const bobId = bob.toHex();
                assert.fieldEquals("Staker", bobId, "id", bobId);
                assert.entityCount("Staker", 1);
            });

            test("Should remove alice's band from all bands", () => {
                assert.notInStore("Band", bandIds[0].toString());
            });

            test("Should leave bob's band", () => {
                const bobBandId = bandIds[1].toString();
                assert.fieldEquals("Band", bobBandId, "id", bobBandId);
                assert.entityCount("Band", 1);
            });

            test("Should remove alice's rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                const usdcId = `${alice.toHex()}-${usdcToken.toHex()}`;

                assert.notInStore("StakerRewards", usdtId);
                assert.notInStore("StakerRewards", usdcId);
            });

            test("Should leave bob's rewards", () => {
                const usdtId = `${bob.toHex()}-${usdtToken.toHex()}`;
                const usdcId = `${bob.toHex()}-${usdcToken.toHex()}`;

                assert.fieldEquals("StakerRewards", usdtId, "id", usdtId);
                assert.fieldEquals("StakerRewards", usdcId, "id", usdcId);
                assert.entityCount("StakerRewards", 2);
            });
        });

        describe("2 Standard FIXED bands for each staker", () => {
            beforeEach(() => {
                stakeStandardFixed(alice, bandLevels[1], bandIds[0], months[11], monthsAfterInit[1]);
                stakeStandardFixed(alice, bandLevels[2], bandIds[1], months[12], monthsAfterInit[1]);
                stakeStandardFixed(bob, bandLevels[4], bandIds[2], months[7], monthsAfterInit[1]);
                stakeStandardFixed(bob, bandLevels[5], bandIds[3], months[8], monthsAfterInit[1]);
                createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdtToken, monthsAfterInit[2]);
                createDistribution(usdcToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdcToken, monthsAfterInit[2]);
                deleteVestingUser(alice);
            });

            test("Should remove alice from all stakers", () => {
                const stakers = `[${bob.toHex()}]`;
                assert.fieldEquals("StakingContract", ids[0], "stakers", stakers);
                assert.notInStore("Staker", alice.toHex());
            });

            test("Should leave bob staker", () => {
                const bobId = bob.toHex();
                assert.fieldEquals("Staker", bobId, "id", bobId);
                assert.entityCount("Staker", 1);
            });

            test("Should remove alice's band from all bands", () => {
                assert.notInStore("Band", bandIds[0].toString());
                assert.notInStore("Band", bandIds[1].toString());
            });

            test("Should leave bob's bands", () => {
                const band2 = bandIds[2].toString();
                const band3 = bandIds[3].toString();
                assert.fieldEquals("Band", band2, "id", band2);
                assert.fieldEquals("Band", band3, "id", band3);
                assert.entityCount("Band", 2);
            });

            test("Should remove alice's rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                const usdcId = `${alice.toHex()}-${usdcToken.toHex()}`;

                assert.notInStore("StakerRewards", usdtId);
                assert.notInStore("StakerRewards", usdcId);
            });

            test("Should leave bob's rewards", () => {
                const usdtId = `${bob.toHex()}-${usdtToken.toHex()}`;
                const usdcId = `${bob.toHex()}-${usdcToken.toHex()}`;

                assert.fieldEquals("StakerRewards", usdtId, "id", usdtId);
                assert.fieldEquals("StakerRewards", usdcId, "id", usdcId);
                assert.entityCount("StakerRewards", 2);
            });
        });

        describe("1 Standard FLEXI bands for each staker", () => {
            beforeEach(() => {
                stakeStandardFlexi(alice, bandLevels[4], bandIds[0], monthsAfterInit[1]);
                stakeStandardFlexi(bob, bandLevels[7], bandIds[1], monthsAfterInit[1]);
                createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdtToken, monthsAfterInit[2]);
                createDistribution(usdcToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdcToken, monthsAfterInit[2]);
                deleteVestingUser(alice);
            });

            test("Should remove alice from all stakers", () => {
                const stakers = `[${bob.toHex()}]`;
                assert.fieldEquals("StakingContract", ids[0], "stakers", stakers);
                assert.notInStore("Staker", alice.toHex());
            });

            test("Should leave bob staker", () => {
                const bobId = bob.toHex();
                assert.fieldEquals("Staker", bobId, "id", bobId);
                assert.entityCount("Staker", 1);
            });

            test("Should remove alice's band from all bands", () => {
                assert.notInStore("Band", bandIds[0].toString());
            });

            test("Should leave bob's band", () => {
                const bobBandId = bandIds[1].toString();
                assert.fieldEquals("Band", bobBandId, "id", bobBandId);
                assert.entityCount("Band", 1);
            });

            test("Should remove alice's rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                const usdcId = `${alice.toHex()}-${usdcToken.toHex()}`;

                assert.notInStore("StakerRewards", usdtId);
                assert.notInStore("StakerRewards", usdcId);
            });

            test("Should leave bob's rewards", () => {
                const usdtId = `${bob.toHex()}-${usdtToken.toHex()}`;
                const usdcId = `${bob.toHex()}-${usdcToken.toHex()}`;

                assert.fieldEquals("StakerRewards", usdtId, "id", usdtId);
                assert.fieldEquals("StakerRewards", usdcId, "id", usdcId);
                assert.entityCount("StakerRewards", 2);
            });
        });

        describe("2 Standard FLEXI bands for each staker", () => {
            beforeEach(() => {
                stakeStandardFlexi(alice, bandLevels[1], bandIds[0], monthsAfterInit[1]);
                stakeStandardFlexi(alice, bandLevels[2], bandIds[1], monthsAfterInit[1]);
                stakeStandardFlexi(bob, bandLevels[4], bandIds[2], monthsAfterInit[1]);
                stakeStandardFlexi(bob, bandLevels[5], bandIds[3], monthsAfterInit[1]);
                createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdtToken, monthsAfterInit[2]);
                createDistribution(usdcToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdcToken, monthsAfterInit[2]);
                deleteVestingUser(alice);
            });

            test("Should remove alice from all stakers", () => {
                const stakers = `[${bob.toHex()}]`;
                assert.fieldEquals("StakingContract", ids[0], "stakers", stakers);
                assert.notInStore("Staker", alice.toHex());
            });

            test("Should leave bob staker", () => {
                const bobId = bob.toHex();
                assert.fieldEquals("Staker", bobId, "id", bobId);
                assert.entityCount("Staker", 1);
            });

            test("Should remove alice's band from all bands", () => {
                assert.notInStore("Band", bandIds[0].toString());
                assert.notInStore("Band", bandIds[1].toString());
            });

            test("Should leave bob's bands", () => {
                const band2 = bandIds[2].toString();
                const band3 = bandIds[3].toString();
                assert.fieldEquals("Band", band2, "id", band2);
                assert.fieldEquals("Band", band3, "id", band3);
                assert.entityCount("Band", 2);
            });

            test("Should remove alice's rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                const usdcId = `${alice.toHex()}-${usdcToken.toHex()}`;

                assert.notInStore("StakerRewards", usdtId);
                assert.notInStore("StakerRewards", usdcId);
            });

            test("Should leave bob's rewards", () => {
                const usdtId = `${bob.toHex()}-${usdtToken.toHex()}`;
                const usdcId = `${bob.toHex()}-${usdcToken.toHex()}`;

                assert.fieldEquals("StakerRewards", usdtId, "id", usdtId);
                assert.fieldEquals("StakerRewards", usdcId, "id", usdcId);
                assert.entityCount("StakerRewards", 2);
            });
        });

        describe("1 Standard FIXED band and 1 Standard FLEXI band for each staker", () => {
            beforeEach(() => {
                stakeStandardFixed(alice, bandLevels[1], bandIds[0], months[10], monthsAfterInit[1]);
                stakeStandardFlexi(alice, bandLevels[2], bandIds[1], monthsAfterInit[1]);
                stakeStandardFixed(bob, bandLevels[4], bandIds[2], months[10], monthsAfterInit[1]);
                stakeStandardFlexi(bob, bandLevels[5], bandIds[3], monthsAfterInit[1]);
                createDistribution(usdtToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdtToken, monthsAfterInit[2]);
                createDistribution(usdcToken, usd100k, monthsAfterInit[2]);
                distributeRewards(usdcToken, monthsAfterInit[2]);
                deleteVestingUser(alice);
            });

            test("Should remove alice from all stakers", () => {
                const stakers = `[${bob.toHex()}]`;
                assert.fieldEquals("StakingContract", ids[0], "stakers", stakers);
                assert.notInStore("Staker", alice.toHex());
            });

            test("Should leave bob staker", () => {
                const bobId = bob.toHex();
                assert.fieldEquals("Staker", bobId, "id", bobId);
                assert.entityCount("Staker", 1);
            });

            test("Should remove alice's band from all bands", () => {
                assert.notInStore("Band", bandIds[0].toString());
                assert.notInStore("Band", bandIds[1].toString());
            });

            test("Should leave bob's bands", () => {
                const band2 = bandIds[2].toString();
                const band3 = bandIds[3].toString();
                assert.fieldEquals("Band", band2, "id", band2);
                assert.fieldEquals("Band", band3, "id", band3);
                assert.entityCount("Band", 2);
            });

            test("Should remove alice's rewards", () => {
                const usdtId = `${alice.toHex()}-${usdtToken.toHex()}`;
                const usdcId = `${alice.toHex()}-${usdcToken.toHex()}`;

                assert.notInStore("StakerRewards", usdtId);
                assert.notInStore("StakerRewards", usdcId);
            });

            test("Should leave bob's rewards", () => {
                const usdtId = `${bob.toHex()}-${usdtToken.toHex()}`;
                const usdcId = `${bob.toHex()}-${usdcToken.toHex()}`;

                assert.fieldEquals("StakerRewards", usdtId, "id", usdtId);
                assert.fieldEquals("StakerRewards", usdcId, "id", usdcId);
                assert.entityCount("StakerRewards", 2);
            });
        });
    });
});
