import { BigInt, log } from "@graphprotocol/graph-ts";
import { StakingContract, Pool } from "../../../generated/schema";
import { getOrInitPool } from "../../helpers/staking.helpers";
import { StakerAndPoolShares } from "../classes";
import { BIGINT_ZERO } from "../constants";

/*//////////////////////////////////////////////////////////////////////////
                                  MAIN FUNCTION
//////////////////////////////////////////////////////////////////////////*/

export function calculateRewards(staking: StakingContract, amount: BigInt, sharesData: StakerAndPoolShares): BigInt[] {
    // Get amount of pools (cache value)
    const totalPools: BigInt = BigInt.fromI32(staking.totalPools);

    // Calculate how many tokens each pool will receive
    const poolAllocations: BigInt[] = calculateAllPoolAllocations(staking, totalPools.toI32(), amount);

    // Add rewards for each staker
    const stakerRewards: BigInt[] = addStakerRewards(
        sharesData.sharesForStakers,
        sharesData.sharesForPools,
        poolAllocations,
        amount,
    );

    return stakerRewards;
}

/*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

function addStakerRewards(
    sharesForStakers: BigInt[][],
    sharesForPools: BigInt[],
    poolAllocations: BigInt[],
    distributionAmount: BigInt,
): BigInt[] {
    const stakersCount: number = sharesForStakers.length;
    const poolsCount: number = poolAllocations.length;
    const stakerRewards: BigInt[] = [];
    let distributedAmount: BigInt = BIGINT_ZERO;

    // Loop through each staker and distribute funds
    for (let stakerIndex = 0; stakerIndex < stakersCount; stakerIndex++) {
        const stakerShares = sharesForStakers[stakerIndex];
        let allocation: BigInt = BIGINT_ZERO;

        // Loop through all pools and distribute funds to the staker
        for (let poolIndex = 0; poolIndex < poolsCount; poolIndex++) {
            const stakerPoolShares: BigInt = stakerShares[poolIndex];
            const totalPoolShares: BigInt = sharesForPools[poolIndex];

            // If staker has shares in the pool, calculate the amount of tokens
            if (stakerPoolShares.gt(BIGINT_ZERO) && totalPoolShares.gt(BIGINT_ZERO)) {
                const totalAmount: BigInt = poolAllocations[poolIndex];

                // Calculate the amount of tokens for the staker and add it to the total allocation
                allocation = allocation.plus(totalAmount.times(stakerPoolShares).div(totalPoolShares));
            }
        }

        stakerRewards.push(allocation);
        distributedAmount = distributedAmount.plus(allocation);
    }

    // Check if algorithm distributed the correct amount of tokens
    // If not, log an error and return null to indicate that distribution
    // should not be created in the subgraph for gelato to handle it
    if (distributedAmount.gt(distributionAmount)) {
        log.error("Distributed amount ({}) is greater than the distribution size ({}).", [
            distributedAmount.toString(),
            distributionAmount.toString(),
        ]);

        return [];
    }

    return stakerRewards;
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
