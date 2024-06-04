import { BigInt, Address, ethereum } from "@graphprotocol/graph-ts";
import { newMockEvent } from "matchstick-as";
import {
    InitializedContractData as InitializedContractDataEvent,
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
} from "../../../generated/Staking/Staking";
import { BIGINT_ZERO } from "../../../src/utils/constants";
import { StakingType } from "../../../src/utils/enums";
import {
    stakingAddress,
    usdtToken,
    usdcToken,
    wowToken,
    totalPools,
    totalBandLevels,
} from "../../utils/data/constants";
import { initDate } from "../../utils/data/dates";
import { createMockedFunctions } from "./createMockedFunctions";

export function createInitializedEvent(): InitializedContractDataEvent {
    createMockedFunctions();

    // @ts-ignore
    const newEvent = changetype<InitializedContractDataEvent>(newMockEvent());

    const usdtTokenParam = new ethereum.EventParam("usdtToken", ethereum.Value.fromAddress(usdtToken));
    const usdcTokenParam = new ethereum.EventParam("usdcToken", ethereum.Value.fromAddress(usdcToken));
    const wowTokenParam = new ethereum.EventParam("wowToken", ethereum.Value.fromAddress(wowToken));
    const totalPoolsParam = new ethereum.EventParam("totalPools", ethereum.Value.fromUnsignedBigInt(totalPools));
    const totalBandLevelsParam = new ethereum.EventParam(
        "totalBandLevels",
        ethereum.Value.fromUnsignedBigInt(totalBandLevels),
    );

    newEvent.address = stakingAddress;
    newEvent.block.timestamp = initDate;

    newEvent.parameters = new Array();
    newEvent.parameters.push(usdtTokenParam);
    newEvent.parameters.push(usdcTokenParam);
    newEvent.parameters.push(wowTokenParam);
    newEvent.parameters.push(totalPoolsParam);
    newEvent.parameters.push(totalBandLevelsParam);

    return newEvent;
}

export function createPoolSetEvent(poolId: BigInt, distributionPercentage: BigInt): PoolSetEvent {
    // @ts-ignore
    const newEvent = changetype<PoolSetEvent>(newMockEvent());

    const poolIdParam = new ethereum.EventParam("poolId", ethereum.Value.fromUnsignedBigInt(poolId));
    const percentageParam = new ethereum.EventParam(
        "distributionPercentage",
        ethereum.Value.fromUnsignedBigInt(distributionPercentage),
    );

    newEvent.parameters = new Array();
    newEvent.parameters.push(poolIdParam);
    newEvent.parameters.push(percentageParam);

    return newEvent;
}

export function createBandLevelSetEvent(bandLevel: BigInt, price: BigInt, pools: BigInt[]): BandLevelSetEvent {
    // @ts-ignore
    const newEvent = changetype<BandLevelSetEvent>(newMockEvent());

    const bandLevelParam = new ethereum.EventParam("bandLevel", ethereum.Value.fromUnsignedBigInt(bandLevel));
    const priceParam = new ethereum.EventParam("price", ethereum.Value.fromUnsignedBigInt(price));
    const poolsParam = new ethereum.EventParam("accessiblePools", ethereum.Value.fromUnsignedBigIntArray(pools));

    newEvent.parameters = new Array();
    newEvent.parameters.push(bandLevelParam);
    newEvent.parameters.push(priceParam);
    newEvent.parameters.push(poolsParam);

    return newEvent;
}

export function createSharesInMonthSetEvent(totalSharesInMonths: BigInt[]): SharesInMonthSetEvent {
    // @ts-ignore
    const newEvent = changetype<SharesInMonthSetEvent>(newMockEvent());

    const sharesParam = new ethereum.EventParam(
        "totalSharesInMonth",
        ethereum.Value.fromUnsignedBigIntArray(totalSharesInMonths),
    );

    newEvent.parameters = new Array();
    newEvent.parameters.push(sharesParam);

    return newEvent;
}

export function createUsdtTokenSetEvent(usdtTokenAddress: Address): UsdtTokenSetEvent {
    // @ts-ignore
    const newEvent = changetype<UsdtTokenSetEvent>(newMockEvent());

    const addressParam = new ethereum.EventParam("token", ethereum.Value.fromAddress(usdtTokenAddress));

    newEvent.parameters = new Array();
    newEvent.parameters.push(addressParam);

    return newEvent;
}

export function createUsdcTokenSetEvent(usdcTokenAddress: Address): UsdcTokenSetEvent {
    // @ts-ignore
    const newEvent = changetype<UsdcTokenSetEvent>(newMockEvent());

    const addressParam = new ethereum.EventParam("token", ethereum.Value.fromAddress(usdcTokenAddress));

    newEvent.parameters = new Array();
    newEvent.parameters.push(addressParam);

    return newEvent;
}

export function createWowTokenSetEvent(wowTokenAddress: Address): WowTokenSetEvent {
    // @ts-ignore
    const newEvent = changetype<WowTokenSetEvent>(newMockEvent());

    const addressParam = new ethereum.EventParam("token", ethereum.Value.fromAddress(wowTokenAddress));

    newEvent.parameters = new Array();
    newEvent.parameters.push(addressParam);

    return newEvent;
}

export function createTotalBandLevelsAmountSetEvent(totalBandLevels: BigInt): TotalBandLevelsAmountSetEvent {
    // @ts-ignore
    const newEvent = changetype<TotalBandLevelsAmountSetEvent>(newMockEvent());

    const totalBandLevelsParam = new ethereum.EventParam(
        "newTotalBandsAmount",
        ethereum.Value.fromUnsignedBigInt(totalBandLevels),
    );

    newEvent.parameters = new Array();
    newEvent.parameters.push(totalBandLevelsParam);

    return newEvent;
}

export function createTotalPoolAmountSetEvent(totalPools: BigInt): TotalPoolAmountSetEvent {
    // @ts-ignore
    const newEvent = changetype<TotalPoolAmountSetEvent>(newMockEvent());

    const totalPoolsParam = new ethereum.EventParam(
        "newTotalPoolAmount",
        ethereum.Value.fromUnsignedBigInt(totalPools),
    );

    newEvent.parameters = new Array();
    newEvent.parameters.push(totalPoolsParam);

    return newEvent;
}

export function createBandUpgradeStatusSetEvent(enabled: boolean): BandUpgradeStatusSetEvent {
    // @ts-ignore
    const newEvent = changetype<BandUpgradeStatusSetEvent>(newMockEvent());

    const statusParam = new ethereum.EventParam("enabled", ethereum.Value.fromBoolean(enabled));

    newEvent.parameters = new Array();
    newEvent.parameters.push(statusParam);

    return newEvent;
}

export function createDistributionStatusSetEvent(inProgress: boolean): DistributionStatusSetEvent {
    // @ts-ignore
    const newEvent = changetype<DistributionStatusSetEvent>(newMockEvent());

    const statusParam = new ethereum.EventParam("inProgress", ethereum.Value.fromBoolean(inProgress));

    newEvent.parameters = new Array();
    newEvent.parameters.push(statusParam);

    return newEvent;
}

export function createTokensWithdrawnEvent(token: Address, receiver: Address, amount: BigInt): TokensWithdrawnEvent {
    // @ts-ignore
    const newEvent = changetype<TokensWithdrawnEvent>(newMockEvent());

    const tokenParam = new ethereum.EventParam("token", ethereum.Value.fromAddress(token));
    const receiverParam = new ethereum.EventParam("receiver", ethereum.Value.fromAddress(receiver));
    const amountParam = new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount));

    newEvent.parameters = new Array();
    newEvent.parameters.push(tokenParam);
    newEvent.parameters.push(receiverParam);
    newEvent.parameters.push(amountParam);

    return newEvent;
}

export function createDistributionCreatedEvent(token: Address, amount: BigInt, date: BigInt): DistributionCreatedEvent {
    // @ts-ignore
    const newEvent = changetype<DistributionCreatedEvent>(newMockEvent());

    const tokenParam = new ethereum.EventParam("token", ethereum.Value.fromAddress(token));
    const amountParam = new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount));

    // These are not used in the mapping, but are required for the event
    // Later on, we should remove these params from the contract event overall
    const totalPoolsParam = new ethereum.EventParam("totalPools", ethereum.Value.fromUnsignedBigInt(BIGINT_ZERO));
    const totalBandLevelsParam = new ethereum.EventParam(
        "totalBandLevels",
        ethereum.Value.fromUnsignedBigInt(BIGINT_ZERO),
    );
    const totalStakersParam = new ethereum.EventParam("totalStakers", ethereum.Value.fromUnsignedBigInt(BIGINT_ZERO));
    const distributionTimestampParam = new ethereum.EventParam(
        "distributionTimestamp",
        ethereum.Value.fromUnsignedBigInt(BIGINT_ZERO),
    );

    newEvent.block.timestamp = date;

    newEvent.parameters = new Array();
    newEvent.parameters.push(tokenParam);
    newEvent.parameters.push(amountParam);
    newEvent.parameters.push(totalPoolsParam);
    newEvent.parameters.push(totalBandLevelsParam);
    newEvent.parameters.push(totalStakersParam);
    newEvent.parameters.push(distributionTimestampParam);
    return newEvent;
}

export function createRewardsDistributedEvent(token: Address, date: BigInt): RewardsDistributedEvent {
    // @ts-ignore
    const newEvent = changetype<RewardsDistributedEvent>(newMockEvent());

    const tokenParam = new ethereum.EventParam("token", ethereum.Value.fromAddress(token));

    newEvent.block.timestamp = date;

    newEvent.parameters = new Array();
    newEvent.parameters.push(tokenParam);

    return newEvent;
}

export function createSharesSyncTriggeredEvent(date: BigInt): SharesSyncTriggeredEvent {
    // @ts-ignore
    const newEvent = changetype<SharesSyncTriggeredEvent>(newMockEvent());

    newEvent.block.timestamp = date;

    return newEvent;
}

export function createStakedEvent(
    staker: Address,
    bandLevel: BigInt,
    bandId: BigInt,
    fixedMonths: BigInt,
    stakingType: StakingType,
    areTokensVested: boolean,
    date: BigInt,
): StakedEvent {
    // @ts-ignore
    const newEvent = changetype<StakedEvent>(newMockEvent());

    const stakerParam = new ethereum.EventParam("user", ethereum.Value.fromAddress(staker));
    const bandLevelParam = new ethereum.EventParam("bandLevel", ethereum.Value.fromUnsignedBigInt(bandLevel));
    const bandIdParam = new ethereum.EventParam("bandId", ethereum.Value.fromUnsignedBigInt(bandId));
    const fixedMonthsParam = new ethereum.EventParam("fixedMonths", ethereum.Value.fromUnsignedBigInt(fixedMonths));
    const stakingTypeParam = new ethereum.EventParam("stakingType", ethereum.Value.fromI32(stakingType));
    const areTokensVestedParam = new ethereum.EventParam(
        "areTokensVested",
        ethereum.Value.fromBoolean(areTokensVested),
    );

    newEvent.block.timestamp = date;

    newEvent.parameters = new Array();
    newEvent.parameters.push(stakerParam);
    newEvent.parameters.push(bandLevelParam);
    newEvent.parameters.push(bandIdParam);
    newEvent.parameters.push(fixedMonthsParam);
    newEvent.parameters.push(stakingTypeParam);
    newEvent.parameters.push(areTokensVestedParam);

    return newEvent;
}

export function createUnstakedEvent(
    staker: Address,
    bandId: BigInt,
    areTokensVested: boolean,
    date: BigInt,
): UnstakedEvent {
    // @ts-ignore
    const newEvent = changetype<UnstakedEvent>(newMockEvent());

    const stakerParam = new ethereum.EventParam("user", ethereum.Value.fromAddress(staker));
    const bandIdParam = new ethereum.EventParam("bandId", ethereum.Value.fromUnsignedBigInt(bandId));
    const areTokensVestedParam = new ethereum.EventParam(
        "areTokensVested",
        ethereum.Value.fromBoolean(areTokensVested),
    );

    newEvent.block.timestamp = date;

    newEvent.parameters = new Array();
    newEvent.parameters.push(stakerParam);
    newEvent.parameters.push(bandIdParam);
    newEvent.parameters.push(areTokensVestedParam);

    return newEvent;
}

export function createVestingUserDeletedEvent(staker: Address): VestingUserDeletedEvent {
    // @ts-ignore
    const newEvent = changetype<VestingUserDeletedEvent>(newMockEvent());

    const stakerParam = new ethereum.EventParam("user", ethereum.Value.fromAddress(staker));

    newEvent.parameters = new Array();
    newEvent.parameters.push(stakerParam);

    return newEvent;
}

export function createBandUpgradedEvent(
    staker: Address,
    bandId: BigInt,
    oldBandLevel: BigInt,
    newBandLevel: BigInt,
    newPurchasePrice: BigInt,
    date: BigInt,
): BandUpgradedEvent {
    // @ts-ignore
    const newEvent = changetype<BandUpgradedEvent>(newMockEvent());

    const stakerParam = new ethereum.EventParam("user", ethereum.Value.fromAddress(staker));
    const bandIdParam = new ethereum.EventParam("bandId", ethereum.Value.fromUnsignedBigInt(bandId));
    const oldBandLevelParam = new ethereum.EventParam("oldBandLevel", ethereum.Value.fromUnsignedBigInt(oldBandLevel));
    const newBandLevelParam = new ethereum.EventParam("newBandLevel", ethereum.Value.fromUnsignedBigInt(newBandLevel));
    const newPurchasePriceParam = new ethereum.EventParam(
        "newPurchasePrice",
        ethereum.Value.fromUnsignedBigInt(newPurchasePrice),
    );

    newEvent.block.timestamp = date;

    newEvent.parameters = new Array();
    newEvent.parameters.push(stakerParam);
    newEvent.parameters.push(bandIdParam);
    newEvent.parameters.push(oldBandLevelParam);
    newEvent.parameters.push(newBandLevelParam);
    newEvent.parameters.push(newPurchasePriceParam);

    return newEvent;
}

export function createBandDowngradedEvent(
    staker: Address,
    bandId: BigInt,
    oldBandLevel: BigInt,
    newBandLevel: BigInt,
    newPurchasePrice: BigInt,
    date: BigInt,
): BandDowngradedEvent {
    // @ts-ignore
    const newEvent = changetype<BandDowngradedEvent>(newMockEvent());

    const stakerParam = new ethereum.EventParam("user", ethereum.Value.fromAddress(staker));
    const bandIdParam = new ethereum.EventParam("bandId", ethereum.Value.fromUnsignedBigInt(bandId));
    const oldBandLevelParam = new ethereum.EventParam("oldBandLevel", ethereum.Value.fromUnsignedBigInt(oldBandLevel));
    const newBandLevelParam = new ethereum.EventParam("newBandLevel", ethereum.Value.fromUnsignedBigInt(newBandLevel));
    const newPurchasePriceParam = new ethereum.EventParam(
        "newPurchasePrice",
        ethereum.Value.fromUnsignedBigInt(newPurchasePrice),
    );

    newEvent.block.timestamp = date;

    newEvent.parameters = new Array();
    newEvent.parameters.push(stakerParam);
    newEvent.parameters.push(bandIdParam);
    newEvent.parameters.push(oldBandLevelParam);
    newEvent.parameters.push(newBandLevelParam);
    newEvent.parameters.push(newPurchasePriceParam);

    return newEvent;
}

export function createRewardsClaimedEvent(
    staker: Address,
    token: Address,
    amount: BigInt,
    date: BigInt,
): RewardsClaimedEvent {
    // @ts-ignore
    const newEvent = changetype<RewardsClaimedEvent>(newMockEvent());

    const stakerParam = new ethereum.EventParam("user", ethereum.Value.fromAddress(staker));
    const tokenParam = new ethereum.EventParam("token", ethereum.Value.fromAddress(token));
    const amountParam = new ethereum.EventParam("totalRewards", ethereum.Value.fromUnsignedBigInt(amount));

    newEvent.block.timestamp = date;

    newEvent.parameters = new Array();
    newEvent.parameters.push(stakerParam);
    newEvent.parameters.push(tokenParam);
    newEvent.parameters.push(amountParam);

    return newEvent;
}
