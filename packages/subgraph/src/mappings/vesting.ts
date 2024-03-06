import {
    BeneficiaryAdded as BeneficiaryAddedEvent,
    BeneficiaryRemoved as BeneficiaryRemovedEvent,
    ContractTokensWithdrawn as ContractTokensWithdrawnEvent,
    Initialized as InitializedEvent,
    ListingDateChanged as ListingDateChangedEvent,
    StakingContractSet as StakingContractSetEvent,
    TokensClaimed as TokensClaimedEvent,
    VestedTokensStaked as VestedTokensStakedEvent,
    VestedTokensUnstaked as VestedTokensUnstakedEvent,
    Vesting,
    VestingPoolAdded as VestingPoolAddedEvent,
} from "../../generated/Vesting/Vesting";
import { VestingContract, Beneficiary, VestingPool } from "../../generated/schema";
import { getOrInitBeneficiaries, getOrInitVestingContract, getOrInitVestingPool } from "../helpers/vesting.helpers";
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
    const beneficiary: Beneficiary = getOrInitBeneficiaries(
        event.address,
        event.params.beneficiary,
        BigInt.fromI32(event.params.poolIndex),
    );

    beneficiary.address = event.params.beneficiary;
    beneficiary.vestingPool = event.params.poolIndex.toString();

    const vestingContract: Vesting = Vesting.bind(event.address);

    const beneficiaryData = vestingContract.getBeneficiary(event.params.poolIndex, event.params.beneficiary);

    // Updated user data
    beneficiary.totalTokens = beneficiaryData.totalTokenAmount;
    beneficiary.listingTokens = beneficiaryData.listingTokenAmount;
    beneficiary.cliffTokens = beneficiaryData.cliffTokenAmount;
    beneficiary.vestedTokens = beneficiaryData.vestedTokenAmount;
    beneficiary.stakedTokens = beneficiaryData.stakedTokenAmount;
    beneficiary.claimedTokens = beneficiaryData.claimedTokenAmount;

    beneficiary.save();
}

/**
 * Handles the BeneficiaryRemoved event triggered when a beneficiary is removed from a pool.
 * @param event - The BeneficiaryRemovedEvent containing beneficiary and pool details.
 */
export function handleBeneficiaryRemoved(event: BeneficiaryRemovedEvent): void {
    const beneficiary: Beneficiary = getOrInitBeneficiaries(
        event.address,
        event.params.beneficiary,
        BigInt.fromI32(event.params.poolIndex),
    );

    // @note Not sure if this how it supposed to look like
    store.remove("Beneficiary", beneficiary.id);

    beneficiary.save();
}

/**
 * Handles the ContractTokensWithdrawn event triggered when tokens are withdrawn from the contract.
 * @param event - The ContractTokensWithdrawnEvent (No specific data for now).
 * @notice - this event triggered when admin decides to withdraw tokens that randomly put into the contract (not WOW tokens)
 */
export function handleContractTokensWithdrawn(event: ContractTokensWithdrawnEvent): void {
    // No state is changed in contracts
}

/**
 * Handles the ListingDateChanged event triggered when the listing date of the contract is changed.
 * @param event - The ListingDateChangedEvent containing the new listing date.
 */
export function handleListingDateChanged(event: ListingDateChangedEvent): void {
    const vestingContract: VestingContract = getOrInitVestingContract(event.address);

    vestingContract.listingDate = event.params.newDate;

    vestingContract.save();
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
    const vestingContract: Vesting = Vesting.bind(event.address);
    const beneficiary: Beneficiary = getOrInitBeneficiaries(
        event.address,
        event.params.user,
        BigInt.fromI32(event.params.poolIndex),
    );

    // sum claimed amount
    beneficiary.claimedTokens = beneficiary.claimedTokens.plus(event.params.tokenAmount);

    // @note I think also needed total tokens that are claimed removed from total tokens (not sure about that)
    // beneficiary.totalTokens = beneficiary.totalTokens.minus(beneficiary.claimedTokens);

    beneficiary.save();
}

/**
 * Handles the VestedTokensStaked event triggered when tokens are staked from vesting contract.
 * @param event - The VestedTokensStakedEvent containing poolIndex, beneficiary and amount details.
 */
export function handleVestedTokensStaked(event: VestedTokensStakedEvent): void {
    const beneficiary: Beneficiary = getOrInitBeneficiaries(
        event.address,
        event.params.beneficiary,
        BigInt.fromI32(event.params.poolIndex),
    );
    beneficiary.stakedTokens = beneficiary.stakedTokens.plus(event.params.amount);

    beneficiary.save();
}

/**
 * Handles the VestedTokensUnstaked event triggered when tokens are unstaked from vesting contract.
 * @param event - The VestedTokensUnstakedEvent containing poolIndex, beneficiary and amount details.
 */
export function handleVestedTokensUnstaked(event: VestedTokensUnstakedEvent): void {
    const beneficiary: Beneficiary = getOrInitBeneficiaries(
        event.address,
        event.params.beneficiary,
        BigInt.fromI32(event.params.poolIndex),
    );
    beneficiary.stakedTokens = beneficiary.stakedTokens.minus(event.params.amount);

    beneficiary.save();
}
