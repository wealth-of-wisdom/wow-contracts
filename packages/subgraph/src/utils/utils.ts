import { BigInt } from "@graphprotocol/graph-ts";
import { UnlockType } from "../helpers/vesting.helpers";


export const getUnlockFromI32 = (unlockType: BigInt): UnlockType => {
    if (unlockType.equals(BigInt.fromI32(0))) {
        return UnlockType.DAILY;
    } else if (unlockType.equals(BigInt.fromI32(1))) {
        return UnlockType.MONTHLY;
    } else {
        throw new Error("Invalid number");
    }
};

export const getUnlockType = (type: UnlockType): string => {
    switch (type) {
        case UnlockType.DAILY:
            return "DAILY";
        case UnlockType.MONTHLY:
            return "MONTHLY";
        default:
            throw new Error("Invalid unlock type type");
    }
};