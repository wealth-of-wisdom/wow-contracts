import { BigInt } from "@graphprotocol/graph-ts";
import { BIGINT_ZERO, BIGINT_ONE } from "../../../src/utils/constants";
import { createArray, createArrayWithMultiplication } from "../arrays";
import { monthInSeconds } from "./dates";
import { wowDecimalsPrecision } from "./constants";

/*//////////////////////////////////////////////////////////////////////////
                                POOL DETAILS
//////////////////////////////////////////////////////////////////////////*/

export const poolId1: BigInt = BigInt.fromI32(1);
export const poolId2: BigInt = BigInt.fromI32(2);
export const poolId3: BigInt = BigInt.fromI32(3);
export const poolId4: BigInt = BigInt.fromI32(4);
export const poolId5: BigInt = BigInt.fromI32(5);
export const poolId6: BigInt = BigInt.fromI32(6);
export const poolId7: BigInt = BigInt.fromI32(7);
export const poolId8: BigInt = BigInt.fromI32(8);
export const poolId9: BigInt = BigInt.fromI32(9);

export const poolIds: BigInt[] = createArray(poolId1, poolId9);

export const poolDistributionPercentage1: BigInt = BigInt.fromI32(1_300_000); // 1.3%
export const poolDistributionPercentage2: BigInt = BigInt.fromI32(1_700_000); // 1.7%
export const poolDistributionPercentage3: BigInt = BigInt.fromI32(3_400_000); // 3.4%
export const poolDistributionPercentage4: BigInt = BigInt.fromI32(6_400_000); // 6.4%
export const poolDistributionPercentage5: BigInt = BigInt.fromI32(15_600_000); // 15.6%
export const poolDistributionPercentage6: BigInt = BigInt.fromI32(14_600_000); // 14.6%
export const poolDistributionPercentage7: BigInt = BigInt.fromI32(24_000_000); // 24%
export const poolDistributionPercentage8: BigInt = BigInt.fromI32(19_000_000); // 19%
export const poolDistributionPercentage9: BigInt = BigInt.fromI32(14_000_000); // 14%

export const poolDistributionPercentages: BigInt[] = [
    poolDistributionPercentage1,
    poolDistributionPercentage2,
    poolDistributionPercentage3,
    poolDistributionPercentage4,
    poolDistributionPercentage5,
    poolDistributionPercentage6,
    poolDistributionPercentage7,
    poolDistributionPercentage8,
    poolDistributionPercentage9,
];

/*//////////////////////////////////////////////////////////////////////////
                            BAND LEVEL DETAILS
//////////////////////////////////////////////////////////////////////////*/

export const bandLevel1: BigInt = BigInt.fromI32(1);
export const bandLevel2: BigInt = BigInt.fromI32(2);
export const bandLevel3: BigInt = BigInt.fromI32(3);
export const bandLevel4: BigInt = BigInt.fromI32(4);
export const bandLevel5: BigInt = BigInt.fromI32(5);
export const bandLevel6: BigInt = BigInt.fromI32(6);
export const bandLevel7: BigInt = BigInt.fromI32(7);
export const bandLevel8: BigInt = BigInt.fromI32(8);
export const bandLevel9: BigInt = BigInt.fromI32(9);

export const bandLevels: BigInt[] = createArray(bandLevel1, bandLevel9);

export const bandLevelPrice1: BigInt = BigInt.fromI32(1_000).times(wowDecimalsPrecision);
export const bandLevelPrice2: BigInt = BigInt.fromI32(3_000).times(wowDecimalsPrecision);
export const bandLevelPrice3: BigInt = BigInt.fromI32(10_000).times(wowDecimalsPrecision);
export const bandLevelPrice4: BigInt = BigInt.fromI32(30_000).times(wowDecimalsPrecision);
export const bandLevelPrice5: BigInt = BigInt.fromI32(100_000).times(wowDecimalsPrecision);
export const bandLevelPrice6: BigInt = BigInt.fromI32(200_000).times(wowDecimalsPrecision);
export const bandLevelPrice7: BigInt = BigInt.fromI32(500_000).times(wowDecimalsPrecision);
export const bandLevelPrice8: BigInt = BigInt.fromI32(1_000_000).times(wowDecimalsPrecision);
export const bandLevelPrice9: BigInt = BigInt.fromI32(2_000_000).times(wowDecimalsPrecision);

export const bandLevelPrices: BigInt[] = [
    bandLevelPrice1,
    bandLevelPrice2,
    bandLevelPrice3,
    bandLevelPrice4,
    bandLevelPrice5,
    bandLevelPrice6,
    bandLevelPrice7,
    bandLevelPrice8,
    bandLevelPrice9,
];

export const bandLevelAccessiblePools1: BigInt[] = createArray(BIGINT_ONE, BIGINT_ONE);
export const bandLevelAccessiblePools2: BigInt[] = createArray(BIGINT_ONE, BigInt.fromI32(2));
export const bandLevelAccessiblePools3: BigInt[] = createArray(BIGINT_ONE, BigInt.fromI32(3));
export const bandLevelAccessiblePools4: BigInt[] = createArray(BIGINT_ONE, BigInt.fromI32(4));
export const bandLevelAccessiblePools5: BigInt[] = createArray(BIGINT_ONE, BigInt.fromI32(5));
export const bandLevelAccessiblePools6: BigInt[] = createArray(BIGINT_ONE, BigInt.fromI32(6));
export const bandLevelAccessiblePools7: BigInt[] = createArray(BIGINT_ONE, BigInt.fromI32(7));
export const bandLevelAccessiblePools8: BigInt[] = createArray(BIGINT_ONE, BigInt.fromI32(8));
export const bandLevelAccessiblePools9: BigInt[] = createArray(BIGINT_ONE, BigInt.fromI32(9));

export const bandLevelAccessiblePools: BigInt[][] = [
    bandLevelAccessiblePools1,
    bandLevelAccessiblePools2,
    bandLevelAccessiblePools3,
    bandLevelAccessiblePools4,
    bandLevelAccessiblePools5,
    bandLevelAccessiblePools6,
    bandLevelAccessiblePools7,
    bandLevelAccessiblePools8,
    bandLevelAccessiblePools9,
];

/*//////////////////////////////////////////////////////////////////////////
                                SHARES DETAILS
//////////////////////////////////////////////////////////////////////////*/

export const month0: BigInt = BigInt.fromI32(0);
export const month1: BigInt = BigInt.fromI32(1);
export const month2: BigInt = BigInt.fromI32(2);
export const month3: BigInt = BigInt.fromI32(3);
export const month4: BigInt = BigInt.fromI32(4);
export const month5: BigInt = BigInt.fromI32(5);
export const month6: BigInt = BigInt.fromI32(6);
export const month7: BigInt = BigInt.fromI32(7);
export const month8: BigInt = BigInt.fromI32(8);
export const month9: BigInt = BigInt.fromI32(9);
export const month10: BigInt = BigInt.fromI32(10);
export const month11: BigInt = BigInt.fromI32(11);
export const month12: BigInt = BigInt.fromI32(12);
export const month13: BigInt = BigInt.fromI32(13);
export const month14: BigInt = BigInt.fromI32(14);
export const month15: BigInt = BigInt.fromI32(15);
export const month16: BigInt = BigInt.fromI32(16);
export const month17: BigInt = BigInt.fromI32(17);
export const month19: BigInt = BigInt.fromI32(19);
export const month20: BigInt = BigInt.fromI32(20);
export const month21: BigInt = BigInt.fromI32(21);
export const month22: BigInt = BigInt.fromI32(22);
export const month23: BigInt = BigInt.fromI32(23);
export const month24: BigInt = BigInt.fromI32(24);
export const month25: BigInt = BigInt.fromI32(25);

export const months: BigInt[] = createArray(month0, month25);

export const secondsInMonths: BigInt[] = createArrayWithMultiplication(BIGINT_ZERO, BigInt.fromI32(50), monthInSeconds);

export const sharesInMonth1: BigInt = BigInt.fromI32(1_000_000);
export const sharesInMonth2: BigInt = BigInt.fromI32(2_000_000);
export const sharesInMonth3: BigInt = BigInt.fromI32(2_500_000);
export const sharesInMonth4: BigInt = BigInt.fromI32(3_000_000);
export const sharesInMonth5: BigInt = BigInt.fromI32(3_500_000);
export const sharesInMonth6: BigInt = BigInt.fromI32(4_000_000);
export const sharesInMonth7: BigInt = BigInt.fromI32(4_500_000);
export const sharesInMonth8: BigInt = BigInt.fromI32(5_000_000);
export const sharesInMonth9: BigInt = BigInt.fromI32(5_500_000);
export const sharesInMonth10: BigInt = BigInt.fromI32(6_000_000);
export const sharesInMonth11: BigInt = BigInt.fromI32(6_125_000);
export const sharesInMonth12: BigInt = BigInt.fromI32(8_250_000);
export const sharesInMonth13: BigInt = BigInt.fromI32(8_375_000);
export const sharesInMonth14: BigInt = BigInt.fromI32(8_500_000);
export const sharesInMonth15: BigInt = BigInt.fromI32(8_625_000);
export const sharesInMonth16: BigInt = BigInt.fromI32(8_750_000);
export const sharesInMonth17: BigInt = BigInt.fromI32(8_875_000);
export const sharesInMonth18: BigInt = BigInt.fromI32(9_000_000);
export const sharesInMonth19: BigInt = BigInt.fromI32(9_125_000);
export const sharesInMonth20: BigInt = BigInt.fromI32(9_250_000);
export const sharesInMonth21: BigInt = BigInt.fromI32(9_375_000);
export const sharesInMonth22: BigInt = BigInt.fromI32(9_500_000);
export const sharesInMonth23: BigInt = BigInt.fromI32(9_625_000);
export const sharesInMonth24: BigInt = BigInt.fromI32(12_000_000);

export const sharesInMonths: BigInt[] = [
    sharesInMonth1,
    sharesInMonth2,
    sharesInMonth3,
    sharesInMonth4,
    sharesInMonth5,
    sharesInMonth6,
    sharesInMonth7,
    sharesInMonth8,
    sharesInMonth9,
    sharesInMonth10,
    sharesInMonth11,
    sharesInMonth12,
    sharesInMonth13,
    sharesInMonth14,
    sharesInMonth15,
    sharesInMonth16,
    sharesInMonth17,
    sharesInMonth18,
    sharesInMonth19,
    sharesInMonth20,
    sharesInMonth21,
    sharesInMonth22,
    sharesInMonth23,
    sharesInMonth24,
];
