import { BigInt } from "@graphprotocol/graph-ts";

/*//////////////////////////////////////////////////////////////////////////
                                  DATES
//////////////////////////////////////////////////////////////////////////*/

export const monthInSeconds: BigInt = BigInt.fromI32(30 * 24 * 60 * 60);

export const preInitDate: BigInt = BigInt.fromI32(1000000000); // Sun Sep 09, 2001 1:46:40 AM
export const initDate: BigInt = BigInt.fromI32(1710000000); // Sat Mar 09 2024 16:00:00 GMT+0000

export const monthsAfterInit: BigInt[] = [
    initDate,
    initDate.plus(monthInSeconds),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(2))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(3))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(4))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(5))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(6))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(7))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(8))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(9))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(10))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(11))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(12))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(13))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(14))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(15))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(16))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(17))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(18))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(19))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(20))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(21))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(22))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(23))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(24))),
    initDate.plus(monthInSeconds.times(BigInt.fromI32(25))),
];
