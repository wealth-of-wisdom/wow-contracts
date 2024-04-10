import { BigInt } from "@graphprotocol/graph-ts";
import { BIGINT_ZERO, BIGINT_ONE } from "../../../src/utils/constants";
import { createArray, createArrayWithMultiplication, createDoubleArray } from "../arrays";
import { monthInSeconds } from "./dates";
import { wowDecimalsPrecision } from "./constants";

/*//////////////////////////////////////////////////////////////////////////
                                POOL DETAILS
//////////////////////////////////////////////////////////////////////////*/

export const poolIds: BigInt[] = createArray(BIGINT_ONE, BigInt.fromI32(9));

export const poolDistributionPercentages: BigInt[] = [
    BigInt.fromI32(1_300_000), // 1.3%
    BigInt.fromI32(1_700_000), // 1.7%
    BigInt.fromI32(3_400_000), // 3.4%
    BigInt.fromI32(6_400_000), // 6.4%
    BigInt.fromI32(15_600_000), // 15.6%
    BigInt.fromI32(14_600_000), // 14.6%
    BigInt.fromI32(24_000_000), // 24%
    BigInt.fromI32(19_000_000), // 19%
    BigInt.fromI32(14_000_000), // 14%
];

/*//////////////////////////////////////////////////////////////////////////
                            BAND LEVEL DETAILS
//////////////////////////////////////////////////////////////////////////*/

export const bandLevels: BigInt[] = createArray(BIGINT_ONE, BigInt.fromI32(9));

export const bandLevelPrices: BigInt[] = [
    BigInt.fromI32(1_000).times(wowDecimalsPrecision),
    BigInt.fromI32(3_000).times(wowDecimalsPrecision),
    BigInt.fromI32(10_000).times(wowDecimalsPrecision),
    BigInt.fromI32(30_000).times(wowDecimalsPrecision),
    BigInt.fromI32(100_000).times(wowDecimalsPrecision),
    BigInt.fromI32(200_000).times(wowDecimalsPrecision),
    BigInt.fromI32(500_000).times(wowDecimalsPrecision),
    BigInt.fromI32(1_000_000).times(wowDecimalsPrecision),
    BigInt.fromI32(2_000_000).times(wowDecimalsPrecision),
];

export const bandLevelAccessiblePools: BigInt[][] = createDoubleArray(BIGINT_ONE, BigInt.fromI32(9));

/*//////////////////////////////////////////////////////////////////////////
                                SHARES DETAILS
//////////////////////////////////////////////////////////////////////////*/

export const months: BigInt[] = createArray(BIGINT_ZERO, BigInt.fromI32(25));

export const secondsInMonths: BigInt[] = createArrayWithMultiplication(BIGINT_ZERO, BigInt.fromI32(50), monthInSeconds);

export const sharesInMonths: BigInt[] = [
    BigInt.fromI32(1_000_000),
    BigInt.fromI32(2_000_000),
    BigInt.fromI32(2_500_000),
    BigInt.fromI32(3_000_000),
    BigInt.fromI32(3_500_000),
    BigInt.fromI32(4_000_000),
    BigInt.fromI32(4_500_000),
    BigInt.fromI32(5_000_000),
    BigInt.fromI32(5_500_000),
    BigInt.fromI32(6_000_000),
    BigInt.fromI32(6_125_000),
    BigInt.fromI32(8_250_000),
    BigInt.fromI32(8_375_000),
    BigInt.fromI32(8_500_000),
    BigInt.fromI32(8_625_000),
    BigInt.fromI32(8_750_000),
    BigInt.fromI32(8_875_000),
    BigInt.fromI32(9_000_000),
    BigInt.fromI32(9_125_000),
    BigInt.fromI32(9_250_000),
    BigInt.fromI32(9_375_000),
    BigInt.fromI32(9_500_000),
    BigInt.fromI32(9_625_000),
    BigInt.fromI32(12_000_000),
];
