import { Address, BigDecimal, BigInt } from "@graphprotocol/graph-ts";
import { UnlockType, StakingType, ActivityStatus } from "./enums";
import { stringifyUnlockType, stringifyStakingType, stringifyActivityStatus } from "./utils";

export const BIGINT_ZERO: BigInt = BigInt.zero();
export const BIGINT_ONE: BigInt = BigInt.fromI32(1);
export const BIGINT_TWO: BigInt = BigInt.fromI32(2);
export const BIGINT_PERCENTAGE_MULTIPLIER: BigInt = BigInt.fromI32(100);
export const BIGINT_1e12: BigInt = BigInt.fromString("1000000000000"); // 1e12

export const BIGDEC_ZERO: BigDecimal = BigDecimal.zero();
export const BIGDEC_HUNDRED: BigDecimal = BigDecimal.fromString("100");

export const ADDRESS_ZERO: Address = Address.zero();

export const SEPOLIA_NETWORK: string = "sepolia";
export const ARBITRUM_SEPOLIA_NETWORK: string = "arbitrum-sepolia";
export const ETH_MAINNET_NETWORK: string = "mainnet";
export const ARBITRUM_ONE_NETWORK: string = "arbitrum-one";

export const TESTNET_NETWORKS: string[] = [SEPOLIA_NETWORK, ARBITRUM_SEPOLIA_NETWORK];
export const MAINNET_NETWORKS: string[] = [ETH_MAINNET_NETWORK, ARBITRUM_ONE_NETWORK];

export const MONTH_IN_SECONDS: BigInt = BigInt.fromI32(30 * 24 * 60 * 60); // 30 days
export const TEN_MINUTES_IN_SECONDS: BigInt = BigInt.fromI32(10 * 60); // 10 minutes
export const TWELVE_HOURS_IN_SECONDS: BigInt = BigInt.fromI32(12 * 60 * 60); // 12 hours

// Enum values

export const UNLOCK_TYPE_DAILY: string = stringifyUnlockType(UnlockType.DAILY);
export const UNLOCK_TYPE_MONTHLY: string = stringifyUnlockType(UnlockType.MONTHLY);

export const STAKING_TYPE_FIX: string = stringifyStakingType(StakingType.FIX);
export const STAKING_TYPE_FLEXI: string = stringifyStakingType(StakingType.FLEXI);

export const ACTIVITY_STATUS_NOT_ACTIVATED: string = stringifyActivityStatus(ActivityStatus.NOT_ACTIVATED);
export const ACTIVITY_STATUS_ACTIVATED: string = stringifyActivityStatus(ActivityStatus.ACTIVATED);
export const ACTIVITY_STATUS_DEACTIVATED: string = stringifyActivityStatus(ActivityStatus.DEACTIVATED);
