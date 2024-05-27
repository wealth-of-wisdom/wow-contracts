import { BigInt } from "@graphprotocol/graph-ts";

export class StakerAndPoolShares {
    constructor(
        public stakers: string[],
        public sharesForStakers: BigInt[][],
        public sharesForPools: BigInt[],
    ) {}
}

export class StakerShares {
    constructor(
        public sharesPerPool: BigInt[],
        public isolatedSharesPerPool: BigInt[],
    ) {}
}
