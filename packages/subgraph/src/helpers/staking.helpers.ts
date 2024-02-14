import { Address, BigInt, log, Bytes } from "@graphprotocol/graph-ts";
import { BIGINT_ZERO, StakingType } from "../utils/constants";
import {
    StakingContract,
    Pool,
    Band,
    FundDistribution,
} from "../../generated/schema"
import { stringifyStakingType } from "../utils/utils";


/**
 * Retrieves or initializes a StakingContract entity.
 * @param stakingContractAddress - The address of the stakingContractAddress.
 * @returns The StakingContract entity.
 */
export function getOrInitStakingContract(stakingContractAddress: Address): StakingContract {

    //  @note: redundant ID and vesting contract address.
    let stakingContractId = "0";
    let stakingContract = StakingContract.load(stakingContractId);

    if (!stakingContract) {

        stakingContract = new StakingContract(stakingContractId);

        // set default Vesting contract entity values
        stakingContract.id = "0";
        stakingContract.stakingContractAddress = stakingContractAddress;
        stakingContract.totalPools = BIGINT_ZERO;
        stakingContract.totalBands = BIGINT_ZERO;

        stakingContract.save();
    }

    return stakingContract;
}


export function getOrInitPool(poolId: BigInt): Pool {
    
    let stakingPoolId = poolId.toString();
    let stakingPool = Pool.load(stakingPoolId);

    if (!stakingPool) {

        stakingPool = new Pool(stakingPoolId);

        // set default Vesting contract entity values
        stakingPool.id = stakingPoolId;
        stakingPool.distributionPercentage = BIGINT_ZERO;
        stakingPool.usdtTokenAmount = BIGINT_ZERO;
        stakingPool.usdcTokenAmount = BIGINT_ZERO;
 
        stakingPool.save();
    }

    return stakingPool;
}

export function getOrInitBand(bandId: BigInt): Band {
    
    let stakingBandId = bandId.toString();
    let stakingBand = Band.load(stakingBandId);

    if (!stakingBand) {

        stakingBand = new Band(stakingBandId);

        stakingBand.id = stakingBandId;
        stakingBand.stakingType = stringifyStakingType(StakingType.FIX);
        stakingBand.bandLevel = BIGINT_ZERO;
        stakingBand.price = BIGINT_ZERO;
        stakingBand.owner = Address.empty();
        stakingBand.startingSharesAmount = BIGINT_ZERO;
        stakingBand.stakingStartTimestamp = BIGINT_ZERO;
        stakingBand.claimableRewardsAmount = BIGINT_ZERO;
        stakingBand.usdtRewardsClaimed = BIGINT_ZERO;
        stakingBand.usdcRewardsClaimed = BIGINT_ZERO;
 
        stakingBand.save();
    }

    return stakingBand;
}

export function getOrInitFundDistribution(fundDistributionID: Bytes): FundDistribution {
    
    let fundDistributionId = fundDistributionID.toHex();
    let fundDistribution = FundDistribution.load(fundDistributionId);

    if (!fundDistribution) {

        fundDistribution = new FundDistribution(fundDistributionId);

        fundDistribution.id = fundDistributionId;
        fundDistribution.token = Address.empty();
        fundDistribution.amount = BIGINT_ZERO;
        fundDistribution.timestamp = BIGINT_ZERO;
        
        fundDistribution.save();
    }

    return fundDistribution;
}
