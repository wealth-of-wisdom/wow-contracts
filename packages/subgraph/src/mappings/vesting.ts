import {
    BeneficiaryAdded as BeneficiaryAddedEvent,
    BeneficiaryRemoved as BeneficiaryRemovedEvent,
    ContractTokensWithdrawn as ContractTokensWithdrawnEvent,
    Initialized as InitializedEvent,
    ListingDateChanged as ListingDateChangedEvent,
    StakedTokensUpdated as StakedTokensUpdatedEvent,
    StakingContractSet as StakingContractSetEvent,
    TokensClaimed as TokensClaimedEvent,
    Vesting,
    VestingPoolAdded as VestingPoolAddedEvent
} from "../../generated/Vesting/Vesting"
import {
    VestingContract,
    VestingPool,
    Beneficiary,
} from "../../generated/schema"
import { getOrInitBeneficiaries, getOrInitVestingContract, getOrInitVestingPool } from "../helpers/vesting.helpers"
import { getUnlockFromI32, getUnlockType } from "../utils/utils";
import { BigInt, store } from "@graphprotocol/graph-ts";

// Initialize Vesting contract
export function handleInitialized(event: InitializedEvent): void {

    const vestingContract: VestingContract = getOrInitVestingContract(event.address);

    vestingContract.save();
}

export function handleVestingPoolAdded(event: VestingPoolAddedEvent): void {

    const vestingPool: VestingPool = getOrInitVestingPool(event.address, new BigInt(event.params.poolIndex));

    const vestingContract = Vesting.bind(event.address)


    const poolGeneralData = vestingContract.getGeneralPoolData(event.params.poolIndex);
    const poolVestingData = vestingContract.getPoolVestingData(event.params.poolIndex);
    const poolListingData = vestingContract.getPoolListingData(event.params.poolIndex);
    const poolCliffData = vestingContract.getPoolCliffData(event.params.poolIndex);

    // General data structure
    //     - pool.name,
    //     - pool.unlockType,
    //     - pool.totalPoolTokenAmount,
    //     - pool.dedicatedPoolTokenAmount
    const poolName: string = poolGeneralData.value0;
    const unlockType = poolGeneralData.value1;
    const totalPoolTokenAmount: BigInt = poolGeneralData.value2;
    const dedicatedPoolTokenAmount: BigInt = poolGeneralData.value3;

    // Vesting data structure:
    //     - pool.vestingEndDate
    //     - pool.vestingDurationInMonths,
    //     - pool.vestingDurationInDays,   
    const vestingEndDate: BigInt = poolVestingData.value0;
    // const vestingDurationInMonths: BigInt = poolVestingData.value1;
    const vestingDurationInDays: BigInt = new BigInt(poolVestingData.value2);

    // Listing data structure:
    //     - pool.listingPercentageDividend
    //     - pool.listingPercentageDivisor,
    const listingPercentageDividend: BigInt = new BigInt(poolListingData.value0);
    const listingPercentageDivisor: BigInt = new BigInt(poolListingData.value1);

    // Cliff data structure:
    //     - pool.cliffEndDate
    //     - pool.cliffInDays,
    //     - pool.cliffPercentageDividend
    //     - pool.cliffPercentageDivisor,    
    const cliffEndDate: BigInt = poolCliffData.value0;
    const cliffInDays: BigInt = new BigInt(poolCliffData.value1);
    const cliffPercentageDividend: BigInt = new BigInt(poolCliffData.value2);
    const cliffPercentageDivisor: BigInt = new BigInt(poolCliffData.value3);



    vestingPool.poolId = new BigInt(event.params.poolIndex);

    vestingPool.name = poolName
    vestingPool.unlockType = getUnlockType(getUnlockFromI32(new BigInt(unlockType)));
    vestingPool.totalPoolTokenAmount = totalPoolTokenAmount;
    vestingPool.dedicatedPoolTokens = dedicatedPoolTokenAmount;

    // TODO: need to figure out how to calcualte listing Percentage from those two variables:
    // listingPercentageDividend and listingPercentageDivisor
    vestingPool.listingPercentage = listingPercentageDividend;


    vestingPool.cliffDuration = cliffInDays;
    vestingPool.cliffEndDate = cliffEndDate;
    // TODO: need to figure out how to calcualte cliff Percentage from those two variables:
    // cliffPercentageDividend and cliffPercentageDivisor
    vestingPool.cliffPercentage = cliffPercentageDividend;
    vestingPool.vestingDuration = vestingDurationInDays;
    vestingPool.vestingEndDate = vestingEndDate;

    vestingPool.dedicatedPoolTokens = event.params.totalPoolTokenAmount


    vestingPool.save()
}


export function handleBeneficiaryAdded(event: BeneficiaryAddedEvent): void {
    const beneficiary: Beneficiary = getOrInitBeneficiaries(event.address, event.params.beneficiary, new BigInt(event.params.poolIndex));

    beneficiary.address = event.params.beneficiary;
    beneficiary.vestingPool = event.params.poolIndex.toString();
    // NOTE / FIX : total amounts is the tokens are allocated to the person, but i can be done more than once
    beneficiary.totalTokens = beneficiary.totalTokens.plus(event.params.addedTokenAmount);

    beneficiary.save();

}

export function handleBeneficiaryRemoved(event: BeneficiaryRemovedEvent): void {
    const beneficiary: Beneficiary = getOrInitBeneficiaries(event.address, event.params.beneficiary, new BigInt(event.params.poolIndex));

    // TODO: Not sure if this how it supposed to look like
    store.remove("Beneficiary", beneficiary.id)

    beneficiary.save()
}

// @notice Admin Transfers tokens to the selected recipient.
export function handleContractTokensWithdrawn(
    event: ContractTokensWithdrawnEvent
): void {
    // TODO: Not a priority right now

}



export function handleListingDateChanged(event: ListingDateChangedEvent): void {
    // 
    const vestingContract: VestingContract = getOrInitVestingContract(event.address);

    vestingContract.listingDate = event.params.newDate

    vestingContract.save()
}


export function handleStakedTokensUpdated(
    event: StakedTokensUpdatedEvent
): void {
    // NEEDED: Reikia kad idetu:
    // emit StakedTokensUpdated(pid, tokenAmount, startStaking); ir beneficiary
    const beneficiary: Beneficiary = getOrInitBeneficiaries(event.address, event.transaction.from, new BigInt(event.params.poolIndex));

    if (event.params.stake === true) {
        beneficiary.stakedTokens = beneficiary.stakedTokens.plus(event.params.amount);
    } else if (event.params.stake === false) {
        beneficiary.stakedTokens = beneficiary.stakedTokens.minus(event.params.amount);
    }

    beneficiary.save();
}

export function handleStakingContractSet(event: StakingContractSetEvent): void {
    const vestingContract: VestingContract = getOrInitVestingContract(event.address);

    // TODO: double check when it's called in SC
    vestingContract.stakingContractAddress = event.params.newContract;

    vestingContract.save();
}

export function handleTokensClaimed(event: TokensClaimedEvent): void {
    const beneficiary: Beneficiary = getOrInitBeneficiaries(event.address, event.params.user, new BigInt(event.params.poolIndex));

    // count claimed amount
    beneficiary.claimedTokens = beneficiary.claimedTokens.plus(event.params.tokenAmount);

    // remove vested tokens because they are claimed
    beneficiary.vestedTokens = beneficiary.vestedTokens.minus(event.params.tokenAmount);

    // I think also needed total tokens that are claimed removed from total tokens (not sure about that)
    beneficiary.save();
}


