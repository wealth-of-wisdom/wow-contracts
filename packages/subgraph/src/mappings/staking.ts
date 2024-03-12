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
    Staked as StakedEvent,
    Unstaked as UnstakedEvent,
    VestingUserDeleted as VestingUserDeletedEvent,
    BandDowngraded as BandDowngradedEvent,
    BandUpgraded as BandUpgradedEvent,
    RewardsClaimed as RewardsClaimedEvent,
    Staking,
} from "../../generated/Staking/Staking";
import { StakingContract, Pool, Band, FundsDistribution } from "../../generated/schema";
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
import { calculateRewards, StakersAndRewards } from "../utils/rewardsCalculation";
import { BIGINT_ZERO, BIGINT_ONE, StakingType } from "../utils/constants";

export function handleInitialized(event: InitializedEvent): void {
    const stakingContract = getOrInitStakingContract();

    const staking = Staking.bind(event.address);
    stakingContract.stakingContractAddress = event.address;
    stakingContract.usdtToken = staking.getTokenUSDT();
    stakingContract.usdcToken = staking.getTokenUSDC();
    stakingContract.wowToken = staking.getTokenWOW();
    stakingContract.percentagePrecision = staking.PERCENTAGE_PRECISION().toI32();
    stakingContract.totalPools = staking.getTotalPools();
    stakingContract.totalBandLevels = staking.getTotalBandLevels();
    stakingContract.save();
}

export function handlePoolSet(event: PoolSetEvent): void {
    const pool = getOrInitPool(BigInt.fromI32(event.params.poolId));

    pool.distributionPercentage = event.params.distributionPercentage.toI32();
    pool.save();
}

export function handleBandLevelSet(event: BandLevelSetEvent): void {
    const bandLevel = getOrInitBandLevel(BigInt.fromI32(event.params.bandLevel));

    const poolsAmount = event.params.accessiblePools.length;
    for (let i = 0; i < poolsAmount; i++) {
        const pool = getOrInitPool(BigInt.fromI32(event.params.accessiblePools[i]));
        let bandPoolIds = bandLevel.accessiblePools;
        bandPoolIds.push(pool.id);
        bandLevel.accessiblePools = bandPoolIds;
    }

    bandLevel.price = event.params.price;
    bandLevel.save();
}

export function handleSharesInMonthSet(event: SharesInMonthSetEvent): void {
    const stakingContract = getOrInitStakingContract();

    stakingContract.sharesInMonths = event.params.totalSharesInMonth;
    stakingContract.save();
}

export function handleUsdtTokenSet(event: UsdtTokenSetEvent): void {
    const stakingContract = getOrInitStakingContract();

    stakingContract.usdtToken = event.params.token;
    stakingContract.save();
}

export function handleUsdcTokenSet(event: UsdcTokenSetEvent): void {
    const stakingContract = getOrInitStakingContract();

    stakingContract.usdcToken = event.params.token;
    stakingContract.save();
}

export function handleWowTokenSet(event: WowTokenSetEvent): void {
    const stakingContract = getOrInitStakingContract();

    stakingContract.wowToken = event.params.token;
    stakingContract.save();
}

export function handleTotalBandLevelsAmountSet(event: TotalBandLevelsAmountSetEvent): void {
    const stakingContract = getOrInitStakingContract();

    stakingContract.totalBandLevels = event.params.newTotalBandsAmount;
    stakingContract.save();
}

export function handleTotalPoolAmountSet(event: TotalPoolAmountSetEvent): void {
    const stakingContract = getOrInitStakingContract();

    stakingContract.totalPools = event.params.newTotalPoolAmount;
    stakingContract.save();
}

export function handleBandUpgradeStatusSet(event: BandUpgradeStatusSetEvent): void {
    const stakingContract = getOrInitStakingContract();

    stakingContract.areUpgradesEnabled = event.params.enabled;
    stakingContract.save();
}

export function handleTokensWithdrawn(event: TokensWithdrawnEvent): void {
    // No state is changed in contracts
}

export function handleDistributionCreated(event: DistributionCreatedEvent): void {
    const stakingContract = getOrInitStakingContract();
    const distributionId = stakingContract.nextDistributionId;

    stakingContract.nextDistributionId = distributionId.plus(BIGINT_ONE);
    stakingContract.save();

    const distribution = getOrInitFundsDistribution(distributionId);

    const stakersAndRewards: StakersAndRewards = calculateRewards(
        stakingContract,
        event.params.amount,
        event.block.timestamp,
    );

    distribution.token = event.params.token;
    distribution.amount = event.params.amount;
    distribution.createdAt = event.block.timestamp;
    distribution.stakers = stakersAndRewards.stakers;
    distribution.rewards = stakersAndRewards.rewards;
    distribution.save();
}

export function handleRewardsDistributed(event: RewardsDistributedEvent): void {
    const stakingContract = getOrInitStakingContract();
    const staking = Staking.bind(Address.fromBytes(stakingContract.stakingContractAddress));

    // Get last distribution id
    const distribution = getOrInitFundsDistribution(stakingContract.nextDistributionId.minus(BIGINT_ONE));
    distribution.distributedAt = event.block.timestamp;
    distribution.save();

    const stakers = stakingContract.stakers;
    const stakersAmount = stakers.length;
    const usdtToken = Address.fromBytes(stakingContract.usdtToken);
    const usdcToken = Address.fromBytes(stakingContract.usdcToken);

    // Loop through each staker and update their rewards for USDT/USDC tokens
    for (let i = 0; i < stakersAmount; i++) {
        const staker = getOrInitStaker(Address.fromString(stakers[i]));
        const stakerAddress = Address.fromString(staker.id);
        const usdtRewards = getOrInitStakerRewards(stakerAddress, usdtToken);
        const usdcRewards = getOrInitStakerRewards(stakerAddress, usdcToken);

        usdtRewards.unclaimedAmount = staking.getStakerReward(stakerAddress, usdtToken).getUnclaimedAmount();
        usdtRewards.save();

        usdcRewards.unclaimedAmount = staking.getStakerReward(stakerAddress, usdcToken).getUnclaimedAmount();
        usdcRewards.save();
    }
}

export function handleStaked(event: StakedEvent): void {
    const stakingContract = getOrInitStakingContract();
    const staker = getOrInitStaker(event.params.user);
    const band: Band = getOrInitBand(event.params.bandId);

    const nextBandId = stakingContract.nextBandId;

    stakingContract.nextBandId = nextBandId.plus(BIGINT_ONE);
    if (BigInt.fromI32(staker.bands.length).equals(BIGINT_ZERO)) {
        let stakerIds = stakingContract.stakers;
        stakerIds.push(staker.id);
        stakingContract.stakers = stakerIds;
    }
    stakingContract.save();

    band.owner = staker.id;
    band.stakingStartDate = event.block.timestamp;
    band.bandLevel = getOrInitBandLevel(BigInt.fromI32(event.params.bandLevel)).id;
    band.stakingType = stringifyStakingType(event.params.stakingType);
    if (event.params.stakingType == StakingType.FIX) band.fixedMonths = event.params.fixedMonths;
    if (event.params.areTokensVested) band.areTokensVested = event.params.areTokensVested;

    band.save();

    let stakerBandIds = staker.bands;
    stakerBandIds.push(band.id);
    staker.bands = stakerBandIds;
    staker.save();
}

export function handleUnstaked(event: UnstakedEvent): void {
    const stakingContract = getOrInitStakingContract();
    const staking = Staking.bind(Address.fromBytes(stakingContract.stakingContractAddress));
    const usdtToken = Address.fromBytes(stakingContract.usdtToken);
    const usdcToken = Address.fromBytes(stakingContract.usdcToken);

    const staker = getOrInitStaker(event.params.user);
    const band: Band = getOrInitBand(event.params.bandId);

    const stakerAddress = Address.fromString(staker.id);
    const usdtRewards = getOrInitStakerRewards(stakerAddress, usdtToken);
    const usdcRewards = getOrInitStakerRewards(stakerAddress, usdcToken);

    const bandsAmount = staker.bands.length;
    for (let i = 0; i < bandsAmount; i++) {
        if (staker.bands[i] == band.id) {
            let stakerBandIds = staker.bands;
            stakerBandIds[i] = stakerBandIds[stakerBandIds.length - 1];
            stakerBandIds.pop();
            staker.bands = stakerBandIds;
            staker.save();
            store.remove("Band", band.id);
            break;
        }
    }

    if (BigInt.fromI32(staker.bands.length).equals(BIGINT_ZERO)) {
        const stakersAmount = stakingContract.stakers.length;
        for (let i = 0; i < stakersAmount; i++) {
            if (stakingContract.stakers[i] == staker.id) {
                let stakersIds = stakingContract.stakers;
                stakersIds[i] = stakersIds[stakersIds.length - 1];
                stakersIds.pop();
                stakingContract.stakers = stakersIds;
                stakingContract.save();
                store.remove("Staker", staker.id);
                break;
            }
        }
    }

    usdtRewards.claimedAmount = staking.getStakerReward(stakerAddress, usdtToken).getClaimedAmount();
    usdtRewards.save();
    usdcRewards.claimedAmount = staking.getStakerReward(stakerAddress, usdcToken).getClaimedAmount();
    usdcRewards.save();
}

export function handleVestingUserDeleted(event: VestingUserDeletedEvent): void {
    const stakingContract = getOrInitStakingContract();
    const usdtToken = Address.fromBytes(stakingContract.usdtToken);
    const usdcToken = Address.fromBytes(stakingContract.usdcToken);

    const staker = getOrInitStaker(event.params.user);

    const stakerAddress = Address.fromString(staker.id);
    const usdtRewards = getOrInitStakerRewards(stakerAddress, usdtToken);
    const usdcRewards = getOrInitStakerRewards(stakerAddress, usdcToken);

    const stakersAmount = stakingContract.stakers.length;
    for (let i = 0; i < stakersAmount; i++) {
        if (stakingContract.stakers[i] == staker.id) {
            let stakersIds = stakingContract.stakers;
            stakersIds[i] = stakersIds[stakersIds.length - 1];
            stakersIds.pop();
            stakingContract.stakers = stakersIds;
            stakingContract.save();
            break;
        }
    }

    const stakerBands = staker.bands;
    const bandsAmount = stakerBands.length;
    for (let i = 0; i < bandsAmount; i++) {
        const band: Band = getOrInitBand(BigInt.fromString(staker.bands[i]));
        store.remove("Band", band.id);
    }
    store.remove("StakerRewards", usdtRewards.id);
    store.remove("StakerRewards", usdcRewards.id);
    store.remove("Staker", staker.id);
}

export function handleBandUpgraded(event: BandUpgradedEvent): void {
    const band: Band = getOrInitBand(event.params.bandId);

    band.bandLevel = getOrInitBandLevel(BigInt.fromI32(event.params.newBandLevel)).id;
    band.save();
}

export function handleBandDowngraded(event: BandDowngradedEvent): void {
    const band: Band = getOrInitBand(event.params.bandId);

    band.bandLevel = getOrInitBandLevel(BigInt.fromI32(event.params.newBandLevel)).id;
    band.save();
}

export function handleRewardsClaimed(event: RewardsClaimedEvent): void {
    const stakingContract = getOrInitStakingContract();
    const staking = Staking.bind(Address.fromBytes(stakingContract.stakingContractAddress));
    const rewardToken = Address.fromBytes(event.params.token);

    const staker = getOrInitStaker(event.params.user);

    const stakerAddress = Address.fromString(staker.id);
    const tokenRewards = getOrInitStakerRewards(stakerAddress, rewardToken);

    tokenRewards.claimedAmount = event.params.totalRewards;
    tokenRewards.save();
}
