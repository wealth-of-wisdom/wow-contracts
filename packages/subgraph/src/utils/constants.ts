import { Address, BigDecimal, BigInt, Bytes } from "@graphprotocol/graph-ts";

export const BIGINT_ZERO: BigInt = BigInt.zero();
export const BIGINT_ONE: BigInt = BigInt.fromI32(1);
export const BIGINT_TWO: BigInt = BigInt.fromI32(2);
export const BIGINT_PERCENTAGE_MULTIPLIER: BigInt = BigInt.fromI32(100);
export const BIGINT_1e12: BigInt = BigInt.fromString("1000000000000"); // 1e12

export const BIGDEC_ZERO: BigDecimal = BigDecimal.zero();
export const BIGDEC_HUNDRED: BigDecimal = BigDecimal.fromString("100");

export const ADDRESS_ZERO: Address = Address.zero();

// UnlockType represents vesting token time release
export enum UnlockType {
    DAILY,
    MONTHLY,
}
// Fixed - user gets shares inmediately, however stake is locks for that selected period
// Flexi - user earns shares over the time, but stake and be unlocked anytime
export enum StakingType {
    FIX,
    FLEXI,
}
