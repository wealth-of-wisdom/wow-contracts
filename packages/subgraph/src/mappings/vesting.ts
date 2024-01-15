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
    Beneficiary,
    VestingPool,
} from "../../generated/schema"
import { getOrInitBeneficiaries, getOrInitVestingContract, getOrInitVestingPool } from "../helpers/vesting.helpers"
import { getUnlockTypeFromBigInt, stringifyUnlockType } from "../utils/utils";
import { BigInt, store } from "@graphprotocol/graph-ts";


/**
 * Handles the Initialized event triggered when the contract is initialized.
 * @param event - The InitializedEvent containing the contract address.
 */
export function handleInitialized(event: InitializedEvent): void {

    const vestingContract: VestingContract = getOrInitVestingContract(event.address);

    vestingContract.save();
}


/**
 * Handles the VestingPoolAdded event triggered when a new vesting pool is added.
 * @param event - The VestingPoolAddedEvent containing the contract address and new pool index.
 */
export function handleVestingPoolAdded(event: VestingPoolAddedEvent): void {
    const vestingContract: Vesting = Vesting.bind(event.address);
    const poolIndex: BigInt = BigInt.fromI32(event.params.poolIndex);
  
    const vestingPool: VestingPool = getOrInitVestingPool(event.address, poolIndex);
  
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
    // TotalPoolTokens is the total number of tokens that are allocated for each pool
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

/**
 * Handles the BeneficiaryAdded event triggered when a new beneficiary is added to a pool.
 * @param event - The BeneficiaryAddedEvent containing beneficiary, pool, and token amount details.
 */
export function handleBeneficiaryAdded(event: BeneficiaryAddedEvent): void {
    const beneficiary: Beneficiary = getOrInitBeneficiaries(event.address, event.params.beneficiary, BigInt.fromI32(event.params.poolIndex));

    beneficiary.address = event.params.beneficiary;
    beneficiary.vestingPool = event.params.poolIndex.toString();

    const vestingContract: Vesting = Vesting.bind(event.address);

    const beneficiaryData = vestingContract.getBeneficiary(event.params.poolIndex, event.params.beneficiary);

    const structBeneficiary = beneficiaryData.values()


    // @note total amounts is the tokens are allocated to the person, but i can be done more than once
    beneficiary.totalTokens = beneficiary.totalTokens.plus(event.params.addedTokenAmount);

    beneficiary.save();

}


/**
 * Handles the BeneficiaryRemoved event triggered when a beneficiary is removed from a pool.
 * @param event - The BeneficiaryRemovedEvent containing beneficiary and pool details.
 */
export function handleBeneficiaryRemoved(event: BeneficiaryRemovedEvent): void {
    const beneficiary: Beneficiary = getOrInitBeneficiaries(event.address, event.params.beneficiary, BigInt.fromI32(event.params.poolIndex));

    // @note Not sure if this how it supposed to look like
    store.remove("Beneficiary", beneficiary.id)

    beneficiary.save()
}

/**
 * Handles the ContractTokensWithdrawn event triggered when tokens are withdrawn from the contract.
 * @param event - The ContractTokensWithdrawnEvent (No specific data for now).
 * @notice - this event triggered when admin decides to withdraw tokens that randomly put into the contract (not WOW tokens)
 */
export function handleContractTokensWithdrawn(
    event: ContractTokensWithdrawnEvent
): void {
    // TODO: Not a priority right now
}


/**
 * Handles the ListingDateChanged event triggered when the listing date of the contract is changed.
 * @param event - The ListingDateChangedEvent containing the new listing date.
 */
export function handleListingDateChanged(event: ListingDateChangedEvent): void {

    const vestingContract: VestingContract = getOrInitVestingContract(event.address);

    vestingContract.listingDate = event.params.newDate

    vestingContract.save()
}

/**
 * Handles the StakedTokensUpdated event triggered when staked tokens are updated.
 * @param event - The StakedTokensUpdatedEvent containing stake status, amount, beneficiary, and pool details.
 */
export function handleStakedTokensUpdated(event: StakedTokensUpdatedEvent): void {
    

    const isStake: boolean = event.params.stake;
    const amount: BigInt = event.params.amount;
    const poolIndex: BigInt = BigInt.fromI32(event.params.poolIndex);

 
    const beneficiary: Beneficiary = getOrInitBeneficiaries(event.address, event.params.beneficiary, poolIndex);

    // Update staked tokens based on the stake status
    beneficiary.stakedTokens = isStake
        ? beneficiary.stakedTokens.plus(amount)
        : beneficiary.stakedTokens.minus(amount);

    // Save the updated Beneficiary entity
    beneficiary.save();
}

/**
 * Handles the StakingContractSet event triggered when the staking contract address is set.
 * @param event - The StakingContractSetEvent containing the new staking contract address.
 */
export function handleStakingContractSet(event: StakingContractSetEvent): void {
    const vestingContract: VestingContract = getOrInitVestingContract(event.address);

    vestingContract.stakingContractAddress = event.params.newContract;

    vestingContract.save();
}


/**
 * Handles the TokensClaimed event triggered when tokens are claimed by a beneficiary.
 * @param event - The TokensClaimedEvent containing beneficiary, pool, and claimed token amount details.
 */
export function handleTokensClaimed(event: TokensClaimedEvent): void {
    const beneficiary: Beneficiary = getOrInitBeneficiaries(event.address, event.params.user, BigInt.fromI32(event.params.poolIndex));

    // sum claimed amount
    beneficiary.claimedTokens = beneficiary.claimedTokens.plus(event.params.tokenAmount);

    // remove vested tokens because they are claimed
    beneficiary.vestedTokens = beneficiary.vestedTokens.minus(event.params.tokenAmount);

    // @note I think also needed total tokens that are claimed removed from total tokens (not sure about that)
    beneficiary.save();
}


