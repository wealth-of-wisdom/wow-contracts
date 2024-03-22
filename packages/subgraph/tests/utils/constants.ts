import { Address, BigInt } from "@graphprotocol/graph-ts";
import { BIGINT_ZERO, BIGINT_ONE } from "../../src/utils/constants";
import { createArray, createArrayWithMultiplication, createDoubleArray, createStringifiedArray } from "./arrays";

/*//////////////////////////////////////////////////////////////////////////
                                ADDRESSES
//////////////////////////////////////////////////////////////////////////*/

export const stakingAddress: Address = Address.fromString("0x1111111111111111111111111111111111111111");

export const usdtToken: Address = Address.fromString("0x0000000000000000000000000000000000000010");
export const usdcToken: Address = Address.fromString("0x0000000000000000000000000000000000000011");
export const wowToken: Address = Address.fromString("0x0000000000000000000000000000000000000012");
export const newToken: Address = Address.fromString("0x0000000000000000000000000000000000000013");

export const alice: Address = Address.fromString("0x0000000000000000000000000000000000000100");
export const bob: Address = Address.fromString("0x0000000000000000000000000000000000000101");
export const charlie: Address = Address.fromString("0x0000000000000000000000000000000000000102");

/*//////////////////////////////////////////////////////////////////////////
                                NUMBERS
//////////////////////////////////////////////////////////////////////////*/

export const percentagePrecision: BigInt = BigInt.fromI32(100_000_000); // 1e8
export const totalPools: BigInt = BigInt.fromI32(9);
export const totalBandLevels: BigInt = BigInt.fromI32(9);

export const usdDecimals: BigInt = BigInt.fromI32(6);
export const usdDecimalsPrecision: BigInt = usdDecimals.pow(10);

export const wowDecimals: BigInt = BigInt.fromI32(18);
export const wowDecimalsPrecision: BigInt = wowDecimals.pow(10);

/*//////////////////////////////////////////////////////////////////////////
                                AMOUNTS
//////////////////////////////////////////////////////////////////////////*/

export const usd100k: BigInt = BigInt.fromI32(100_000).times(usdDecimalsPrecision);

/*//////////////////////////////////////////////////////////////////////////
                                  DATES
//////////////////////////////////////////////////////////////////////////*/

export const initDate: BigInt = BigInt.fromI32(1710000000); // Sat Mar 09 2024 16:00:00 GMT+0000

/*//////////////////////////////////////////////////////////////////////////
                                    IDS
//////////////////////////////////////////////////////////////////////////*/

export const zeroStr: string = "0";

export const ids: string[] = createStringifiedArray(BIGINT_ZERO, BigInt.fromI32(100));

export const bandIds: BigInt[] = createArray(BIGINT_ZERO, BigInt.fromI32(100));

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

export const months: BigInt[] = createArray(BIGINT_ZERO, BigInt.fromI32(50));

export const monthsInSeconds: BigInt[] = createArrayWithMultiplication(
    BIGINT_ZERO,
    BigInt.fromI32(50),
    BigInt.fromI32(30 * 24 * 60 * 60),
);

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
