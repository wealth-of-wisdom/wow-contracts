import { BigInt } from "@graphprotocol/graph-ts";
import { BIGINT_ZERO } from "../../../src/utils/constants";
import { createArrayWithMultiplicationAndAddition } from "../arrays";

/*//////////////////////////////////////////////////////////////////////////
                                  DATES
//////////////////////////////////////////////////////////////////////////*/

export const monthInSeconds: BigInt = BigInt.fromI32(30 * 24 * 60 * 60);

export const preInitDate: BigInt = BigInt.fromI32(1000000000); // Sun Sep 09, 2001 1:46:40 AM
export const initDate: BigInt = BigInt.fromI32(1710000000); // Sat Mar 09 2024 16:00:00 GMT+0000

export const monthsAfterInit: BigInt[] = createArrayWithMultiplicationAndAddition(
    BIGINT_ZERO,
    BigInt.fromI32(25),
    monthInSeconds,
    initDate,
);
