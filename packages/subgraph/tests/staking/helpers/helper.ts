import { BigInt, Address } from "@graphprotocol/graph-ts";
import {
    handleInitialized,
    handlePoolSet,
    handleBandLevelSet,
    handleSharesInMonthSet,
    handleUsdtTokenSet,
    handleUsdcTokenSet,
    handleWowTokenSet,
    handleTotalBandLevelsAmountSet,
    handleTotalPoolAmountSet,
    handleBandUpgradeStatusSet,
    handleDistributionStatusSetEvent,
    handleTokensWithdrawn,
    handleDistributionCreated,
    handleRewardsDistributed,
    handleSharesSyncTriggered,
    handleStaked,
    handleUnstaked,
    handleVestingUserDeleted,
    handleBandUpgraded,
    handleBandDowngraded,
    handleRewardsClaimed,
} from "../../../src/mappings/staking";
import {
    createInitializedEvent,
    createPoolSetEvent,
    createBandLevelSetEvent,
    createSharesInMonthSetEvent,
    createUsdtTokenSetEvent,
    createUsdcTokenSetEvent,
    createWowTokenSetEvent,
    createTotalBandLevelsAmountSetEvent,
    createTotalPoolAmountSetEvent,
    createBandUpgradeStatusSetEvent,
    createDistributionStatusSetEvent,
    createTokensWithdrawnEvent,
    createDistributionCreatedEvent,
    createRewardsDistributedEvent,
    createSharesSyncTriggeredEvent,
    createStakedEvent,
    createUnstakedEvent,
    createVestingUserDeletedEvent,
    createBandUpgradedEvent,
    createBandDowngradedEvent,
    createRewardsClaimedEvent,
} from "../helpers/createEvents";
import { BIGINT_ZERO, StakingType } from "../../../src/utils/constants";

export function initialize(): void {
    handleInitialized(createInitializedEvent());
}

export function setPool(poolId: BigInt, distributionPercentage: BigInt): void {
    handlePoolSet(createPoolSetEvent(poolId, distributionPercentage));
}

export function setBandLevel(bandLevel: BigInt, price: BigInt, pools: BigInt[]): void {
    handleBandLevelSet(createBandLevelSetEvent(bandLevel, price, pools));
}

export function setSharesInMonth(totalSharesInMonths: BigInt[]): void {
    handleSharesInMonthSet(createSharesInMonthSetEvent(totalSharesInMonths));
}

export function setUsdtTokenAddress(token: Address): void {
    handleUsdtTokenSet(createUsdtTokenSetEvent(token));
}

export function setUsdcTokenAddress(token: Address): void {
    handleUsdcTokenSet(createUsdcTokenSetEvent(token));
}

export function setWowTokenAddress(token: Address): void {
    handleWowTokenSet(createWowTokenSetEvent(token));
}

export function setTotalBandLevels(amount: BigInt): void {
    handleTotalBandLevelsAmountSet(createTotalBandLevelsAmountSetEvent(amount));
}

export function setTotalPools(amount: BigInt): void {
    handleTotalPoolAmountSet(createTotalPoolAmountSetEvent(amount));
}

export function setBandUpgradesEnabled(status: boolean): void {
    handleBandUpgradeStatusSet(createBandUpgradeStatusSetEvent(status));
}

export function setDistributionInProgress(status: boolean): void {
    handleDistributionStatusSetEvent(createDistributionStatusSetEvent(status));
}

export function withdrawTokens(token: Address, receiver: Address, amount: BigInt): void {
    handleTokensWithdrawn(createTokensWithdrawnEvent(token, receiver, amount));
}

export function createDistribution(token: Address, amount: BigInt): void {
    handleDistributionCreated(createDistributionCreatedEvent(token, amount));
}

export function distributeRewards(token: Address): void {
    handleRewardsDistributed(createRewardsDistributedEvent(token));
}

export function triggerSharesSync(): void {
    handleSharesSyncTriggered(createSharesSyncTriggeredEvent());
}

export function stake(
    staker: Address,
    bandLevel: BigInt,
    bandId: BigInt,
    fixedMonths: BigInt,
    stakingType: StakingType,
    areTokensVested: boolean,
): void {
    handleStaked(createStakedEvent(staker, bandLevel, bandId, fixedMonths, stakingType, areTokensVested));
}

export function stakeStandardFlexi(staker: Address, bandLevel: BigInt, bandId: BigInt): void {
    stake(staker, bandLevel, bandId, BIGINT_ZERO, StakingType.FLEXI, false);
}

export function stakeStandardFixed(staker: Address, bandLevel: BigInt, bandId: BigInt, fixedMonths: BigInt): void {
    stake(staker, bandLevel, bandId, fixedMonths, StakingType.FIX, false);
}

export function stakeVestedFlexi(staker: Address, bandLevel: BigInt, bandId: BigInt): void {
    stake(staker, bandLevel, bandId, BIGINT_ZERO, StakingType.FLEXI, true);
}

export function stakeVestedFixed(staker: Address, bandLevel: BigInt, bandId: BigInt, fixedMonths: BigInt): void {
    stake(staker, bandLevel, bandId, fixedMonths, StakingType.FIX, true);
}

export function unstake(staker: Address, bandId: BigInt, areTokensVested: boolean): void {
    handleUnstaked(createUnstakedEvent(staker, bandId, areTokensVested));
}

export function unstakeStandard(staker: Address, bandId: BigInt): void {
    unstake(staker, bandId, false);
}

export function unstakeVested(staker: Address, bandId: BigInt): void {
    unstake(staker, bandId, true);
}

export function deleteVestingUser(staker: Address): void {
    handleVestingUserDeleted(createVestingUserDeletedEvent(staker));
}

export function upgradeBand(staker: Address, bandId: BigInt, oldBandLevel: BigInt, newBandLevel: BigInt): void {
    handleBandUpgraded(createBandUpgradedEvent(staker, bandId, oldBandLevel, newBandLevel));
}

export function downgradeBand(staker: Address, bandId: BigInt, oldBandLevel: BigInt, newBandLevel: BigInt): void {
    handleBandDowngraded(createBandDowngradedEvent(staker, bandId, oldBandLevel, newBandLevel));
}

export function claimRewards(staker: Address, token: Address, amount: BigInt): void {
    handleRewardsClaimed(createRewardsClaimedEvent(staker, token, amount));
}
