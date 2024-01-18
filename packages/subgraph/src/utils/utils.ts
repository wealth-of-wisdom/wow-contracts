import { BigInt } from "@graphprotocol/graph-ts";
import { BIGINT_ONE, BIGINT_ZERO, UnlockType } from "./constants";



  /**
   * Converts a BigInt unlock type to UnlockType enum.
   * @param unlockType - BigInt representing the unlock type.
   * @returns Corresponding UnlockType enum value.
   * @throws Error if the input is not a valid unlock type.
   */
  export const getUnlockTypeFromBigInt = (unlockType: BigInt): UnlockType => {
    if (unlockType.equals(BIGINT_ZERO)) {
      return UnlockType.DAILY;
    } else if (unlockType.equals(BIGINT_ONE)) {
      return UnlockType.MONTHLY;
    } else {
      throw new Error("Invalid unlock type value");
    }
  };
  
  /**
   * Converts an UnlockType enum value to its string representation.
   * @param type - UnlockType enum value.
   * @returns String representation of the unlock type.
   * @throws Error if the input is not a valid unlock type.
   */
  export const stringifyUnlockType = (type: UnlockType): string => {
    switch (type) {
      case UnlockType.DAILY:
        return "DAILY";
      case UnlockType.MONTHLY:
        return "MONTHLY";
      default:
        throw new Error("Invalid unlock type");
    }
  };