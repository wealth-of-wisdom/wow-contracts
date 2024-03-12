import { Address, BigInt, log } from "@graphprotocol/graph-ts";
import { StakingContract, Band, BandLevel, Pool, Staker } from "../../generated/schema";
import { getOrInitPool, getOrInitBandLevel, getOrInitStaker, getOrInitBand } from "../helpers/staking.helpers";
import { stringifyStakingType } from "../utils/utils";
import { BIGINT_ONE, BIGINT_ZERO, StakingType } from "../utils/constants";

/*//////////////////////////////////////////////////////////////////////////
                            CLASSES TO RETURN VALUES
//////////////////////////////////////////////////////////////////////////*/

export class StakersAndRewards {
    constructor(
        public stakers: string[],
        public rewards: BigInt[],
    ) {}
}

export class StakerAndPoolShares {
    constructor(
        public sharesForStakers: BigInt[][],
        public sharesForPools: BigInt[],
    ) {}
}

/*//////////////////////////////////////////////////////////////////////////
                                  MAIN FUNCTION
//////////////////////////////////////////////////////////////////////////*/

export function calculateRewards(
    staking: StakingContract,
    amount: BigInt,
    distributionDate: BigInt,
): StakersAndRewards {
    // Get shares for each month
    const sharesInMonth: BigInt[] = staking.sharesInMonths;

    // Get amount of pools (cache value)
    const totalPools: BigInt = BigInt.fromI32(staking.totalPools);

    // Calculate how many tokens each pool will receive
    const poolAllocations: BigInt[] = calculateAllPoolAllocations(staking, totalPools.toI32(), amount);

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

    // Add rewards for each staker
    const stakerRewards: BigInt[] = addStakerRewards(
        sharesData.sharesForStakers,
        sharesData.sharesForPools,
        poolAllocations,
    );

    return new StakersAndRewards(stakers, stakerRewards);
}

/*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONs
//////////////////////////////////////////////////////////////////////////*/

function addStakerRewards(sharesForStakers: BigInt[][], sharesForPools: BigInt[], poolAllocations: BigInt[]): BigInt[] {
    const stakersCount: number = sharesForStakers.length;
    const stakerRewards: BigInt[] = [];

    // Loop through each staker and distribute funds
    for (let i = 0; i < stakersCount; i++) {
        const stakerShares = sharesForStakers[i];
        const poolsCount: number = poolAllocations.length;
        let allocation: BigInt = BIGINT_ZERO;

        // Loop through all pools and distribute funds to the staker
        for (let j = 0; j < poolsCount; j++) {
            const stakerPoolShares: BigInt = stakerShares[j];
            const totalPoolShares: BigInt = sharesForPools[j];

            // If staker has shares in the pool, calculate the amount of tokens
            if (stakerPoolShares.gt(BIGINT_ZERO) && totalPoolShares.gt(BIGINT_ZERO)) {
                const totalAmount: BigInt = poolAllocations[j];

                // Calculate the amount of tokens for the staker and add it to the total allocation
                allocation = allocation.plus(totalAmount.times(stakerPoolShares).div(totalPoolShares));
            }
        }

        stakerRewards.push(allocation);
    }

    return stakerRewards;
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

    // Array of pools shares amount for each staker
    // We don't use TypedMap because it cannot be converted to arrays
    const sharesForStakers: BigInt[][] = [];

    // Get all stakers to loop through them
    const stakersCount = stakers.length;

    // Loop through all stakers and set the amount of shares
    for (let i = 0; i < stakersCount; i++) {
        const staker: Staker = getOrInitStaker(Address.fromString(stakers[i]));

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

        // Loop through all pools and add staker shares to the pool
        for (let j = 0; j < totalPools.toI32(); j++) {
            const poolShare: BigInt = stakerSharesPerPool[j];

            if (poolShare.gt(BIGINT_ZERO)) {
                // Add staker shares to the pool
                sharesForPools[j] = sharesForPools[j].plus(poolShare);
            }
        }
    }

    return new StakerAndPoolShares(sharesForStakers, sharesForPools);
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
    for (let i = 0; i < bandsAmount; i++) {
        const bandId: BigInt = BigInt.fromString(bandIds[i]);
        const band: Band = getOrInitBand(bandId);
        const bandShares: BigInt = calculateBandShares(band, distributionDate, sharesInMonth);

        // No need to add shares if there is nothing to add
        if (bandShares.gt(BIGINT_ZERO)) {
            const bandLevel: BigInt = BigInt.fromString(band.bandLevel);
            const poolIds: BigInt[] = bandLevelPoolIds[bandLevel.minus(BIGINT_ONE).toI32()];
            const poolsAmount: number = poolIds.length;

            // Loop through all pools and set the amount of shares
            for (let j = 0; j < poolsAmount; j++) {
                // Typecast to BigInt because it's a number (f64) and we need number (i32)
                const poolIndex: BigInt = poolIds[j].minus(BIGINT_ONE);

                // Add shares to the staker in the pool
                stakerSharesPerPool[poolIndex.toI32()] = stakerSharesPerPool[poolIndex.toI32()].plus(bandShares);
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
        for (let poolId = 0; poolId < poolsCount; poolId++) {
            const poolIdNum: BigInt = BigInt.fromString(bandLevelData.accessiblePools[poolId]);
            poolIds.push(poolIdNum);
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

function calculateAllPoolAllocations(staking: StakingContract, totalPools: number, totalAmount: BigInt): BigInt[] {
    const percentagePrecision: BigInt = BigInt.fromI32(staking.percentagePrecision);
    const allocations: BigInt[] = [];

    // Loop through all pools and set the amount of tokens
    for (let poolId = 1; poolId <= totalPools; poolId++) {
        // Calculate the amount of tokens for the pool
        const poolTokens: BigInt = calculatePoolAllocation(totalAmount, percentagePrecision, BigInt.fromI32(poolId));

        allocations.push(poolTokens);
    }

    return allocations;
}

function calculatePoolAllocation(totalAmount: BigInt, percentagePrecision: BigInt, poolId: BigInt): BigInt {
    const pool: Pool = getOrInitPool(poolId);
    const distributionPercentage: BigInt = BigInt.fromI32(pool.distributionPercentage);

    // totalAmount * (distribution% * 10**6) / (100% * 10**6)
    const poolTokens: BigInt = totalAmount.times(distributionPercentage).div(percentagePrecision);

    return poolTokens;
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
