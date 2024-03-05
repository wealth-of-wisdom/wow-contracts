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
    // UpgradesTriggerSet as UpgradesTriggerSetEvent,
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
        bandLevel.accessiblePools.push(pool.id);
    }

    bandLevel.price = event.params.price;
    bandLevel.save();
}

export function handleSharesInMonths(event: SharesInMonthSetEvent): void {
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

// export function handleUpgradesTriggerSet(event: UpgradesTriggerSetEvent): void {
//     const stakingContract = getOrInitStakingContract();

//     stakingContract.areUpgradesEnabled = event.params.triggerStatus;
//     stakingContract.save();
// }

export function handleTokensWithdrawn(event: TokensWithdrawnEvent): void {
    // No state is changed in contracts
}

export function handleDistributionCreated(event: DistributionCreatedEvent): void {
    const stakingContract = getOrInitStakingContract();
    const distributionId = stakingContract.nextDistributionId;

    stakingContract.nextDistributionId = distributionId.plus(BIGINT_ONE);
    stakingContract.save();

    const distribution = getOrInitFundsDistribution(distributionId);

    distribution.token = event.params.token;
    distribution.amount = event.params.amount;
    distribution.createdAt = event.block.timestamp;
    distribution.save();

    // @todo add full gelato function logic which calculates the rewards for all users
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
    const nextBandId = stakingContract.nextBandId;
    const band: Band = getOrInitBand(event.params.bandId);

    staker.bands.push(band.id);
    staker.save();

    stakingContract.nextBandId = nextBandId.plus(BIGINT_ONE);
    if (staker.bands.length == 1) stakingContract.stakers.push(staker.id);
    stakingContract.save();

    band.owner = event.params.user;
    band.stakingStartDate = event.block.timestamp;
    band.bandLevel = event.params.bandLevel;
    band.stakingType = event.params.stakingType.toString();
    if (event.params.stakingType == StakingType.FIX) band.fixedMonths = event.params.fixedMonths;
    band.areTokensVested = event.params.areTokensVested;
    band.save();
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

    for (let i = 0; i < staker.bands.length; i++) {
        if (staker.bands[i] === band.id) {
            staker.bands[i] = staker.bands[i - 1];
            staker.bands.pop();
        }
    }
    if (staker.bands.length == 0) {
        for (let i = 0; i < stakingContract.stakers.length; i++) {
            if (stakingContract.stakers[i] === staker.id) {
                stakingContract.stakers[i] = stakingContract.stakers[i - 1];
                stakingContract.stakers.pop();
            }
        }
        store.remove("Staker", staker.id);
    }
    store.remove("Band", band.id);

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

    for (let i = 0; i < stakingContract.stakers.length; i++) {
        if (stakingContract.stakers[i] === staker.id) {
            stakingContract.stakers[i] = stakingContract.stakers[i - 1];
            stakingContract.stakers.pop();
        }
    }

    for (let i = 0; i < staker.bands.length; i++) {
        const band: Band = getOrInitBand(BigInt.fromString(staker.bands[i]));
        store.remove("Band", band.id);
    }
    store.remove("StakerRewards", usdtRewards.id);
    store.remove("StakerRewards", usdcRewards.id);
    store.remove("Staker", event.params.user.toString());
}

export function handleBandUpgraded(event: BandUpgradedEvent): void {
    const band: Band = getOrInitBand(event.params.bandId);

    band.bandLevel = event.params.newBandLevel;
    band.save();
}

export function handleBandDowngraded(event: BandDowngradedEvent): void {
    const band: Band = getOrInitBand(event.params.bandId);

    band.bandLevel = event.params.newBandLevel;
    band.save();
}

export function handleRewardsClaimed(event: RewardsClaimedEvent): void {
    const stakingContract = getOrInitStakingContract();
    const staking = Staking.bind(Address.fromBytes(stakingContract.stakingContractAddress));
    const rewardToken = Address.fromBytes(event.params.token);

    const staker = getOrInitStaker(event.params.user);

    const stakerAddress = Address.fromString(staker.id);
    const tokenRewards = getOrInitStakerRewards(stakerAddress, rewardToken);

    tokenRewards.claimedAmount = staking.getStakerReward(stakerAddress, rewardToken).getClaimedAmount();
    tokenRewards.save();
}

// @note The following commented out functions are old and should only be used as reference

// // Band add
// export function handleBandStaked(event: BandStakedEvent): void {
//     const band: Band = getOrInitBand(event.params.bandId);

//     // band.stakingType = event.params
//     band.bandLevel = event.params.bandLevel;
//     band.owner = event.params.user;
//     // @todo get from getter function
//     // band.price = event.params.price;
//     band.startingSharesAmount = BIGINT_ZERO;
//     band.stakingStartTimestamp = event.block.timestamp;
//     band.claimableRewardsAmount = BIGINT_ZERO;
//     band.usdcRewardsClaimed = BIGINT_ZERO;
//     band.usdcRewardsClaimed = BIGINT_ZERO;

//     band.save();
// }
// // Band remove
// export function handleBandUnstaked(event: BandUnstakedEvent): void {
//     const band: Band = getOrInitBand(event.params.bandId);

//     store.remove("Band", band.id);

//     band.save();
// }

// export function handleFundsDistributed(event: FundsDistributedEvent): void {
//     const fundsDistribution = getOrInitFundDistribution(event.transaction.hash);

//     fundsDistribution.amount = event.params.amount;
//     fundsDistribution.timestamp = event.block.timestamp;
//     fundsDistribution.token = event.params.token;

//     fundsDistribution.save();
// }

// export function handleRewardsClaimed(event: RewardsClaimedEvent): void {
//     // @todo This event should also emit band ID, to track claimed rewards from band
//     const band = getOrInitBand(event.params.bandId);

//     // @todo add this to constants file
//     const usdtAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
//     const usdcAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";

//     if (event.params.token.toString() === usdtAddress) {
//         band.usdtRewardsClaimed = event.params.totalRewards;
//     } else if (event.params.token.toString() === usdcAddress) {
//         band.usdcRewardsClaimed = event.params.totalRewards;
//     }

//     band.save();
// }

// // @note What is the difference between StakedEvent and handleBandStaked???
// export function handleStaked(event: StakedEvent): void {
//     // @todo This event should also emit band ID, to track staked band
//     const band = getOrInitBand(event.params.bandId);

//     band.bandLevel = event.params.bandLevel;
//     band.stakingType = event.params.stakingType;
//     band.owner = event.params.user;

//     band.save();
// }
