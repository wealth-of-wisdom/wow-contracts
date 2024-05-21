import { UnlockType, StakingType, ActivityStatus } from "./enums";

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

/**
 * Converts an StakingType enum value to its string representation.
 * @param type - StakingType enum value.
 * @returns String representation of the stake type.
 * @throws Error if the input is not a valid stake type.
 */
export const stringifyStakingType = (type: StakingType): string => {
    switch (type) {
        case StakingType.FIX:
            return "FIX";
        case StakingType.FLEXI:
            return "FLEXI";
        default:
            throw new Error("Invalid staking type");
    }
};

/**
 * Converts an ActivityStatus enum value to its string representation.
 * @param type - ActivityStatus enum value.
 * @returns String representation of the activity status.
 * @throws Error if the input is not a valid activity status.
 */
export const stringifyActivityStatus = (type: ActivityStatus): string => {
    switch (type) {
        case ActivityStatus.DEACTIVATED:
            return "DEACTIVATED";
        case ActivityStatus.NOT_ACTIVATED:
            return "NOT_ACTIVATED";
        case ActivityStatus.ACTIVATED:
            return "ACTIVATED";
        default:
            throw new Error("Invalid activity status");
    }
};
