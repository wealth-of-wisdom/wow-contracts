import { Address, BigInt } from "@graphprotocol/graph-ts";

// ADDRESSES

export const stakingAddress: Address = Address.fromString("0x1111111111111111111111111111111111111111");

export const usdtToken: Address = Address.fromString("0x0000000000000000000000000000000000000010");
export const usdcToken: Address = Address.fromString("0x0000000000000000000000000000000000000011");
export const wowToken: Address = Address.fromString("0x0000000000000000000000000000000000000012");

export const alice: Address = Address.fromString("0x0000000000000000000000000000000000000100");
export const bob: Address = Address.fromString("0x0000000000000000000000000000000000000101");
export const charlie: Address = Address.fromString("0x0000000000000000000000000000000000000102");

// NUMBERS

export const percentagePrecision: BigInt = BigInt.fromI32(100000000); // 1e8
export const totalPools: BigInt = BigInt.fromI32(9);
export const totalBandLevels: BigInt = BigInt.fromI32(9);

export const usdDecimals: BigInt = BigInt.fromI32(6);
export const usdDecimalsPrecision: BigInt = usdDecimals.pow(10);

export const wowDecimals: BigInt = BigInt.fromI32(18);
export const wowDecimalsPrecision: BigInt = wowDecimals.pow(10);

// DATES

export const initDate: BigInt = BigInt.fromI32(1710000000); // Sat Mar 09 2024 16:00:00 GMT+0000

// IDS

export const zeroId: string = "0";

// POOL DETAILS

export const pool1: BigInt = BigInt.fromI32(1);
export const pool2: BigInt = BigInt.fromI32(2);
export const pool3: BigInt = BigInt.fromI32(3);
export const pool4: BigInt = BigInt.fromI32(4);
export const pool5: BigInt = BigInt.fromI32(5);
export const pool6: BigInt = BigInt.fromI32(6);
export const pool7: BigInt = BigInt.fromI32(7);
export const pool8: BigInt = BigInt.fromI32(8);
export const pool9: BigInt = BigInt.fromI32(9);

export const pool1DistributionPercentage: BigInt = BigInt.fromI32(1_300_000);
export const pool2DistributionPercentage: BigInt = BigInt.fromI32(1_700_000);
export const pool3DistributionPercentage: BigInt = BigInt.fromI32(3_400_000);
export const pool4DistributionPercentage: BigInt = BigInt.fromI32(6_400_000);
export const pool5DistributionPercentage: BigInt = BigInt.fromI32(15_600_000);
export const pool6DistributionPercentage: BigInt = BigInt.fromI32(14_600_000);
export const pool7DistributionPercentage: BigInt = BigInt.fromI32(24_000_000);
export const pool8DistributionPercentage: BigInt = BigInt.fromI32(19_000_000);
export const pool9DistributionPercentage: BigInt = BigInt.fromI32(14_000_000);

export const poolDistributionPercentages: BigInt[] = [
    pool1DistributionPercentage,
    pool2DistributionPercentage,
    pool3DistributionPercentage,
    pool4DistributionPercentage,
    pool5DistributionPercentage,
    pool6DistributionPercentage,
    pool7DistributionPercentage,
    pool8DistributionPercentage,
    pool9DistributionPercentage,
];

// BAND LEVEL DETAILS

export const bandLevel1: BigInt = BigInt.fromI32(1);
export const bandLevel2: BigInt = BigInt.fromI32(2);
export const bandLevel3: BigInt = BigInt.fromI32(3);
export const bandLevel4: BigInt = BigInt.fromI32(4);
export const bandLevel5: BigInt = BigInt.fromI32(5);
export const bandLevel6: BigInt = BigInt.fromI32(6);
export const bandLevel7: BigInt = BigInt.fromI32(7);
export const bandLevel8: BigInt = BigInt.fromI32(8);
export const bandLevel9: BigInt = BigInt.fromI32(9);

export const bandLevel1Price: BigInt = BigInt.fromI32(1_000).times(wowDecimalsPrecision);
export const bandLevel2Price: BigInt = BigInt.fromI32(3_000).times(wowDecimalsPrecision);
export const bandLevel3Price: BigInt = BigInt.fromI32(10_000).times(wowDecimalsPrecision);
export const bandLevel4Price: BigInt = BigInt.fromI32(30_000).times(wowDecimalsPrecision);
export const bandLevel5Price: BigInt = BigInt.fromI32(100_000).times(wowDecimalsPrecision);
export const bandLevel6Price: BigInt = BigInt.fromI32(200_000).times(wowDecimalsPrecision);
export const bandLevel7Price: BigInt = BigInt.fromI32(500_000).times(wowDecimalsPrecision);
export const bandLevel8Price: BigInt = BigInt.fromI32(1_000_000).times(wowDecimalsPrecision);
export const bandLevel9Price: BigInt = BigInt.fromI32(2_000_000).times(wowDecimalsPrecision);

export const bandLevelPrices: BigInt[] = [
    bandLevel1Price,
    bandLevel2Price,
    bandLevel3Price,
    bandLevel4Price,
    bandLevel5Price,
    bandLevel6Price,
    bandLevel7Price,
    bandLevel8Price,
    bandLevel9Price,
];

export const bandLevel1AccessiblePools: BigInt[] = [pool1];
export const bandLevel2AccessiblePools: BigInt[] = [pool1, pool2];
export const bandLevel3AccessiblePools: BigInt[] = [pool1, pool2, pool3];
export const bandLevel4AccessiblePools: BigInt[] = [pool1, pool2, pool3, pool4];
export const bandLevel5AccessiblePools: BigInt[] = [pool1, pool2, pool3, pool4, pool5];
export const bandLevel6AccessiblePools: BigInt[] = [pool1, pool2, pool3, pool4, pool5, pool6];
export const bandLevel7AccessiblePools: BigInt[] = [pool1, pool2, pool3, pool4, pool5, pool6, pool7];
export const bandLevel8AccessiblePools: BigInt[] = [pool1, pool2, pool3, pool4, pool5, pool6, pool7, pool8];
export const bandLevel9AccessiblePools: BigInt[] = [pool1, pool2, pool3, pool4, pool5, pool6, pool7, pool8, pool9];

export const bandLevelAccessiblePools: BigInt[][] = [
    bandLevel1AccessiblePools,
    bandLevel2AccessiblePools,
    bandLevel3AccessiblePools,
    bandLevel4AccessiblePools,
    bandLevel5AccessiblePools,
    bandLevel6AccessiblePools,
    bandLevel7AccessiblePools,
    bandLevel8AccessiblePools,
    bandLevel9AccessiblePools,
];

// SHARES DETAILS

export const sharesInMonth1: BigInt = BigInt.fromI32(1_000_000);
// @todo finish with shares and maybe add calculations instead of hardcoding values
