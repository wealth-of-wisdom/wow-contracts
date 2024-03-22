import { Address, BigInt, store, log } from "@graphprotocol/graph-ts";
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
    DistributionStatusSet as DistributionStatusSetEvent,
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
    addStakerToStakingContract,
    removeStakerFromStakingContract,
    addBandToStakerBands,
    removeBandFromStakerBands,
    removeAllBands,
    removeAllStakerRewards,
    changeBandLevel,
} from "../helpers/staking.helpers";
import { stakingTypeFIX, stringifyStakingType, StakerAndPoolShares } from "../utils/utils";
import { calculateRewards } from "../utils/staking/rewardsCalculation";
import {
    syncFlexiSharesEvery12Hours,
    calculateAllShares,
    addFixedShares,
    removeFixedShares,
    removeFlexiShares,
} from "../utils/staking/sharesSync";
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

export function handleDistributionStatusSetEvent(event: DistributionStatusSetEvent): void {
    const stakingContract: StakingContract = getOrInitStakingContract();

    stakingContract.isDistributionInProgress = event.params.inProgress;
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
    const sharesData: StakerAndPoolShares = calculateAllShares(stakingContract, event.block.timestamp);

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
        const rewards: BigInt = distribution.rewards[i];

        const stakerAddress: Address = Address.fromString(stakers[i]);
        const staker: Staker = getOrInitStaker(stakerAddress);
        staker.totalUnclaimedRewards = staker.totalUnclaimedRewards.plus(rewards);
        staker.save();

        const stakerRewards: StakerRewards = getOrInitStakerRewards(stakerAddress, distributionToken);
        stakerRewards.unclaimedAmount = stakerRewards.unclaimedAmount.plus(rewards);
        stakerRewards.save();
    }
}

// Gelato will call triggerSharesSync() function
// If more than 24 hours have passed since the last shares sync
export function handleSharesSyncTriggered(event: SharesSyncTriggeredEvent): void {
    syncFlexiSharesEvery12Hours(event.block.timestamp);
}

export function handleStaked(event: StakedEvent): void {
    // Sync shares if needed
    syncFlexiSharesEvery12Hours(event.block.timestamp);

    const stakingContract: StakingContract = getOrInitStakingContract();
    const staker: Staker = getOrInitStaker(event.params.user);

    const bandLevel: BandLevel = getOrInitBandLevel(BigInt.fromI32(event.params.bandLevel));
    const band: Band = getOrInitBand(event.params.bandId);

    band.owner = staker.id;
    band.stakingStartDate = event.block.timestamp;
    band.bandLevel = bandLevel.id;
    band.stakingType = stringifyStakingType(event.params.stakingType);
    band.fixedMonths = event.params.fixedMonths;
    band.areTokensVested = event.params.areTokensVested;
    band.save();

    // Update staking contract data
    addStakerToStakingContract(stakingContract, staker);
    stakingContract.nextBandId = stakingContract.nextBandId.plus(BIGINT_ONE);
    stakingContract.totalStakedAmount = stakingContract.totalStakedAmount.plus(bandLevel.price);
    stakingContract.save();

    // Update staker data
    addBandToStakerBands(staker, band);
    staker.bandsCount = staker.bandsCount + 1;
    staker.stakedAmount = staker.stakedAmount.plus(bandLevel.price);
    staker.save();

    // Recalculate fixed shares if band is with type FIX
    // We don't need to update flexi shares because they are updated every 12-24 hours
    // And the staker will have the same amount of shares as before because no months have passed
    addFixedShares(staker, band, stakingContract.sharesInMonths, bandLevel.accessiblePools);
}

export function handleUnstaked(event: UnstakedEvent): void {
    const staker: Staker = getOrInitStaker(event.params.user);
    const band: Band = getOrInitBand(event.params.bandId);
    const bandLevel: BandLevel = getOrInitBandLevel(BigInt.fromString(band.bandLevel));

    // Update total staked amount in the contract
    const stakingContract: StakingContract = getOrInitStakingContract();
    stakingContract.totalStakedAmount = stakingContract.totalStakedAmount.minus(bandLevel.price);
    stakingContract.save();

    const isStakerRemoved: boolean = staker.bandsCount == 1;

    // If only one band is staked, remove the band and staker
    if (isStakerRemoved) {
        removeStakerFromStakingContract(stakingContract, staker);
    }
    // Else remove the band and update staker data
    else {
        removeBandFromStakerBands(staker, band, bandLevel.price);
    }

    // Remove band
    store.remove("Band", band.id);

    // Run full sync if 12 hours have passed since last sync
    // Else, update shares for the staker, band and the pools that changed
    const syncExecuted: boolean = syncFlexiSharesEvery12Hours(event.block.timestamp);

    // If the removed band is with type FIX, remove the fixed shares
    if (band.stakingType == stakingTypeFIX) {
        removeFixedShares(isStakerRemoved ? null : staker, band, bandLevel.accessiblePools);
    }
    // Else if type is FLEXI and sync was not executed, update shares
    else if (!syncExecuted) {
        removeFlexiShares(staker, band, bandLevel.accessiblePools);
    }
}

export function handleVestingUserDeleted(event: VestingUserDeletedEvent): void {
    const stakingContract: StakingContract = getOrInitStakingContract();
    const staker: Staker = getOrInitStaker(event.params.user);

    // Remove staker from the contract
    removeStakerFromStakingContract(stakingContract, staker);

    removeAllBands(staker);

    removeAllStakerRewards(stakingContract, staker);
}

export function handleBandUpgraded(event: BandUpgradedEvent): void {
    // Sync shares if needed
    syncFlexiSharesEvery12Hours(event.block.timestamp);

    changeBandLevel(event.params.user, event.params.bandId, event.params.oldBandLevel, event.params.newBandLevel);
}

export function handleBandDowngraded(event: BandDowngradedEvent): void {
    // Sync shares if needed
    syncFlexiSharesEvery12Hours(event.block.timestamp);

    changeBandLevel(event.params.user, event.params.bandId, event.params.oldBandLevel, event.params.newBandLevel);
}

export function handleRewardsClaimed(event: RewardsClaimedEvent): void {
    const rewards = event.params.totalRewards;

    // Update staker rewards data
    const stakerAddress: Address = event.params.user;
    const staker: Staker = getOrInitStaker(stakerAddress);
    staker.totalUnclaimedRewards = staker.totalUnclaimedRewards.minus(rewards);
    staker.totalClaimedRewards = staker.totalClaimedRewards.plus(rewards);
    staker.save();

    // Update single token rewards data
    const rewardToken: Address = Address.fromBytes(event.params.token);
    const tokenRewards: StakerRewards = getOrInitStakerRewards(stakerAddress, rewardToken);
    tokenRewards.unclaimedAmount = BIGINT_ZERO;
    tokenRewards.claimedAmount = tokenRewards.claimedAmount.plus(rewards);
    tokenRewards.save();
}
