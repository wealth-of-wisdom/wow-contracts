import { ethereum } from "@graphprotocol/graph-ts";
import { createMockedFunction } from "matchstick-as/assembly/index";
import {
    stakingAddress,
    usdtToken,
    usdcToken,
    wowToken,
    percentagePrecision,
    sharePrecision,
    totalPools,
    totalBandLevels,
} from "../../utils/constants";

export function createMockedFunctions(): void {
    createMockedFunction_getTokenUSDT();
    createMockedFunction_getTokenUSDC();
    createMockedFunction_getTokenWOW();
    createMockedFunction_PERCENTAGE_PRECISION();
    createMockedFunction_SHARE();
    createMockedFunction_getTotalPools();
    createMockedFunction_getTotalBandLevels();
}

export function createMockedFunction_getTokenUSDT(): void {
    createMockedFunction(stakingAddress, "getTokenUSDT", "getTokenUSDT():(address)")
        .withArgs([])
        .returns([ethereum.Value.fromAddress(usdtToken)]);
}

export function createMockedFunction_getTokenUSDC(): void {
    createMockedFunction(stakingAddress, "getTokenUSDC", "getTokenUSDC():(address)")
        .withArgs([])
        .returns([ethereum.Value.fromAddress(usdcToken)]);
}

export function createMockedFunction_getTokenWOW(): void {
    createMockedFunction(stakingAddress, "getTokenWOW", "getTokenWOW():(address)")
        .withArgs([])
        .returns([ethereum.Value.fromAddress(wowToken)]);
}

export function createMockedFunction_PERCENTAGE_PRECISION(): void {
    createMockedFunction(stakingAddress, "PERCENTAGE_PRECISION", "PERCENTAGE_PRECISION():(uint48)")
        .withArgs([])
        .returns([ethereum.Value.fromUnsignedBigInt(percentagePrecision)]);
}

export function createMockedFunction_SHARE(): void {
    createMockedFunction(stakingAddress, "SHARE", "SHARE():(uint48)")
        .withArgs([])
        .returns([ethereum.Value.fromUnsignedBigInt(sharePrecision)]);
}

export function createMockedFunction_getTotalPools(): void {
    createMockedFunction(stakingAddress, "getTotalPools", "getTotalPools():(uint16)")
        .withArgs([])
        .returns([ethereum.Value.fromUnsignedBigInt(totalPools)]);
}

export function createMockedFunction_getTotalBandLevels(): void {
    createMockedFunction(stakingAddress, "getTotalBandLevels", "getTotalBandLevels():(uint16)")
        .withArgs([])
        .returns([ethereum.Value.fromUnsignedBigInt(totalBandLevels)]);
}
