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
    handleDistributionStatusSet,
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
import { totalPools, totalBandLevels } from "../../utils/data/constants";
import {
    poolDistributionPercentages,
    bandLevelPrices,
    bandLevelAccessiblePools,
    sharesInMonths,
} from "../../utils/data/data";

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

export function initializeAndSetUp(): void {
    initialize();

    for (let i = 0; i < totalPools.toI32(); i++) {
        const poolId: BigInt = BigInt.fromI32(i + 1);
        setPool(poolId, poolDistributionPercentages[i]);
    }

    for (let i = 0; i < totalBandLevels.toI32(); i++) {
        const bandLevel: BigInt = BigInt.fromI32(i + 1);
        setBandLevel(bandLevel, bandLevelPrices[i], bandLevelAccessiblePools[i]);
    }

    setSharesInMonth(sharesInMonths);
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
    handleDistributionStatusSet(createDistributionStatusSetEvent(status));
}

export function withdrawTokens(token: Address, receiver: Address, amount: BigInt): void {
    handleTokensWithdrawn(createTokensWithdrawnEvent(token, receiver, amount));
}

export function createDistribution(token: Address, amount: BigInt, date: BigInt): void {
    handleDistributionCreated(createDistributionCreatedEvent(token, amount, date));
}

export function distributeRewards(token: Address, date: BigInt): void {
    handleRewardsDistributed(createRewardsDistributedEvent(token, date));
}

export function triggerSharesSync(date: BigInt): void {
    handleSharesSyncTriggered(createSharesSyncTriggeredEvent(date));
}

export function stake(
    staker: Address,
    bandLevel: BigInt,
    bandId: BigInt,
    fixedMonths: BigInt,
    stakingType: StakingType,
    areTokensVested: boolean,
    date: BigInt,
): void {
    handleStaked(createStakedEvent(staker, bandLevel, bandId, fixedMonths, stakingType, areTokensVested, date));
}

export function stakeStandardFlexi(staker: Address, bandLevel: BigInt, bandId: BigInt, date: BigInt): void {
    stake(staker, bandLevel, bandId, BIGINT_ZERO, StakingType.FLEXI, false, date);
}

export function stakeStandardFixed(
    staker: Address,
    bandLevel: BigInt,
    bandId: BigInt,
    fixedMonths: BigInt,
    date: BigInt,
): void {
    stake(staker, bandLevel, bandId, fixedMonths, StakingType.FIX, false, date);
}

export function stakeVestedFlexi(staker: Address, bandLevel: BigInt, bandId: BigInt, date: BigInt): void {
    stake(staker, bandLevel, bandId, BIGINT_ZERO, StakingType.FLEXI, true, date);
}

export function stakeVestedFixed(
    staker: Address,
    bandLevel: BigInt,
    bandId: BigInt,
    fixedMonths: BigInt,
    date: BigInt,
): void {
    stake(staker, bandLevel, bandId, fixedMonths, StakingType.FIX, true, date);
}

export function unstake(staker: Address, bandId: BigInt, areTokensVested: boolean, date: BigInt): void {
    handleUnstaked(createUnstakedEvent(staker, bandId, areTokensVested, date));
}

export function unstakeStandard(staker: Address, bandId: BigInt, date: BigInt): void {
    unstake(staker, bandId, false, date);
}

export function unstakeVested(staker: Address, bandId: BigInt, date: BigInt): void {
    unstake(staker, bandId, true, date);
}

export function deleteVestingUser(staker: Address): void {
    handleVestingUserDeleted(createVestingUserDeletedEvent(staker));
}

export function upgradeBand(
    staker: Address,
    bandId: BigInt,
    oldBandLevel: BigInt,
    newBandLevel: BigInt,
    date: BigInt,
): void {
    handleBandUpgraded(createBandUpgradedEvent(staker, bandId, oldBandLevel, newBandLevel, date));
}

export function downgradeBand(
    staker: Address,
    bandId: BigInt,
    oldBandLevel: BigInt,
    newBandLevel: BigInt,
    date: BigInt,
): void {
    handleBandDowngraded(createBandDowngradedEvent(staker, bandId, oldBandLevel, newBandLevel, date));
}

export function claimRewards(staker: Address, token: Address, amount: BigInt, date: BigInt): void {
    handleRewardsClaimed(createRewardsClaimedEvent(staker, token, amount, date));
}
