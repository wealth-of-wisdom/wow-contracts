import {
    BeneficiaryAdded as BeneficiaryAddedEvent,
    BeneficiaryRemoved as BeneficiaryRemovedEvent,
    ContractTokensWithdrawn as ContractTokensWithdrawnEvent,
    Initialized as InitializedEvent,
    ListingDateChanged as ListingDateChangedEvent,
    StakingContractSet as StakingContractSetEvent,
    TokensClaimed as TokensClaimedEvent,
    AllTokensClaimed as AllTokensClaimedEvent,
    VestedTokensStaked as VestedTokensStakedEvent,
    VestedTokensUnstaked as VestedTokensUnstakedEvent,
    VestingPoolAdded as VestingPoolAddedEvent,
    Vesting,
} from "../../generated/Vesting/Vesting";
import { getOrInitBand } from "../helpers/staking.helpers";
import {
    VestingContract,
    Beneficiary,
    Band,
    VestingPool,
    VestingPoolAllocationLoader,
    VestingPoolAllocation,
} from "../../generated/schema";
import {
    getOrInitBeneficiary,
    getOrInitVestingContract,
    getOrInitVestingPool,
    getOrInitVestingPoolAllocation,
} from "../helpers/vesting.helpers";
import { getUnlockTypeFromBigInt, stringifyUnlockType } from "../utils/utils";
import { Address, BigDecimal, BigInt, store } from "@graphprotocol/graph-ts";
import { BIGDEC_HUNDRED, BIGDEC_ZERO, BIGINT_ZERO, UnlockType } from "../utils/constants";

/**
 * Handles the Initialized event triggered when the contract is initialized.
 * @param event - The InitializedEvent containing the contract address.
 */
export function handleInitialized(event: InitializedEvent): void {
    const vestingContract: VestingContract = getOrInitVestingContract();
    const vesting = Vesting.bind(event.address);

    vestingContract.vestingContractAddress = event.address;
    vestingContract.stakingContractAddress = vesting.getStakingContract();
    vestingContract.tokenContractAddress = vesting.getToken();
    vestingContract.listingDate = vesting.getListingDate();
    vestingContract.save();
}

/**
 * Handles the VestingPoolAdded event triggered when a new vesting pool is added.
 * @param event - The VestingPoolAddedEvent containing the contract address and new pool index.
 */
export function handleVestingPoolAdded(event: VestingPoolAddedEvent): void {
    // Fetch data from Vesting contract
    const vesting: Vesting = Vesting.bind(event.address);
    const generalData = vesting.getGeneralPoolData(event.params.poolIndex);
    const vestingData = vesting.getPoolVestingData(event.params.poolIndex);
    const listingData = vesting.getPoolListingData(event.params.poolIndex);
    const cliffData = vesting.getPoolCliffData(event.params.poolIndex);
    const secondsInDay: BigInt = vesting.DAY();

    // Extract data from Vesting contract getters
    const poolName: string = generalData.getValue0();
    const unlockTypeNum: BigInt = BigInt.fromI32(generalData.getValue1());
    const unlockTypeStr: string = stringifyUnlockType(getUnlockTypeFromBigInt(unlockTypeNum));
    const totalPoolTokensAmount: BigInt = generalData.getValue2();
    const dedicatedPoolTokensAmount: BigInt = generalData.getValue3();

    const listingPercentageDividend: BigDecimal = BigInt.fromI32(listingData.getValue0()).toBigDecimal();
    const listingPercentageDivisor: BigDecimal = BigInt.fromI32(listingData.getValue1()).toBigDecimal();
    const listingPercentage: BigDecimal = listingPercentageDivisor.notEqual(BIGDEC_ZERO)
        ? BIGDEC_HUNDRED.times(listingPercentageDividend).div(listingPercentageDivisor)
        : BIGDEC_ZERO;

    const cliffEndDate: BigInt = cliffData.getValue0();
    const cliffInDays: BigInt = BigInt.fromI32(cliffData.getValue1());
    const cliffDuration: BigInt = cliffInDays.times(secondsInDay);
    const cliffPercentageDividend: BigDecimal = BigInt.fromI32(cliffData.getValue2()).toBigDecimal();
    const cliffPercentageDivisor: BigDecimal = BigInt.fromI32(cliffData.getValue3()).toBigDecimal();
    const cliffPercentage: BigDecimal = cliffPercentageDivisor.notEqual(BIGDEC_ZERO)
        ? BIGDEC_HUNDRED.times(cliffPercentageDividend).div(cliffPercentageDivisor)
        : BIGDEC_ZERO;

    const vestingEndDate: BigInt = vestingData.getValue0();
    const vestingDurationInDays: BigInt = BigInt.fromI32(vestingData.getValue2());
    const vestingDuration: BigInt = vestingDurationInDays.times(secondsInDay);
    const vestingPercentage: BigDecimal = BIGDEC_HUNDRED.minus(listingPercentage).minus(cliffPercentage);

    // Initialize VestingPool entity
    const poolId: BigInt = BigInt.fromI32(event.params.poolIndex);
    const vestingPool: VestingPool = getOrInitVestingPool(poolId);

    vestingPool.name = poolName;
    vestingPool.unlockType = unlockTypeStr;
    vestingPool.totalPoolTokens = totalPoolTokensAmount; // Total tokens allocation in the pool
    vestingPool.dedicatedPoolTokens = dedicatedPoolTokensAmount; // Assigned tokens in the pool
    vestingPool.listingPercentage = listingPercentage;
    vestingPool.cliffDuration = cliffDuration;
    vestingPool.cliffEndDate = cliffEndDate;
    vestingPool.cliffPercentage = cliffPercentage;
    vestingPool.vestingDuration = vestingDuration;
    vestingPool.vestingEndDate = vestingEndDate;
    vestingPool.vestingPercentage = vestingPercentage;
    vestingPool.save();

    // Increment total pool count in VestingContract entity
    const vestingContract: VestingContract = getOrInitVestingContract();
    vestingContract.totalAmountOfPools += 1;
    vestingContract.save();
}

/**
 * Handles the BeneficiaryAdded event triggered when a new beneficiary is added to a pool.
 * @param event - The BeneficiaryAddedEvent containing beneficiary, pool, and token amount details.
 */
export function handleBeneficiaryAdded(event: BeneficiaryAddedEvent): void {
    const poolId: BigInt = BigInt.fromI32(event.params.poolIndex);
    const beneficiaryAddress: Address = event.params.beneficiary;

    const vesting: Vesting = Vesting.bind(event.address);
    const data = vesting.getBeneficiary(poolId.toI32(), beneficiaryAddress);

    const poolAllocation: VestingPoolAllocation = getOrInitVestingPoolAllocation(poolId, beneficiaryAddress);
    const beneficiary: Beneficiary = getOrInitBeneficiary(beneficiaryAddress);

    // If allocation was just created, increment total allocations for the beneficiary
    let totalAllocations = beneficiary.totalAllocations;
    if (poolAllocation.totalTokens.equals(BIGINT_ZERO)) totalAllocations += 1;

    // Update accumulated data for all allocations by beneficiary
    // We need to subtract the old allocation data and add the new allocation data
    // Because this event can be triggered multiple times for the same beneficiary and pool
    beneficiary.totalTokens = beneficiary.totalTokens.minus(poolAllocation.totalTokens).plus(data.totalTokenAmount);
    beneficiary.totalListingTokens = beneficiary.totalListingTokens
        .minus(poolAllocation.listingTokens)
        .plus(data.listingTokenAmount);
    beneficiary.totalCliffTokens = beneficiary.totalCliffTokens
        .minus(poolAllocation.cliffTokens)
        .plus(data.cliffTokenAmount);
    beneficiary.totalVestedTokens = beneficiary.totalVestedTokens
        .minus(poolAllocation.vestedTokens)
        .plus(data.vestedTokenAmount);
    beneficiary.totalStakedTokens = beneficiary.totalStakedTokens
        .minus(poolAllocation.stakedTokens)
        .plus(data.stakedTokenAmount);
    beneficiary.totalClaimedTokens = beneficiary.totalClaimedTokens
        .minus(poolAllocation.claimedTokens)
        .plus(data.claimedTokenAmount);
    beneficiary.totalUnclaimedTokens = beneficiary.totalTokens.minus(beneficiary.totalClaimedTokens);
    beneficiary.totalAllocations = totalAllocations;
    beneficiary.save();

    // Initialize or update allocation with data for the beneficiary
    poolAllocation.totalTokens = data.totalTokenAmount;
    poolAllocation.listingTokens = data.listingTokenAmount;
    poolAllocation.cliffTokens = data.cliffTokenAmount;
    poolAllocation.vestedTokens = data.vestedTokenAmount;
    poolAllocation.stakedTokens = data.stakedTokenAmount;
    poolAllocation.claimedTokens = data.claimedTokenAmount;
    poolAllocation.unclaimedTokens = data.totalTokenAmount.minus(data.claimedTokenAmount);
    poolAllocation.save();

    // Update the total dedicated tokens in the pool
    const vestingPool: VestingPool = getOrInitVestingPool(poolId);
    vestingPool.dedicatedPoolTokens = vestingPool.dedicatedPoolTokens.plus(event.params.addedTokenAmount);
    vestingPool.save();
}

/**
 * Handles the BeneficiaryRemoved event triggered when a beneficiary is removed from a pool.
 * @param event - The BeneficiaryRemovedEvent containing beneficiary and pool details.
 */
export function handleBeneficiaryRemoved(event: BeneficiaryRemovedEvent): void {
    /// @dev We don't remove bands in this event as all the bands are removed in Staking handler

    const poolId: BigInt = BigInt.fromI32(event.params.poolIndex);
    const beneficiaryAddress: Address = event.params.beneficiary;

    const poolAllocation: VestingPoolAllocation = getOrInitVestingPoolAllocation(poolId, beneficiaryAddress);
    const beneficiary: Beneficiary = getOrInitBeneficiary(beneficiaryAddress);

    // Remove the allocation data from the beneficiary
    store.remove("VestingPoolAllocation", poolAllocation.id);

    // Remove the beneficiary if there are no more allocations
    if (beneficiary.totalAllocations == 1) {
        store.remove("Beneficiary", beneficiary.id);
    } else {
        // Update accumulated data for all allocations by beneficiary
        // We need to subtract the old allocation data
        beneficiary.totalTokens = beneficiary.totalTokens.minus(poolAllocation.totalTokens);
        beneficiary.totalListingTokens = beneficiary.totalListingTokens.minus(poolAllocation.listingTokens);
        beneficiary.totalCliffTokens = beneficiary.totalCliffTokens.minus(poolAllocation.cliffTokens);
        beneficiary.totalVestedTokens = beneficiary.totalVestedTokens.minus(poolAllocation.vestedTokens);
        beneficiary.totalStakedTokens = beneficiary.totalStakedTokens.minus(poolAllocation.stakedTokens);
        beneficiary.totalClaimedTokens = beneficiary.totalClaimedTokens.minus(poolAllocation.claimedTokens);
        beneficiary.totalUnclaimedTokens = beneficiary.totalTokens.minus(beneficiary.totalClaimedTokens);
        beneficiary.totalAllocations -= 1;
        beneficiary.save();
    }

    // Update the total dedicated tokens in the pool
    const vestingPool: VestingPool = getOrInitVestingPool(poolId);
    vestingPool.dedicatedPoolTokens = vestingPool.dedicatedPoolTokens.minus(event.params.availableAmount);
    vestingPool.save();
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
    const newListingDate = event.params.newDate;

    const vestingContract: VestingContract = getOrInitVestingContract();
    vestingContract.listingDate = newListingDate;
    vestingContract.save();

    const totalPools = vestingContract.totalAmountOfPools;
    for (let i = 0; i < totalPools; i++) {
        const vestingPool: VestingPool = getOrInitVestingPool(BigInt.fromI32(i));
        vestingPool.cliffEndDate = newListingDate.plus(vestingPool.cliffDuration);
        vestingPool.vestingEndDate = vestingPool.cliffEndDate.plus(vestingPool.vestingDuration);
        vestingPool.save();
    }
}

/**
 * Handles the StakingContractSet event triggered when the staking contract address is set.
 * @param event - The StakingContractSetEvent containing the new staking contract address.
 */
export function handleStakingContractSet(event: StakingContractSetEvent): void {
    const vestingContract: VestingContract = getOrInitVestingContract();
    vestingContract.stakingContractAddress = event.params.newContract;
    vestingContract.save();
}

/**
 * Handles the TokensClaimed event triggered when tokens are claimed by a beneficiary.
 * @param event - The TokensClaimedEvent containing beneficiary, pool, and claimed token amount details.
 */
export function handleTokensClaimed(event: TokensClaimedEvent): void {
    const poolId: BigInt = BigInt.fromI32(event.params.poolIndex);
    const beneficiaryAddress: Address = event.params.user;
    const claimedAmount: BigInt = event.params.tokenAmount;

    const poolAllocation: VestingPoolAllocation = getOrInitVestingPoolAllocation(poolId, beneficiaryAddress);
    poolAllocation.claimedTokens = poolAllocation.claimedTokens.plus(claimedAmount);
    poolAllocation.unclaimedTokens = poolAllocation.unclaimedTokens.minus(claimedAmount);
    poolAllocation.save();

    const beneficiary: Beneficiary = getOrInitBeneficiary(beneficiaryAddress);
    beneficiary.totalClaimedTokens = beneficiary.totalClaimedTokens.plus(claimedAmount);
    beneficiary.totalUnclaimedTokens = beneficiary.totalUnclaimedTokens.minus(claimedAmount);
    beneficiary.save();
}

/**
 * Handles the AllTokensClaimed event triggered when all tokens are claimed by a beneficiary.
 * @param event - The AllTokensClaimedEvent containing beneficiary and pool details.
 */
export function handleAllTokensClaimed(event: AllTokensClaimedEvent): void {
    /// @dev This handler is not used as all the logic is handled in handleTokensClaimed event
}

/**
 * Handles the VestedTokensStaked event triggered when tokens are staked from vesting contract.
 * @param event - The VestedTokensStakedEvent containing poolIndex, beneficiary and amount details.
 */
export function handleVestedTokensStaked(event: VestedTokensStakedEvent): void {
    const poolId: BigInt = BigInt.fromI32(event.params.poolIndex);
    const beneficiaryAddress: Address = event.params.beneficiary;
    const stakedAmount: BigInt = event.params.amount;

    const poolAllocation: VestingPoolAllocation = getOrInitVestingPoolAllocation(poolId, beneficiaryAddress);
    poolAllocation.stakedTokens = poolAllocation.stakedTokens.plus(stakedAmount);
    poolAllocation.save();

    const beneficiary: Beneficiary = getOrInitBeneficiary(beneficiaryAddress);
    beneficiary.totalStakedTokens = beneficiary.totalStakedTokens.plus(stakedAmount);
    beneficiary.save();

    // Update the vesting pool in the band entity
    const band: Band = getOrInitBand(event.params.bandId);
    band.vestingPool = getOrInitVestingPool(poolId).id;
    band.save();
}

/**
 * Handles the VestedTokensUnstaked event triggered when tokens are unstaked from vesting contract.
 * @param event - The VestedTokensUnstakedEvent containing poolIndex, beneficiary and amount details.
 */
export function handleVestedTokensUnstaked(event: VestedTokensUnstakedEvent): void {
    /// @dev Don't remove band entity as it is removed in Staking handler

    const poolId: BigInt = BigInt.fromI32(event.params.poolIndex);
    const beneficiaryAddress: Address = event.params.beneficiary;
    const unstakedAmount: BigInt = event.params.amount;

    const poolAllocation: VestingPoolAllocation = getOrInitVestingPoolAllocation(poolId, beneficiaryAddress);
    poolAllocation.stakedTokens = poolAllocation.stakedTokens.minus(unstakedAmount);
    poolAllocation.save();

    const beneficiary: Beneficiary = getOrInitBeneficiary(beneficiaryAddress);
    beneficiary.totalStakedTokens = beneficiary.totalStakedTokens.minus(unstakedAmount);
    beneficiary.save();
}
