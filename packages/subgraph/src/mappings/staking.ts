import { Address, BigInt, store } from "@graphprotocol/graph-ts";
import {
    Initialized as InitializedEvent,
    PoolSet as PoolSetEvent,
    BandLevelSet as BandLevelSetEvent,
    SharesInMonthSet as SharesInMonthSetEvent,
    UsdtTokenSet as UsdtTokenSetEvent,
    UsdcTokenSet as UsdcTokenSetEvent,
    WowTokenSet as WowTokenSetEvent,
    TotalBandLevelsAmountSet as TotalBandLevelsAmountSetEvent,
    TotalPoolAmountSet as TotalPoolAmountSetEvent,
    BandUpgradeStatusSet as BandUpgradeStatusSetEvent,
    TokensWithdrawn as TokensWithdrawnEvent,
    DistributionCreated as DistributionCreatedEvent,
    RewardsDistributed as RewardsDistributedEvent,
    SharesSyncTriggered as SharesSyncTriggeredEvent,
    Staked as StakedEvent,
    Unstaked as UnstakedEvent,
    VestingUserDeleted as VestingUserDeletedEvent,
    BandDowngraded as BandDowngradedEvent,
    BandUpgraded as BandUpgradedEvent,
    RewardsClaimed as RewardsClaimedEvent,
    Staking,
} from "../../generated/Staking/Staking";
import {
    Band,
    BandLevel,
    Staker,
    StakingContract,
    Pool,
    FundsDistribution,
    StakerRewards,
} from "../../generated/schema";
import {
    getOrInitStakingContract,
    getOrInitPool,
    getOrInitBandLevel,
    getOrInitStaker,
    getOrInitStakerRewards,
    getOrInitBand,
    getOrInitFundsDistribution,
} from "../helpers/staking.helpers";
import { stringifyStakingType } from "../utils/utils";
import { calculateRewards } from "../utils/rewardsCalculation";
import {
    syncAllSharesEvery12Hours,
    updateSharesForPoolsAndStakers,
    updateSharesWhenStaked,
    updateSharesWhenUnstaked,
    StakerAndPoolShares,
} from "../utils/sharesSync";
import { claimRewardsFromUnclaimedAmount } from "../utils/rewardsClaim";
import { BIGINT_ZERO, BIGINT_ONE } from "../utils/constants";

export function handleInitialized(event: InitializedEvent): void {
    const stakingContract: StakingContract = getOrInitStakingContract();

    const staking: Staking = Staking.bind(event.address);
    stakingContract.stakingContractAddress = event.address;
    stakingContract.usdtToken = staking.getTokenUSDT();
    stakingContract.usdcToken = staking.getTokenUSDC();
    stakingContract.wowToken = staking.getTokenWOW();
    stakingContract.percentagePrecision = staking.PERCENTAGE_PRECISION().toI32();
    stakingContract.totalPools = staking.getTotalPools();
    stakingContract.totalBandLevels = staking.getTotalBandLevels();
    stakingContract.lastSharesSyncDate = event.block.timestamp;
    stakingContract.save();
}

export function handlePoolSet(event: PoolSetEvent): void {
    const pool: Pool = getOrInitPool(BigInt.fromI32(event.params.poolId));

    pool.distributionPercentage = event.params.distributionPercentage.toI32();
    pool.save();
}

export function handleBandLevelSet(event: BandLevelSetEvent): void {
    const bandLevel: BandLevel = getOrInitBandLevel(BigInt.fromI32(event.params.bandLevel));
    const bandPoolIds = bandLevel.accessiblePools;

    const poolsAmount: number = event.params.accessiblePools.length;
    for (let i = 0; i < poolsAmount; i++) {
        const pool: Pool = getOrInitPool(BigInt.fromI32(event.params.accessiblePools[i]));
        bandPoolIds.push(pool.id);
    }

    bandLevel.accessiblePools = bandPoolIds;
    bandLevel.price = event.params.price;
    bandLevel.save();
}

export function handleSharesInMonthSet(event: SharesInMonthSetEvent): void {
    const stakingContract: StakingContract = getOrInitStakingContract();

    stakingContract.sharesInMonths = event.params.totalSharesInMonth;
    stakingContract.save();
}

export function handleUsdtTokenSet(event: UsdtTokenSetEvent): void {
    const stakingContract: StakingContract = getOrInitStakingContract();

    stakingContract.usdtToken = event.params.token;
    stakingContract.save();
}

export function handleUsdcTokenSet(event: UsdcTokenSetEvent): void {
    const stakingContract: StakingContract = getOrInitStakingContract();

    stakingContract.usdcToken = event.params.token;
    stakingContract.save();
}

export function handleWowTokenSet(event: WowTokenSetEvent): void {
    const stakingContract: StakingContract = getOrInitStakingContract();

    stakingContract.wowToken = event.params.token;
    stakingContract.save();
}

export function handleTotalBandLevelsAmountSet(event: TotalBandLevelsAmountSetEvent): void {
    const stakingContract: StakingContract = getOrInitStakingContract();

    stakingContract.totalBandLevels = event.params.newTotalBandsAmount;
    stakingContract.save();
}

export function handleTotalPoolAmountSet(event: TotalPoolAmountSetEvent): void {
    const stakingContract: StakingContract = getOrInitStakingContract();

    stakingContract.totalPools = event.params.newTotalPoolAmount;
    stakingContract.save();
}

export function handleBandUpgradeStatusSet(event: BandUpgradeStatusSetEvent): void {
    const stakingContract: StakingContract = getOrInitStakingContract();

    stakingContract.areUpgradesEnabled = event.params.enabled;
    stakingContract.save();
}

export function handleTokensWithdrawn(event: TokensWithdrawnEvent): void {
    // No data needs to be updated
}

export function handleDistributionCreated(event: DistributionCreatedEvent): void {
    const stakingContract: StakingContract = getOrInitStakingContract();
    const distributionId: BigInt = stakingContract.nextDistributionId;

    // Increase distribution id
    stakingContract.nextDistributionId = distributionId.plus(BIGINT_ONE);
    stakingContract.save();

    // Update shares for stakers and pools
    const sharesData: StakerAndPoolShares = updateSharesForPoolsAndStakers(stakingContract, event.block.timestamp);

    // Calculate rewards for stakers
    const stakerRewards: BigInt[] = calculateRewards(stakingContract, event.params.amount, sharesData);

    // Create new distribution data which will be used for rewards distribution by gelato
    const distribution: FundsDistribution = getOrInitFundsDistribution(distributionId);
    distribution.token = event.params.token;
    distribution.amount = event.params.amount;
    distribution.createdAt = event.block.timestamp;
    distribution.stakers = sharesData.stakers;
    distribution.rewards = stakerRewards;
    distribution.save();
}

export function handleRewardsDistributed(event: RewardsDistributedEvent): void {
    const stakingContract: StakingContract = getOrInitStakingContract();

    // Get last distribution id
    const distribution: FundsDistribution = getOrInitFundsDistribution(
        stakingContract.nextDistributionId.minus(BIGINT_ONE),
    );
    distribution.distributedAt = event.block.timestamp;
    distribution.save();

    const stakers: string[] = distribution.stakers;
    const stakersAmount: number = stakers.length;
    const distributionToken: Address = Address.fromBytes(distribution.token);

    // Loop through each staker and update their rewards for USDT/USDC tokens
    for (let i = 0; i < stakersAmount; i++) {
        const staker: Staker = getOrInitStaker(Address.fromString(stakers[i]));
        const rewardAmount: BigInt = distribution.rewards[i];
        const stakerAddress: Address = Address.fromString(staker.id);
        const stakerRewards: StakerRewards = getOrInitStakerRewards(stakerAddress, distributionToken);

        stakerRewards.unclaimedAmount = stakerRewards.unclaimedAmount.plus(rewardAmount);
        stakerRewards.save();
    }
}

// Gelato will call triggerSharesSync() function
// If more than 24 hours have passed since the last shares sync
export function handleSharesSyncTriggered(event: SharesSyncTriggeredEvent): void {
    syncAllSharesEvery12Hours(event.block.timestamp);
}

export function handleStaked(event: StakedEvent): void {
    const stakingContract: StakingContract = getOrInitStakingContract();
    const staker: Staker = getOrInitStaker(event.params.user);

    // If staker has no bands, it means staker is not added to all stakers array
    if (BigInt.fromI32(staker.bands.length).equals(BIGINT_ZERO)) {
        // Add staker to all stakers array
        const stakerIds = stakingContract.stakers;
        stakerIds.push(staker.id);
        stakingContract.stakers = stakerIds;
    }

    const bandLevel: BandLevel = getOrInitBandLevel(BigInt.fromI32(event.params.bandLevel));
    const band: Band = getOrInitBand(event.params.bandId);

    band.owner = staker.id;
    band.stakingStartDate = event.block.timestamp;
    band.bandLevel = bandLevel.id;
    band.stakingType = stringifyStakingType(event.params.stakingType);
    band.fixedMonths = event.params.fixedMonths;
    band.areTokensVested = event.params.areTokensVested;
    band.save();

    const totalStakedFromAllUsers = stakingContract.totalStakedFromAllUsers;
    stakingContract.nextBandId = stakingContract.nextBandId.plus(BIGINT_ONE);
    stakingContract.totalStakedFromAllUsers = totalStakedFromAllUsers.plus(bandLevel.price);
    stakingContract.save();

    // Update staker bands
    const stakerBandIds = staker.bands;
    stakerBandIds.push(band.id);
    staker.bands = stakerBandIds;

    // Update staker total staked
    const stakerTotalStaked = staker.totalStaked;
    staker.totalStaked = stakerTotalStaked.plus(bandLevel.price);
    staker.save();

    // Run full sync if 12 hours have passed since last sync
    // Else, update shares for the staker and the pools that changed
    updateSharesWhenStaked(
        staker,
        band,
        bandLevel,
        stakingContract.sharesInMonths,
        bandLevel.accessiblePools,
        event.block.timestamp,
    );
}

export function handleUnstaked(event: UnstakedEvent): void {
    const stakingContract: StakingContract = getOrInitStakingContract();
    const staker: Staker = getOrInitStaker(event.params.user);

    const band: Band = getOrInitBand(event.params.bandId);
    const bandShares: BigInt = band.sharesAmount;

    const bandLevel: BandLevel = getOrInitBandLevel(BigInt.fromString(band.bandLevel));

    const bandsAmount: number = staker.bands.length;
    for (let i = 0; i < bandsAmount; i++) {
        if (staker.bands[i] == band.id) {
            // Swap last element with the one to be removed
            // And then remove the last element
            const stakerBandIds: string[] = staker.bands;
            stakerBandIds[i] = stakerBandIds[stakerBandIds.length - 1];
            stakerBandIds.pop();
            staker.bands = stakerBandIds;
            staker.save();

            // Remove band
            store.remove("Band", band.id);
            break;
        }
    }

    const isStakerRemoved: boolean = BigInt.fromI32(staker.bands.length).equals(BIGINT_ZERO);
    if (isStakerRemoved) {
        const stakersAmount: number = stakingContract.stakers.length;

        // Remove staker from all stakers array and staker itself
        for (let i = 0; i < stakersAmount; i++) {
            if (stakingContract.stakers[i] == staker.id) {
                // Swap last element with the one to be removed
                // And then remove the last element
                const stakersIds: string[] = stakingContract.stakers;
                stakersIds[i] = stakersIds[stakersIds.length - 1];
                stakersIds.pop();
                stakingContract.stakers = stakersIds;
                stakingContract.save();

                // Remove staker
                store.remove("Staker", staker.id);
                break;
            }
        }
    }

    // Claim USDT and USDC rewards.
    // Unclaimed amount will be added to claimed amount
    // Unclaimed amount is reset to zero
    claimRewardsFromUnclaimedAmount(stakingContract, staker);

    // Run full sync if 12 hours have passed since last sync
    // Else, update shares for the staker and the pools that changed
    updateSharesWhenUnstaked(
        isStakerRemoved ? null : staker,
        bandShares,
        bandLevel.accessiblePools,
        event.block.timestamp,
    );
}

export function handleVestingUserDeleted(event: VestingUserDeletedEvent): void {
    const stakingContract: StakingContract = getOrInitStakingContract();
    const staker: Staker = getOrInitStaker(event.params.user);
    const stakerAddress: Address = Address.fromString(staker.id);

    const usdcToken: Address = Address.fromBytes(stakingContract.usdcToken);
    const usdcRewards: StakerRewards = getOrInitStakerRewards(stakerAddress, usdcToken);

    const usdtToken: Address = Address.fromBytes(stakingContract.usdtToken);
    const usdtRewards: StakerRewards = getOrInitStakerRewards(stakerAddress, usdtToken);

    const stakersAmount: number = stakingContract.stakers.length;
    for (let i = 0; i < stakersAmount; i++) {
        if (stakingContract.stakers[i] == staker.id) {
            // Swap last element with the one to be removed
            // And then remove the last element
            const stakersIds: string[] = stakingContract.stakers;
            stakersIds[i] = stakersIds[stakersIds.length - 1];
            stakersIds.pop();
            stakingContract.stakers = stakersIds;
            stakingContract.save();

            break;
        }
    }

    const stakerBands: string[] = staker.bands;
    const bandsAmount: number = stakerBands.length;

    // Remove bands
    for (let i = 0; i < bandsAmount; i++) {
        const band: Band = getOrInitBand(BigInt.fromString(staker.bands[i]));
        store.remove("Band", band.id);
    }

    // Remove staker and accumulated rewards
    store.remove("StakerRewards", usdtRewards.id);
    store.remove("StakerRewards", usdcRewards.id);
    store.remove("Staker", staker.id);
}

export function handleBandUpgraded(event: BandUpgradedEvent): void {
    // Sync shares if needed
    syncAllSharesEvery12Hours(event.block.timestamp);

    const band: Band = getOrInitBand(event.params.bandId);
    band.bandLevel = getOrInitBandLevel(BigInt.fromI32(event.params.newBandLevel)).id;
    band.save();
}

export function handleBandDowngraded(event: BandDowngradedEvent): void {
    // Sync shares if needed
    syncAllSharesEvery12Hours(event.block.timestamp);

    const band: Band = getOrInitBand(event.params.bandId);
    band.bandLevel = getOrInitBandLevel(BigInt.fromI32(event.params.newBandLevel)).id;
    band.save();
}

export function handleRewardsClaimed(event: RewardsClaimedEvent): void {
    // Sync shares if needed
    syncAllSharesEvery12Hours(event.block.timestamp);

    const staker: Staker = getOrInitStaker(event.params.user);
    const stakerAddress: Address = Address.fromString(staker.id);
    const rewardToken: Address = Address.fromBytes(event.params.token);

    const tokenRewards: StakerRewards = getOrInitStakerRewards(stakerAddress, rewardToken);
    tokenRewards.claimedAmount = event.params.totalRewards;
    tokenRewards.save();
}
