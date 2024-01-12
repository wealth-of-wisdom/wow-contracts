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
import { getUnlockTypeFromBigInt, stringifyUnlockType } from "../utils/utils";
import { BigInt, store } from "@graphprotocol/graph-ts";

// Initialize Vesting contract
export function handleInitialized(event: InitializedEvent): void {

    const vestingContract: VestingContract = getOrInitVestingContract(event.address);

    vestingContract.save();
}

export function handleVestingPoolAdded(event: VestingPoolAddedEvent): void {
    const vestingContract = Vesting.bind(event.address);
    const poolIndex = BigInt.fromI32(event.params.poolIndex);
  
    const vestingPool = getOrInitVestingPool(event.address, poolIndex);
  
    // Fetch data from Vesting contract
    const generalData = vestingContract.getGeneralPoolData(event.params.poolIndex);
    const vestingData = vestingContract.getPoolVestingData(event.params.poolIndex);
    const listingData = vestingContract.getPoolListingData(event.params.poolIndex);
    const cliffData = vestingContract.getPoolCliffData(event.params.poolIndex);
  
    // Getting data from Vesting contract getters
    const poolName = generalData.value0;
    const unlockType = generalData.value1;
    const totalPoolTokenAmount = generalData.value2;
    const dedicatedPoolTokenAmount = generalData.value3;
  
    const vestingEndDate = vestingData.value0;
    const vestingDurationInDays = BigInt.fromI32(vestingData.value2);
  
    const listingPercentageDividend = BigInt.fromI32(listingData.value0);
    const listingPercentageDivisor = BigInt.fromI32(listingData.value1);
  
    const cliffEndDate = cliffData.value0;
    const cliffInDays = BigInt.fromI32(cliffData.value1);
    const cliffPercentageDividend = BigInt.fromI32(cliffData.value2);
    const cliffPercentageDivisor = BigInt.fromI32(cliffData.value3);
  
    // Update VestingPool entity properties
    vestingPool.poolId = poolIndex;
    vestingPool.name = poolName;
    vestingPool.unlockType = stringifyUnlockType(getUnlockTypeFromBigInt(BigInt.fromI32(unlockType)));
    vestingPool.totalPoolTokenAmount = totalPoolTokenAmount;
    vestingPool.dedicatedPoolTokens = dedicatedPoolTokenAmount;
    vestingPool.listingPercentageDividend = listingPercentageDividend;
    vestingPool.listingPercentageDivisor = listingPercentageDivisor;
    vestingPool.cliffDuration = cliffInDays;
    vestingPool.cliffEndDate = cliffEndDate;
    vestingPool.cliffPercentageDividend = cliffPercentageDividend;
    vestingPool.cliffPercentageDivisor = cliffPercentageDivisor;
    vestingPool.vestingDuration = vestingDurationInDays;
    vestingPool.vestingEndDate = vestingEndDate;
  
    
    vestingPool.save();
  }


export function handleBeneficiaryAdded(event: BeneficiaryAddedEvent): void {
    const beneficiary: Beneficiary = getOrInitBeneficiaries(event.address, event.params.beneficiary, BigInt.fromI32(event.params.poolIndex));

    beneficiary.address = event.params.beneficiary;
    beneficiary.vestingPool = event.params.poolIndex.toString();
    // NOTE / FIX : total amounts is the tokens are allocated to the person, but i can be done more than once
    beneficiary.totalTokens = beneficiary.totalTokens.plus(event.params.addedTokenAmount);

    beneficiary.save();

}

export function handleBeneficiaryRemoved(event: BeneficiaryRemovedEvent): void {
    const beneficiary: Beneficiary = getOrInitBeneficiaries(event.address, event.params.beneficiary, BigInt.fromI32(event.params.poolIndex));

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

    const vestingContract: VestingContract = getOrInitVestingContract(event.address);

    vestingContract.listingDate = event.params.newDate

    vestingContract.save()
}


export function handleStakedTokensUpdated(
    event: StakedTokensUpdatedEvent
): void {

    const stake = event.params.stake;
    const amount = event.params.amount;

    // TODO: after the contract update change `event.transaction.from` to `event.params.beneficiary`
    const beneficiary: Beneficiary = getOrInitBeneficiaries(event.address, event.transaction.from, BigInt.fromI32(event.params.poolIndex));

    
    if (stake === true) {
        beneficiary.stakedTokens = beneficiary.stakedTokens.plus(amount);
    } else if (stake === false) {
        beneficiary.stakedTokens = beneficiary.stakedTokens.minus(amount);
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
    const beneficiary: Beneficiary = getOrInitBeneficiaries(event.address, event.params.user, BigInt.fromI32(event.params.poolIndex));

    // count claimed amount
    beneficiary.claimedTokens = beneficiary.claimedTokens.plus(event.params.tokenAmount);

    // remove vested tokens because they are claimed
    beneficiary.vestedTokens = beneficiary.vestedTokens.minus(event.params.tokenAmount);

    // I think also needed total tokens that are claimed removed from total tokens (not sure about that)
    beneficiary.save();
}


