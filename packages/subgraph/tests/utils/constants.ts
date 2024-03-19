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

// DATES

export const initDate: BigInt = BigInt.fromI32(1710000000); // Sat Mar 09 2024 16:00:00 GMT+0000

// STRINGS

export const zeroId: string = "0";