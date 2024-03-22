import { BigInt } from "@graphprotocol/graph-ts";
import { BIGINT_ONE } from "../../src/utils/constants";

/*//////////////////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

// In assemblyscript we cannot use Array.from() function

export function createArray(start: BigInt, end: BigInt): BigInt[] {
    const size = end.minus(start).plus(BIGINT_ONE);
    const arr = new Array<BigInt>(size.toI32());

    for (let i = 0; i < size.toI32(); i++) {
        arr[i] = start.plus(BigInt.fromI32(i));
    }

    return arr;
}

export function createArrayWithMultiplication(start: BigInt, end: BigInt, multiplier: BigInt): BigInt[] {
    const size = end.minus(start).plus(BIGINT_ONE);
    const arr = new Array<BigInt>(size.toI32());

    for (let i = 0; i < size.toI32(); i++) {
        arr[i] = start.plus(BigInt.fromI32(i)).times(multiplier);
    }

    return arr;
}

export function createDoubleArray(start: BigInt, end: BigInt): BigInt[][] {
    const size = end.minus(start).plus(BIGINT_ONE);
    const arr = new Array<BigInt[]>(size.toI32());

    for (let i = 0; i < size.toI32(); i++) {
        arr[i] = createArray(start, start.plus(BigInt.fromI32(i)));
    }

    return arr;
}

export function createStringifiedArray(start: BigInt, end: BigInt): string[] {
    const size = end.minus(start).plus(BIGINT_ONE);
    const arr = new Array<string>(size.toI32());

    for (let i = 0; i < size.toI32(); i++) {
        arr[i] = start.plus(BigInt.fromI32(i)).toString();
    }

    return arr;
}

export function convertBigIntArrayToString(arr: BigInt[]): string {
    let numbers = arr.toString().split(",").join(", ");
    return `[${numbers}]`;
}
