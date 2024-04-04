import { Address, BigInt } from "@graphprotocol/graph-ts";
import { BIGINT_ZERO, BIGINT_ONE } from "../../../src/utils/constants";
import { createArray, createArrayWithMultiplication, createDoubleArray, createStringifiedArray } from "../arrays";

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
export const sharePrecision: BigInt = BigInt.fromI32(1_000_000); // 1e6

export const totalPools: BigInt = BigInt.fromI32(9);
export const totalBandLevels: BigInt = BigInt.fromI32(9);

export const usdDecimalsPrecision: BigInt = BigInt.fromI32(10).pow(6);
export const wowDecimalsPrecision: BigInt = BigInt.fromI32(10).pow(18);

/*//////////////////////////////////////////////////////////////////////////
                                ARRAYS
//////////////////////////////////////////////////////////////////////////*/

export const zeroSharesPerPool: BigInt[] = new Array<BigInt>(totalPools.toI32()).fill(BIGINT_ZERO);

/*//////////////////////////////////////////////////////////////////////////
                                AMOUNTS
//////////////////////////////////////////////////////////////////////////*/

export const usd100k: BigInt = BigInt.fromI32(100_000).times(usdDecimalsPrecision);
export const usd200k: BigInt = BigInt.fromI32(200_000).times(usdDecimalsPrecision);
export const usd300k: BigInt = BigInt.fromI32(300_000).times(usdDecimalsPrecision);
export const usd400k: BigInt = BigInt.fromI32(400_000).times(usdDecimalsPrecision);
export const usd500k: BigInt = BigInt.fromI32(500_000).times(usdDecimalsPrecision);
export const usd600k: BigInt = BigInt.fromI32(600_000).times(usdDecimalsPrecision);
export const usd700k: BigInt = BigInt.fromI32(700_000).times(usdDecimalsPrecision);
export const usd800k: BigInt = BigInt.fromI32(800_000).times(usdDecimalsPrecision);
export const usd900k: BigInt = BigInt.fromI32(900_000).times(usdDecimalsPrecision);
export const usd1m: BigInt = BigInt.fromI32(1_000_000).times(usdDecimalsPrecision);

/*//////////////////////////////////////////////////////////////////////////
                                    IDS
//////////////////////////////////////////////////////////////////////////*/

export const zeroStr: string = "0";

export const oneStr: string = "1";

export const ids: string[] = createStringifiedArray(BIGINT_ZERO, BigInt.fromI32(100));

export const bandIds: BigInt[] = createArray(BIGINT_ZERO, BigInt.fromI32(100));
