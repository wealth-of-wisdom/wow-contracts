import { Address, BigInt, Bytes } from "@graphprotocol/graph-ts";
import { StakingContract, Band, BandLevel, Pool, Staker } from "../../generated/schema";
import {
    getOrInitPool,
    getOrInitBandLevel,
    getOrInitStaker,
    getOrInitBand,
    getOrInitStakingContract,
} from "../helpers/staking.helpers";
import { stringifyStakingType } from "../utils/utils";
import { BIGINT_ONE, BIGINT_ZERO, StakingType } from "../utils/constants";

/*//////////////////////////////////////////////////////////////////////////
                            CLASSES TO RETURN VALUES
//////////////////////////////////////////////////////////////////////////*/

export class StakerAndPoolShares {
    constructor(
        public stakers: string[],
        public sharesForStakers: BigInt[][],
        public sharesForPools: BigInt[],
    ) {}
}

/*//////////////////////////////////////////////////////////////////////////
                                  MAIN FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

// Sync all shares for stakers and pools each 12 hours
export function syncAllSharesEvery12Hours(currentTime: BigInt): boolean {
    const staking: StakingContract = getOrInitStakingContract();
    const lastSyncDate: BigInt = staking.lastSharesSyncDate;
    const timePassed = currentTime.minus(lastSyncDate);
    const minSyncInterval: BigInt = BigInt.fromI32(60 * 60 * 12); // 12 hours in seconds

    // If at least 12 hours passed since last sync, update shares
    if (timePassed.ge(minSyncInterval)) {
        // Update shares for pools and stakers
        updateSharesForPoolsAndStakers(staking, currentTime);

        // Update last sync date
        staking.lastSharesSyncDate = currentTime;
        staking.save();

        return true;
    }

    return false;
}

// Update shares for pools and stakers when sync or distribution starts
export function updateSharesForPoolsAndStakers(
    staking: StakingContract,
    distributionDate: BigInt,
): StakerAndPoolShares {
    // Get shares for each month
    const sharesInMonth: BigInt[] = staking.sharesInMonths;

    // Get amount of pools (cache value)
    const totalPools: BigInt = BigInt.fromI32(staking.totalPools);

    // Loop through all band levels once to store all accessible pools
    const bandLevelPoolIds: BigInt[][] = getBandLevelPoolIds(staking.totalBandLevels);

    // Get all stakers to loop through them
    // Leave as string because it is going to be used for calling function by gelato function
    const stakers: string[] = staking.stakers;

    // Add shares for each staker and pool
    const sharesData: StakerAndPoolShares = addPoolsAndStakersShares(
        stakers,
        totalPools,
        distributionDate,
        bandLevelPoolIds,
        sharesInMonth,
    );

    return sharesData;
}

export function updateSharesWhenStaked(
    staker: Staker,
    band: Band,
    sharesInMonths: BigInt[],
    accessiblePools: string[],
    executionDate: BigInt,
): void {
    // Try to sync all stakers shares
    const syncExecuted: boolean = syncAllSharesEvery12Hours(executionDate);

    // If full sync was not executed, update only the shares for the staker and the pools that changed
    if (!syncExecuted && band.fixedMonths > 0) {
        const stakerSharesPerPool = staker.sharesPerPool;

        // Get band shares that user will receive instantly
        const bandShares = sharesInMonths[band.fixedMonths - 1];

        // Update band shares
        band.sharesAmount = bandShares;
        band.save();

        const totalAccessiblePools = accessiblePools.length;
        for (let i = 0; i < totalAccessiblePools; i++) {
            // Update total pool shares
            const pool = getOrInitPool(BigInt.fromString(accessiblePools[i]));
            pool.totalSharesAmount = pool.totalSharesAmount.plus(bandShares);
            pool.save();

            stakerSharesPerPool[i] = stakerSharesPerPool[i].plus(bandShares);
        }

        // Update staker shares
        staker.sharesPerPool = stakerSharesPerPool;
        staker.save();
    }
}

export function updateSharesWhenUnstaked(
    staker: Staker | null,
    bandShares: BigInt,
    accessiblePools: string[],
    executionDate: BigInt,
): void {
    const syncExecuted: boolean = syncAllSharesEvery12Hours(executionDate);

    if (!syncExecuted) {
        const totalAccessiblePools: number = accessiblePools.length;

        // Update total shares for each pool
        for (let i = 0; i < totalAccessiblePools; i++) {
            const pool: Pool = getOrInitPool(BigInt.fromString(accessiblePools[i]));
            pool.totalSharesAmount = pool.totalSharesAmount.minus(bandShares);
            pool.save();
        }

        // If staker was not removed, update staker shares
        if (staker) {
            const stakerSharesPerPool: BigInt[] = staker.sharesPerPool;

            // Update staker shares for each accessible pool
            for (let i = 0; i < totalAccessiblePools; i++) {
                stakerSharesPerPool[i] = stakerSharesPerPool[i].minus(bandShares);
            }

            staker.sharesPerPool = stakerSharesPerPool;
            staker.save();
        }
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

function addPoolsAndStakersShares(
    stakers: string[],
    totalPools: BigInt,
    distributionDate: BigInt,
    bandLevelPoolIds: BigInt[][],
    sharesInMonth: BigInt[],
): StakerAndPoolShares {
    // Initialize array with 0 shares for each pool
    const sharesForPools: BigInt[] = new Array<BigInt>(totalPools.toI32()).fill(BIGINT_ZERO);

    // Array of pools shares amount for each staker
    // We don't use TypedMap because it cannot be converted to arrays
    const sharesForStakers: BigInt[][] = [];

    // Get all stakers to loop through them
    const stakersCount = stakers.length;

    // Loop through all stakers and set the amount of shares
    for (let stakerIndex = 0; stakerIndex < stakersCount; stakerIndex++) {
        // Get or initialize staker
        const staker: Staker = getOrInitStaker(Address.fromString(stakers[stakerIndex]));

        // Loop through all bands and add shares to pools
        const stakerSharesPerPool: BigInt[] = addMultipleBandSharesToPools(
            staker,
            totalPools,
            distributionDate,
            bandLevelPoolIds,
            sharesInMonth,
        );

        // Add shares to the staker
        sharesForStakers.push(stakerSharesPerPool);

        // Update staker shares for pools in the database and save it
        staker.sharesPerPool = stakerSharesPerPool;
        staker.save();

        // Loop through all pools and add staker shares to the pool
        for (let poolIndex = 0; poolIndex < totalPools.toI32(); poolIndex++) {
            const poolShare: BigInt = stakerSharesPerPool[poolIndex];

            if (poolShare.gt(BIGINT_ZERO)) {
                // Add staker shares to the pool
                sharesForPools[poolIndex] = sharesForPools[poolIndex].plus(poolShare);
            }
        }
    }

    // Update pool shares in the database and save it
    for (let poolIndex = 0; poolIndex < totalPools.toI32(); poolIndex++) {
        const pool: Pool = getOrInitPool(BigInt.fromI32(poolIndex + 1));
        pool.totalSharesAmount = sharesForPools[poolIndex];
        pool.save();
    }

    return new StakerAndPoolShares(stakers, sharesForStakers, sharesForPools);
}

function addMultipleBandSharesToPools(
    staker: Staker,
    totalPools: BigInt,
    distributionDate: BigInt,
    bandLevelPoolIds: BigInt[][],
    sharesInMonth: BigInt[],
): BigInt[] {
    const bandIds: string[] = staker.bands;
    const bandsAmount: number = bandIds.length;

    // Initialize array with 0 shares for each pool
    const stakerSharesPerPool: BigInt[] = new Array<BigInt>(totalPools.toI32()).fill(BIGINT_ZERO);

    // Loop through all bands that staker owns and set the amount of shares
    for (let bandIndex = 0; bandIndex < bandsAmount; bandIndex++) {
        const bandId: BigInt = BigInt.fromString(bandIds[bandIndex]);
        const band: Band = getOrInitBand(bandId);
        const bandShares: BigInt = calculateBandShares(band, distributionDate, sharesInMonth);

        // No need to add shares if there is nothing to add
        if (bandShares.gt(BIGINT_ZERO)) {
            const bandLevel: BigInt = BigInt.fromString(band.bandLevel);
            const poolIds: BigInt[] = bandLevelPoolIds[bandLevel.minus(BIGINT_ONE).toI32()];
            const poolsAmount: number = poolIds.length;

            // Update shares amount in database and save it
            band.sharesAmount = bandShares;
            band.save();

            // Loop through all pools and set the amount of shares
            for (let poolIndex = 0; poolIndex < poolsAmount; poolIndex++) {
                // Typecast to BigInt because it's a number (f64) and we need number (i32)
                const poolIdx: BigInt = poolIds[poolIndex].minus(BIGINT_ONE);

                // Add shares to the staker in the pool
                stakerSharesPerPool[poolIdx.toI32()] = stakerSharesPerPool[poolIdx.toI32()].plus(bandShares);
            }
        }
    }

    return stakerSharesPerPool;
}

function getBandLevelPoolIds(totalBandLevels: number): BigInt[][] {
    const allPoolIds: BigInt[][] = [];

    // Loop through all band levels and store all accessible pools
    for (let bandLevel = 1; bandLevel <= totalBandLevels; bandLevel++) {
        const bandLevelData: BandLevel = getOrInitBandLevel(BigInt.fromI32(bandLevel));
        const poolsCount: number = bandLevelData.accessiblePools.length;
        const poolIds: BigInt[] = [];

        // Loop through all pools and store the pool id as number
        for (let poolIndex = 0; poolIndex < poolsCount; poolIndex++) {
            const poolId: BigInt = BigInt.fromString(bandLevelData.accessiblePools[poolIndex]);
            poolIds.push(poolId);
        }

        allPoolIds.push(poolIds);
    }

    return allPoolIds;
}

function calculateCompletedMonths(startDateInSeconds: BigInt, endDateInSeconds: BigInt): BigInt {
    // 60 seconds * 60 minutes * 24 hours * 30 days
    // This is hardcoded because it's a constant value
    const secondsInMonth: BigInt = BigInt.fromI32(60 * 60 * 24 * 30);
    const completedMonths = endDateInSeconds.minus(startDateInSeconds).div(secondsInMonth);

    return completedMonths;
}

function calculateBandShares(band: Band, endDateInSeconds: BigInt, sharesInMonth: BigInt[]): BigInt {
    let bandShares: BigInt = BIGINT_ZERO;

    // If staking type is FLEXI calculate shares based on months passed
    if (band.stakingType == stringifyStakingType(StakingType.FLEXI)) {
        // Calculate months that passed since staking started
        const monthsPassed: BigInt = calculateCompletedMonths(band.stakingStartDate, endDateInSeconds);

        // If at least 1 month passed, calculate shares based on months
        if (monthsPassed.gt(BIGINT_ZERO)) {
            bandShares = sharesInMonth[monthsPassed.minus(BIGINT_ONE).toI32()];
        }
    }
    // Else type is FIX
    else {
        // For FIX type, shares are set at the start and do not change over time
        bandShares = sharesInMonth[band.fixedMonths - 1];
    }

    return bandShares;
}
