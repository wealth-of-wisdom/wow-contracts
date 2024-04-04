import { BigInt } from "@graphprotocol/graph-ts";

/*//////////////////////////////////////////////////////////////////////////
                                  DATES
//////////////////////////////////////////////////////////////////////////*/

export const monthInSeconds: BigInt = BigInt.fromI32(30 * 24 * 60 * 60);

export const preInitDate: BigInt = BigInt.fromI32(1000000000); // Sun Sep 09, 2001 1:46:40 AM
export const initDate: BigInt = BigInt.fromI32(1710000000); // Sat Mar 09 2024 16:00:00 GMT+0000

export const month1AfterInit: BigInt = initDate.plus(monthInSeconds);
export const month2AfterInit: BigInt = month1AfterInit.plus(monthInSeconds);
export const month3AfterInit: BigInt = month2AfterInit.plus(monthInSeconds);
export const month4AfterInit: BigInt = month3AfterInit.plus(monthInSeconds);
export const month5AfterInit: BigInt = month4AfterInit.plus(monthInSeconds);
export const month6AfterInit: BigInt = month5AfterInit.plus(monthInSeconds);
export const month7AfterInit: BigInt = month6AfterInit.plus(monthInSeconds);
export const month8AfterInit: BigInt = month7AfterInit.plus(monthInSeconds);
export const month9AfterInit: BigInt = month8AfterInit.plus(monthInSeconds);
export const month10AfterInit: BigInt = month9AfterInit.plus(monthInSeconds);
export const month11AfterInit: BigInt = month10AfterInit.plus(monthInSeconds);
export const month12AfterInit: BigInt = month11AfterInit.plus(monthInSeconds);

export const monthsAfterInit: BigInt[] = [
    initDate,
    month1AfterInit,
    month2AfterInit,
    month3AfterInit,
    month4AfterInit,
    month5AfterInit,
    month6AfterInit,
    month7AfterInit,
    month8AfterInit,
    month9AfterInit,
    month10AfterInit,
    month11AfterInit,
    month12AfterInit,
];
