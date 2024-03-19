import { BigInt } from "@graphprotocol/graph-ts";
import {
    handleInitialized,
    handlePoolSet,
    handleBandLevelSet,
    handleSharesInMonthSet,
} from "../../../src/mappings/staking";
import {
    createInitializedEvent,
    createPoolSetEvent,
    createBandLevelSetEvent,
    createSharesInMonthSetEvent,
} from "../helpers/createEvents";

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
