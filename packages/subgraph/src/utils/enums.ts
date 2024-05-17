// UnlockType represents vesting token time release
export enum UnlockType {
    DAILY,
    MONTHLY,
}
// Fixed - user gets shares inmediately, however stake is locks for that selected period
// Flexi - user earns shares over the time, but stake and be unlocked anytime
export enum StakingType {
    FIX,
    FLEXI,
}

export enum ActivityStatus {
    NOT_ACTIVATED,
    ACTIVATED,
    DEACTIVATED,
}
