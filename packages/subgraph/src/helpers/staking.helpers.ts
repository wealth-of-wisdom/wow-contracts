import { Address, BigDecimal, BigInt } from "@graphprotocol/graph-ts";
import {
    StakingContract,
    Pool,
    BandLevel,
    Staker,
    StakerRewards,
    Band,
    FundsDistribution,
} from "../../generated/schema";
import { Staking } from "../../generated/Staking/Staking";
import { ADDRESS_ZERO, BIGINT_ZERO, BIGDEC_ZERO, StakingType } from "../utils/constants";
import { stringifyStakingType } from "../utils/utils";
/**
 * Retrieves or initializes a StakingContract entity.
 * @returns The StakingContract entity.
 */
export function getOrInitStakingContract(): StakingContract {
    const id = "0";
    let stakingContract = StakingContract.load(id);

    if (!stakingContract) {
        stakingContract = new StakingContract(id);
        stakingContract.stakingContractAddress = ADDRESS_ZERO;
        stakingContract.usdtToken = ADDRESS_ZERO;
        stakingContract.usdcToken = ADDRESS_ZERO;
        stakingContract.wowToken = ADDRESS_ZERO;
        stakingContract.sharesInMonths = [];
        stakingContract.nextBandId = BIGINT_ZERO;
        stakingContract.nextDistributionId = BIGINT_ZERO;
        stakingContract.percentagePrecision = 0;
        stakingContract.totalPools = 0;
        stakingContract.totalBandLevels = 0;
        stakingContract.areUpgradesEnabled = true;
        stakingContract.stakers = [];
        stakingContract.lastSharesSyncDate = BIGINT_ZERO;
        stakingContract.totalStakedFromAllUsers = BIGINT_ZERO;

        stakingContract.save();
    }

    return stakingContract;
}

/**
 * Retrieves or initializes a Pool entity.
 * @param poolId - The pool id in the staking contract.
 * @returns The Pool entity.
 */
export function getOrInitPool(poolId: BigInt): Pool {
    const id = poolId.toString();
    let stakingPool = Pool.load(id);

    if (!stakingPool) {
        stakingPool = new Pool(id);
        stakingPool.distributionPercentage = 0;
        stakingPool.totalSharesAmount = BIGINT_ZERO;

        stakingPool.save();
    }

    return stakingPool;
}

/**
 * Retrieves or initializes a BandLevel entity.
 * @param level - The band level in the staking contract.
 * @returns The BandLevel entity.
 */
export function getOrInitBandLevel(level: BigInt): BandLevel {
    const id = level.toString();
    let bandLevel = BandLevel.load(id);

    if (!bandLevel) {
        bandLevel = new BandLevel(id);
        bandLevel.price = BIGINT_ZERO;
        bandLevel.accessiblePools = [];
        bandLevel.totalPoolShares = BIGINT_ZERO;
        bandLevel.totalBandShares = BIGINT_ZERO;

        bandLevel.save();
    }

    return bandLevel;
}

/**
 * Retrieves or initializes a Staker entity.
 * @param stakerAddress - The address of the staker.
 * @returns The Staker entity.
 */
export function getOrInitStaker(stakerAddress: Address): Staker {
    const id = stakerAddress.toHex();
    let staker = Staker.load(id);

    if (!staker) {
        const stakingContract = getOrInitStakingContract();

        staker = new Staker(id);
        staker.bands = [];
        staker.sharesPerPool = new Array<BigInt>(stakingContract.totalPools).fill(BIGINT_ZERO);
        staker.sharePercentagesPerPool = new Array<BigDecimal>(stakingContract.totalPools).fill(BIGDEC_ZERO);
        staker.totalStaked = BIGINT_ZERO;

        staker.save();
    }

    return staker;
}

/**
 * Retrieves or initializes a StakerRewards entity.
 * @param stakerAddress - The address of the staker.
 * @param tokenAddress - The address of the token.
 * @returns The StakerRewards entity.
 */
export function getOrInitStakerRewards(stakerAddress: Address, tokenAddress: Address): StakerRewards {
    const id = `${stakerAddress.toHex()}-${tokenAddress.toHex()}`;
    let stakerRewards = StakerRewards.load(id);

    if (!stakerRewards) {
        stakerRewards = new StakerRewards(id);
        stakerRewards.staker = stakerAddress.toHex();
        stakerRewards.token = tokenAddress;
        stakerRewards.unclaimedAmount = BIGINT_ZERO;
        stakerRewards.claimedAmount = BIGINT_ZERO;

        stakerRewards.save();
    }

    return stakerRewards;
}

/**
 * Retrieves or initializes unique Band entity.
 * @param bandId - The band id in the staking contract.
 * @returns The Band entity.
 */
export function getOrInitBand(bandId: BigInt): Band {
    const id = bandId.toString();
    let band = Band.load(id);

    if (!band) {
        const stakingContract = getOrInitStakingContract();
        band = new Band(id);
        band.owner = ADDRESS_ZERO.toHex();
        band.stakingStartDate = BIGINT_ZERO;
        band.bandLevel = getOrInitBandLevel(BIGINT_ZERO).id;
        band.fixedMonths = 0;
        band.stakingType = stringifyStakingType(StakingType.FIX);
        band.areTokensVested = false;
        band.sharesAmount = BIGINT_ZERO;
        band.bandSharesPercentage = BIGDEC_ZERO;
        // band.poolSharesPercentages = new Array<BigDecimal>(stakingContract.totalPools).fill(BIGDEC_ZERO);
        band.save();
    }

    return band;
}

/**
 * Retrieves or initializes a FundsDistribution entity.
 * @param id - The id of the funds distribution.
 * @returns The FundsDistribution entity.
 */
export function getOrInitFundsDistribution(distributionId: BigInt): FundsDistribution {
    const id = distributionId.toString();
    let fundsDistribution = FundsDistribution.load(id);

    if (!fundsDistribution) {
        fundsDistribution = new FundsDistribution(id);
        fundsDistribution.token = ADDRESS_ZERO;
        fundsDistribution.amount = BIGINT_ZERO;
        fundsDistribution.createdAt = BIGINT_ZERO;
        fundsDistribution.distributedAt = BIGINT_ZERO;
        fundsDistribution.stakers = [];
        fundsDistribution.rewards = [];

        fundsDistribution.save();
    }

    return fundsDistribution;
}
