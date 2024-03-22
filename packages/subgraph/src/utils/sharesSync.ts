import { Address, BigInt, BigDecimal, Bytes } from "@graphprotocol/graph-ts";
import { StakingContract, Band, BandLevel, Pool, Staker } from "../../generated/schema";
import {
    getOrInitPool,
    getOrInitBandLevel,
    getOrInitStaker,
    getOrInitBand,
    getOrInitStakingContract,
} from "../helpers/staking.helpers";
import {
    stakingTypeFIX,
    stakingTypeFLEXI,
    stringifyStakingType,
    StakerAndPoolShares,
    StakerShares,
} from "../utils/utils";
import { BIGINT_ONE, BIGINT_ZERO, BIGINT_PERCENTAGE_MULTIPLIER, StakingType } from "../utils/constants";

/*//////////////////////////////////////////////////////////////////////////
                            CALLED ON STAKE/UNSTAKE
//////////////////////////////////////////////////////////////////////////*/

export function addFixedShares(staker: Staker, band: Band, sharesInMonths: BigInt[], accessiblePools: string[]): void {
    // Update shares if band is FIX type
    if (band.stakingType != stakingTypeFIX) {
        return;
    }

    const stakerShares: BigInt[] = staker.fixedSharesPerPool;
    const stakerIsolatedShares: BigInt[] = staker.isolatedFixedSharesPerPool;

    // Get band shares that user will receive instantly
    const bandShares: BigInt = sharesInMonths[band.fixedMonths - 1];
    const totalAccessiblePools: number = accessiblePools.length;

    for (let i = 0; i < totalAccessiblePools; i++) {
        const pool: Pool = getOrInitPool(BigInt.fromString(accessiblePools[i]));

        // If last pool, add shares to isolated shares
        if (i == totalAccessiblePools - 1) {
            pool.isolatedFixedSharesAmount = pool.isolatedFixedSharesAmount.plus(bandShares);
            stakerIsolatedShares[i] = stakerIsolatedShares[i].plus(bandShares);
        }

        // Update pool shares
        pool.totalFixedSharesAmount = pool.totalFixedSharesAmount.plus(bandShares);
        pool.save();

        stakerShares[i] = stakerShares[i].plus(bandShares);
    }

    // Update staker shares
    staker.fixedSharesPerPool = stakerShares;
    staker.isolatedFixedSharesPerPool = stakerIsolatedShares;
    staker.save();

    // Update band shares
    band.sharesAmount = bandShares;
    band.save();
}

export function removeFixedShares(staker: Staker | null, band: Band, accessiblePools: string[]): void {
    if (band.stakingType == stakingTypeFIX) {
        const totalAccessiblePools: number = accessiblePools.length;
        const bandShares: BigInt = band.sharesAmount;

        // Update total shares for each pool
        for (let i = 0; i < totalAccessiblePools; i++) {
            const pool: Pool = getOrInitPool(BigInt.fromString(accessiblePools[i]));

            // If last pool, remove shares from isolated shares
            if (i == totalAccessiblePools - 1) {
                pool.isolatedFixedSharesAmount = pool.isolatedFixedSharesAmount.minus(bandShares);
            }

            pool.totalFixedSharesAmount = pool.totalFixedSharesAmount.minus(bandShares);
            pool.save();
        }

        // If staker was not removed, update staker shares
        if (staker) {
            const stakerShares: BigInt[] = staker.fixedSharesPerPool;
            const stakerIsolatedShares: BigInt[] = staker.isolatedFixedSharesPerPool;

            const shares: StakerShares = reduceSharesForStaker(
                stakerShares,
                stakerIsolatedShares,
                bandShares,
                totalAccessiblePools,
            );

            staker.fixedSharesPerPool = shares.sharesPerPool;
            staker.isolatedFixedSharesPerPool = shares.isolatedSharesPerPool;
            staker.save();
        }
    }
}

export function removeFlexiShares(staker: Staker | null, band: Band, accessiblePools: string[]): void {
    if (band.stakingType == stakingTypeFIX) {
        const totalAccessiblePools: number = accessiblePools.length;
        const bandShares: BigInt = band.sharesAmount;

        // Update total shares for each pool
        for (let i = 0; i < totalAccessiblePools; i++) {
            const pool: Pool = getOrInitPool(BigInt.fromString(accessiblePools[i]));

            // If last pool, remove shares from isolated shares
            if (i == totalAccessiblePools - 1) {
                pool.isolatedFlexiSharesAmount = pool.isolatedFlexiSharesAmount.minus(bandShares);
            }

            pool.totalFlexiSharesAmount = pool.totalFlexiSharesAmount.minus(bandShares);
            pool.save();
        }

        // If staker was not removed, update staker shares
        if (staker) {
            const stakerShares: BigInt[] = staker.flexiSharesPerPool;
            const stakerIsolatedShares: BigInt[] = staker.isolatedFlexiSharesPerPool;

            const shares: StakerShares = reduceSharesForStaker(
                stakerShares,
                stakerIsolatedShares,
                bandShares,
                totalAccessiblePools,
            );

            staker.flexiSharesPerPool = shares.sharesPerPool;
            staker.isolatedFlexiSharesPerPool = shares.isolatedSharesPerPool;
            staker.save();
        }
    }
}

function reduceSharesForStaker(
    stakerShares: BigInt[],
    stakerIsolatedShares: BigInt[],
    bandShares: BigInt,
    totalAccessiblePools: number,
): StakerShares {
    // Update staker shares for each accessible pool
    for (let i = 0; i < totalAccessiblePools; i++) {
        stakerShares[i] = stakerShares[i].minus(bandShares);
    }

    // Type cast to BigInt to avoid TS error
    const lastPoolIndex = BigInt.fromString(totalAccessiblePools.toString()).toI32() - 1;
    stakerIsolatedShares[lastPoolIndex] = stakerIsolatedShares[lastPoolIndex].minus(bandShares);

    return new StakerShares(stakerShares, stakerIsolatedShares);
}

/*//////////////////////////////////////////////////////////////////////////
                              FLEXI BANDS SYNC
//////////////////////////////////////////////////////////////////////////*/

// Sync all shares for stakers and pools each 12 hours
export function syncFlexiSharesEvery12Hours(currentTime: BigInt): boolean {
    const staking: StakingContract = getOrInitStakingContract();
    const lastSyncDate: BigInt = staking.lastSharesSyncDate;
    const timePassed = currentTime.minus(lastSyncDate);
    const minSyncInterval: BigInt = BigInt.fromI32(60 * 60 * 12); // 12 hours in seconds

    // If at least 12 hours passed since last sync, update shares
    if (timePassed.ge(minSyncInterval)) {
        // Update shares for pools and stakers
        updateFlexiSharesDuringSync(staking, currentTime);

        // Update last sync date
        staking.lastSharesSyncDate = currentTime;
        staking.save();

        return true;
    }

    return false;
}

export function calculateAllShares(stakingContract: StakingContract, distributionDate: BigInt): StakerAndPoolShares {
    // Update flexi shares for stakers, bands and pools
    const sharesData: StakerAndPoolShares = updateFlexiSharesDuringSync(stakingContract, distributionDate);
    const totalPools: number = stakingContract.totalPools;
    const stakers: string[] = sharesData.stakers;
    const stakersCount: number = stakers.length;
    const sharesForStakers: BigInt[][] = sharesData.sharesForStakers;
    const sharesForPools: BigInt[] = sharesData.sharesForPools;

    // Loop through all stakers and pools to add fixed shares to the stakers
    for (let stakerIndex = 0; stakerIndex < stakersCount; stakerIndex++) {
        const staker: Staker = getOrInitStaker(Address.fromString(stakers[stakerIndex]));
        const fixedSharesPerPool: BigInt[] = staker.fixedSharesPerPool;

        for (let poolIndex = 0; poolIndex < totalPools; poolIndex++) {
            sharesForStakers[stakerIndex][poolIndex] = sharesForStakers[stakerIndex][poolIndex].plus(
                fixedSharesPerPool[poolIndex],
            );
        }
    }

    // Loop through all pools and add fixed shares to the pools
    for (let poolIndex = 0; poolIndex < totalPools; poolIndex++) {
        const pool: Pool = getOrInitPool(BigInt.fromI32(poolIndex + 1));
        sharesForPools[poolIndex] = sharesForPools[poolIndex].plus(pool.totalFixedSharesAmount);
    }

    return new StakerAndPoolShares(stakers, sharesForStakers, sharesForPools);
}

// Update shares for pools and stakers when sync or distribution starts
export function updateFlexiSharesDuringSync(staking: StakingContract, distributionDate: BigInt): StakerAndPoolShares {
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

function addPoolsAndStakersShares(
    stakers: string[],
    totalPools: BigInt,
    distributionDate: BigInt,
    bandLevelPoolIds: BigInt[][],
    sharesInMonth: BigInt[],
): StakerAndPoolShares {
    // Initialize array with 0 shares for each pool
    const sharesForPools: BigInt[] = new Array<BigInt>(totalPools.toI32()).fill(BIGINT_ZERO);
    const isolatedSharesForPools: BigInt[] = new Array<BigInt>(totalPools.toI32()).fill(BIGINT_ZERO);

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
        const stakerShares: StakerShares = addMultipleBandSharesToPools(
            staker,
            totalPools,
            distributionDate,
            bandLevelPoolIds,
            sharesInMonth,
        );

        // Add shares to the staker
        sharesForStakers.push(stakerShares.sharesPerPool);

        // Update staker shares for pools in the database and save it
        staker.flexiSharesPerPool = stakerShares.sharesPerPool;
        staker.isolatedFlexiSharesPerPool = stakerShares.isolatedSharesPerPool;
        staker.save();

        // Loop through all pools and add staker shares to the pool
        for (let poolIndex = 0; poolIndex < totalPools.toI32(); poolIndex++) {
            // Add staker shares to the pool
            const poolShare: BigInt = stakerShares.sharesPerPool[poolIndex];
            sharesForPools[poolIndex] = sharesForPools[poolIndex].plus(poolShare);

            // Add isolated shares to the pool
            const isolatedPoolShare: BigInt = stakerShares.isolatedSharesPerPool[poolIndex];
            isolatedSharesForPools[poolIndex] = isolatedSharesForPools[poolIndex].plus(isolatedPoolShare);
        }
    }

    // Update pool shares in the database and save it
    for (let poolIndex = 0; poolIndex < totalPools.toI32(); poolIndex++) {
        const pool: Pool = getOrInitPool(BigInt.fromI32(poolIndex + 1));
        pool.totalFlexiSharesAmount = sharesForPools[poolIndex];
        pool.isolatedFlexiSharesAmount = isolatedSharesForPools[poolIndex];
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
): StakerShares {
    const bandIds: string[] = staker.flexiBands;
    const bandsAmount: number = bandIds.length;

    // Initialize arrays with 0 shares for each pool
    const stakerSharesPerPool: BigInt[] = new Array<BigInt>(totalPools.toI32()).fill(BIGINT_ZERO);
    const isolatedStakerSharesPerPool: BigInt[] = new Array<BigInt>(totalPools.toI32()).fill(BIGINT_ZERO);

    // Loop through all bands that staker owns and set the amount of shares
    for (let bandIndex = 0; bandIndex < bandsAmount; bandIndex++) {
        const bandId: BigInt = BigInt.fromString(bandIds[bandIndex]);
        const band: Band = getOrInitBand(bandId);
        const bandShares: BigInt = calculateBandShares(band, distributionDate, sharesInMonth);

        // No need to add shares if there is nothing to add
        if (bandShares.equals(BIGINT_ZERO)) {
            continue;
        }

        const bandLevel = BigInt.fromString(band.bandLevel).toI32();
        const poolIds: BigInt[] = bandLevelPoolIds[bandLevel - 1];
        const poolsCount = poolIds.length;

        // Update shares amount in database and save it
        band.sharesAmount = bandShares;
        band.save();

        // Loop through all pools and set the amount of shares
        for (let poolIndex = 0; poolIndex < poolsCount; poolIndex++) {
            // Add shares to the staker in the pool
            stakerSharesPerPool[poolIndex] = stakerSharesPerPool[poolIndex].plus(bandShares);
        }

        // For last pool, add shares to isolated shares
        const lastPoolIndex = poolsCount - 1;
        isolatedStakerSharesPerPool[lastPoolIndex] = isolatedStakerSharesPerPool[lastPoolIndex].plus(bandShares);
    }

    return new StakerShares(isolatedStakerSharesPerPool, stakerSharesPerPool);
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

    // Calculate months that passed since staking started
    const monthsPassed = calculateCompletedMonths(band.stakingStartDate, endDateInSeconds).toI32();

    // If at least 1 month passed, calculate shares based on months
    if (monthsPassed > 0) {
        const totalMonths = sharesInMonth.length;

        // If more months passed than we have in the array, use the last month
        if (monthsPassed > totalMonths) {
            bandShares = sharesInMonth[totalMonths - 1];
        } else {
            bandShares = sharesInMonth[monthsPassed - 1];
        }
    }

    return bandShares;
}
