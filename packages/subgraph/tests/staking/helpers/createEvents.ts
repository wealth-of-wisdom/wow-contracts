import { BigInt, ethereum } from "@graphprotocol/graph-ts";
import { newMockEvent } from "matchstick-as";
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
} from "../../../generated/Staking/Staking";
import { stakingAddress, initDate } from "../../utils/constants";
import { createMockedFunctions } from "./createMockedFunctions";

export function createInitializedEvent(): InitializedEvent {
    createMockedFunctions();

    // @ts-ignore
    const newEvent = changetype<InitializedEvent>(newMockEvent());
    newEvent.address = stakingAddress;
    newEvent.block.timestamp = initDate;

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
