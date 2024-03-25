import { Address, BigInt, store } from "@graphprotocol/graph-ts";
import {
    StakingContract,
    Pool,
    BandLevel,
    Staker,
    StakerRewards,
    Band,
    FundsDistribution,
} from "../../generated/schema";
import { ADDRESS_ZERO, BIGINT_ZERO } from "../utils/constants";
import { stakingTypeFIX } from "../utils/utils";

/*//////////////////////////////////////////////////////////////////////////
                            GET OR INIT FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

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
        stakingContract.areUpgradesEnabled = false;
        stakingContract.isDistributionInProgress = false;
        stakingContract.stakers = [];
        stakingContract.lastSharesSyncDate = BIGINT_ZERO;
        stakingContract.totalStakedAmount = BIGINT_ZERO;

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
        stakingPool.totalFixedSharesAmount = BIGINT_ZERO;
        stakingPool.totalFlexiSharesAmount = BIGINT_ZERO;
        stakingPool.isolatedFixedSharesAmount = BIGINT_ZERO;
        stakingPool.isolatedFlexiSharesAmount = BIGINT_ZERO;

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
        staker.fixedBands = [];
        staker.flexiBands = [];
        staker.bandsCount = 0;
        staker.stakedAmount = BIGINT_ZERO;
        staker.fixedSharesPerPool = new Array<BigInt>(stakingContract.totalPools).fill(BIGINT_ZERO);
        staker.flexiSharesPerPool = new Array<BigInt>(stakingContract.totalPools).fill(BIGINT_ZERO);
        staker.isolatedFixedSharesPerPool = new Array<BigInt>(stakingContract.totalPools).fill(BIGINT_ZERO);
        staker.isolatedFlexiSharesPerPool = new Array<BigInt>(stakingContract.totalPools).fill(BIGINT_ZERO);
        staker.totalUnclaimedRewards = BIGINT_ZERO;
        staker.totalClaimedRewards = BIGINT_ZERO;

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
        band = new Band(id);
        band.owner = ADDRESS_ZERO.toHex();
        band.stakingStartDate = BIGINT_ZERO;
        band.bandLevel = getOrInitBandLevel(BIGINT_ZERO).id;
        band.fixedMonths = 0;
        band.stakingType = stakingTypeFIX;
        band.areTokensVested = false;
        band.sharesAmount = BIGINT_ZERO;
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

/*//////////////////////////////////////////////////////////////////////////
                                OTHER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// @notice This function does not save the stakingContract entity.
export function addStakerToStakingContract(stakingContract: StakingContract, staker: Staker): void {
    // If staker has no bands, it means staker is not added to all stakers array
    if (staker.bandsCount == 0) {
        // Add staker to all stakers array
        const stakerIds = stakingContract.stakers;
        stakerIds.push(staker.id);

        stakingContract.stakers = stakerIds;
    }
}

export function removeStakerFromStakingContract(stakingContract: StakingContract, staker: Staker): void {
    const stakersIds: string[] = stakingContract.stakers;
    const stakersAmount = stakersIds.length;

    // Remove staker from all stakers array and staker itself
    for (let i = 0; i < stakersAmount; i++) {
        if (stakersIds[i] == staker.id) {
            // Swap last element with the one to be removed
            // And then remove the last element
            stakersIds[i] = stakersIds[stakersAmount - 1];
            stakersIds.pop();

            // Update stakers array in staking contract
            stakingContract.stakers = stakersIds;
            stakingContract.save();

            // Remove staker and band
            store.remove("Staker", staker.id);

            break;
        }
    }
}

/// @notice This function does not save the staker entity.
export function addBandToStakerBands(staker: Staker, band: Band): void {
    // Update array corresponding to the staking type of the band
    if (band.stakingType == stakingTypeFIX) {
        const fixedBands = staker.fixedBands;
        fixedBands.push(band.id);

        staker.fixedBands = fixedBands;
    } else {
        const flexiBands = staker.flexiBands;
        flexiBands.push(band.id);

        staker.flexiBands = flexiBands;
    }
}

export function removeBandFromStakerBands(staker: Staker, band: Band, stakedAmount: BigInt): void {
    const stakerBandIds: string[] = band.stakingType == stakingTypeFIX ? staker.fixedBands : staker.flexiBands;
    const bandsCount = stakerBandIds.length;

    for (let i = 0; i < bandsCount; i++) {
        if (stakerBandIds[i] == band.id) {
            // Swap last element with the one to be removed
            // And then remove the last element
            // Use stakerBandIds.length instead of bandsAmount to avoid type error
            stakerBandIds[i] = stakerBandIds[bandsCount - 1];
            stakerBandIds.pop();

            if (band.stakingType == stakingTypeFIX) {
                staker.fixedBands = stakerBandIds;
            } else {
                staker.flexiBands = stakerBandIds;
            }

            staker.stakedAmount = staker.stakedAmount.minus(stakedAmount);
            staker.save();

            break;
        }
    }
}

export function removeAllBands(staker: Staker): void {
    const fixedBands: string[] = staker.fixedBands;
    const fixedBandsCount: number = fixedBands.length;

    // Remove fixed bands
    for (let i = 0; i < fixedBandsCount; i++) {
        const band: Band = getOrInitBand(BigInt.fromString(fixedBands[i]));
        store.remove("Band", band.id);
    }

    const flexiBands: string[] = staker.flexiBands;
    const flexiBandsCount: number = flexiBands.length;

    // Remove flexi bands
    for (let i = 0; i < flexiBandsCount; i++) {
        const band: Band = getOrInitBand(BigInt.fromString(flexiBands[i]));
        store.remove("Band", band.id);
    }
}

export function removeAllStakerRewards(stakingContract: StakingContract, staker: Staker): void {
    const stakerAddress: Address = Address.fromString(staker.id);

    // Remove USDT rewards
    const usdtToken: Address = Address.fromBytes(stakingContract.usdtToken);
    const usdtRewards: StakerRewards = getOrInitStakerRewards(stakerAddress, usdtToken);
    store.remove("StakerRewards", usdtRewards.id);

    // Remove USDC rewards
    const usdcToken: Address = Address.fromBytes(stakingContract.usdcToken);
    const usdcRewards: StakerRewards = getOrInitStakerRewards(stakerAddress, usdcToken);
    store.remove("StakerRewards", usdcRewards.id);
}

export function changeBandLevel(stakerAddress: Address, bandId: BigInt, oldBandLvl: BigInt, newBandLvl: BigInt): void {
    const oldBandLevel: BandLevel = getOrInitBandLevel(oldBandLvl);
    const newBandLevel: BandLevel = getOrInitBandLevel(newBandLvl);

    // Update total staked amount in the contract
    const stakingContract: StakingContract = getOrInitStakingContract();
    stakingContract.totalStakedAmount = stakingContract.totalStakedAmount
        .minus(oldBandLevel.price)
        .plus(newBandLevel.price);
    stakingContract.save();

    // Update staker staked amount
    const staker: Staker = getOrInitStaker(stakerAddress);
    staker.stakedAmount = staker.stakedAmount.minus(oldBandLevel.price).plus(newBandLevel.price);
    staker.save();

    const band: Band = getOrInitBand(bandId);
    band.bandLevel = newBandLevel.id;
    band.save();
}
