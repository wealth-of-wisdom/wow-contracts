import { TypedMap, Address, BigInt } from "@graphprotocol/graph-ts";
import { StakingContract, Band, BandLevel, Pool } from "../../generated/schema";
import { Staking } from "../../generated/Staking/Staking";
import { getOrInitPool, getOrInitBandLevel } from "../helpers/staking.helpers";
import { stringifyStakingType } from "../utils/utils";
import { BIGINT_ZERO, BIGINT_ONE, StakingType } from "../utils/constants";

/*//////////////////////////////////////////////////////////////////////////
                                  MAIN FUNCTION
//////////////////////////////////////////////////////////////////////////*/

export function calculateRewards(stakingContract: StakingContract, token: Address, amount: BigInt): void {
    const sharesInMonth: BigInt[] = stakingContract.sharesInMonths;
}

/*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONs
//////////////////////////////////////////////////////////////////////////*/

function addUserRewards(
    poolAllocations: BigInt[],
    sharesForPools: number[],
    sharesForUsers: Map<string, number[]>,
): TypedMap<string, BigInt> {
    return new TypedMap<string, BigInt>();
}

// @todo use double array instead of mapping, the TypedMap cannot be converted to arrays
// function addPoolsAndUsersShares(
//     staking: Staking,
//     totalPools: number,
//     usersAmount: number,
//     distributionDate: number,
//     bandLevelPoolIds: number[][],
//     sharesInMonth: number[],
// ): [number[], TypedMap⁠<string, number[]>] {
//     return [[], new TypedMap<string, number[]>()];
// }

function addMultipleBandSharesToPools(
    staking: Staking,
    user: string,
    totalPools: number,
    distributionDate: number,
    bandLevelPoolIds: number[][],
    sharesInMonth: number[],
): number[] {
    return [];
}

function getBandLevelPoolIds(staking: Staking, totalBandLevels: number): number[][] {
    const poolIds: number[][] = [];

    // Loop through all band levels and store all accessible pools
    for (let bandLevel = 1; bandLevel <= totalBandLevels; bandLevel++) {
        const bandLevelData: BandLevel = getOrInitBandLevel(BigInt.fromI32(bandLevel));

        const poolIds: number[] = [];
        const poolsCount: number = bandLevelData.accessiblePools.length;
    //     for (let poolId = 0; poolId < poolsCount; poolId++) {
    //         poolIds.push(bandLevelData.accessiblePools[poolId.toString()]);
    //     }

    //     poolIds.push(bandLevelData.accessiblePools);
    // }

    return poolIds;
}

function calculateCompletedMonths(startDateInSeconds: BigInt, endDateInSeconds: BigInt): number {
    // 60 seconds * 60 minutes * 24 hours * 30 days
    // This is hardcoded because it's a constant value
    const secondsInMonth: BigInt = BigInt.fromI32(60 * 60 * 24 * 30);
    const completedMonths = endDateInSeconds.minus(startDateInSeconds).div(secondsInMonth).toI32();

    return completedMonths;
}

function calculateAllPoolAllocations(
    stakingContract: StakingContract,
    totalPools: number,
    totalAmount: BigInt,
): BigInt[] {
    const percentagePrecision: BigInt = BigInt.fromI32(stakingContract.percentagePrecision);
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
        const monthsPassed: number = calculateCompletedMonths(band.stakingStartDate, endDateInSeconds);

        // If at least 1 month passed, calculate shares based on months
        if (monthsPassed > 0) {
            bandShares = sharesInMonth[monthsPassed - 1];
        }
    }
    // Else type is FIX
    else {
        // For FIX type, shares are set at the start and do not change over time
        bandShares = sharesInMonth[band.fixedMonths - 1];
    }

    return bandShares;
}
