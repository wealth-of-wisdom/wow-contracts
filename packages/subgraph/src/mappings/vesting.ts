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
import { getOrInitBeneficiary, getOrInitVestingContract, getOrInitVestingPool } from "../helpers/vesting.helpers";
import { BIGINT_ONE } from "../utils/constants";
import { getUnlockTypeFromBigInt, stringifyUnlockType } from "../utils/utils";
import { BigInt, store } from "@graphprotocol/graph-ts";

/**
 * Handles the Initialized event triggered when the contract is initialized.
 * @param event - The InitializedEvent containing the contract address.
 */
export function handleInitialized(event: InitializedEvent): void {
    const vestingContract: VestingContract = getOrInitVestingContract(event.address);

    const vesting = Vesting.bind(event.address);
    vestingContract.tokenContractAddress = vesting.getToken();
    vestingContract.listingDate = vesting.getListingDate();
    vestingContract.stakingContractAddress = vesting.getStakingContract();
    vestingContract.save();
}

/**
 * Handles the VestingPoolAdded event triggered when a new vesting pool is added.
 * @param event - The VestingPoolAddedEvent containing the contract address and new pool index.
 */
export function handleVestingPoolAdded(event: VestingPoolAddedEvent): void {
    const vestingContractBind: Vesting = Vesting.bind(event.address);
    const poolIndex: BigInt = BigInt.fromI32(event.params.poolIndex);

    const vestingPool: VestingPool = getOrInitVestingPool(poolIndex);

    // Fetch data from Vesting contract
    const generalData = vestingContractBind.getGeneralPoolData(event.params.poolIndex);
    const vestingData = vestingContractBind.getPoolVestingData(event.params.poolIndex);
    const listingData = vestingContractBind.getPoolListingData(event.params.poolIndex);
    const cliffData = vestingContractBind.getPoolCliffData(event.params.poolIndex);

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

    const vestingContract: VestingContract = getOrInitVestingContract(event.address);
    const totalPoolAmount = vestingContract.poolAmount;

    // Update VestingPool entity properties
    vestingPool.poolId = poolIndex;
    vestingPool.vestingContract = event.address.toHex();
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

    // Update total pool amount in Vesting
    vestingContract.poolAmount = totalPoolAmount.plus(BIGINT_ONE);
    vestingContract.save();
}

/**
 * Handles the BeneficiaryAdded event triggered when a new beneficiary is added to a pool.
 * @param event - The BeneficiaryAddedEvent containing beneficiary, pool, and token amount details.
 */
export function handleBeneficiaryAdded(event: BeneficiaryAddedEvent): void {
    const beneficiary: Beneficiary = getOrInitBeneficiary(
        event.params.beneficiary,
        BigInt.fromI32(event.params.poolIndex),
    );

    const vestingPool: VestingPool = getOrInitVestingPool(event.params.poolIndex);
    const vestingContract: Vesting = Vesting.bind(event.address);

    const beneficiaryData = vestingContract.getBeneficiary(event.params.poolIndex, event.params.beneficiary);
    const dedicatedPoolTokenAmount = vestingPool.dedicatedPoolTokens;

    // Updated user data

    beneficiary.id = event.params.beneficiary.toString();
    beneficiary.vestingPool = event.params.poolIndex.toString();
    beneficiary.totalTokens = beneficiaryData.totalTokenAmount;
    beneficiary.listingTokens = beneficiaryData.listingTokenAmount;
    beneficiary.cliffTokens = beneficiaryData.cliffTokenAmount;
    beneficiary.vestedTokens = beneficiaryData.vestedTokenAmount;
    beneficiary.stakedTokens = beneficiaryData.stakedTokenAmount;
    beneficiary.claimedTokens = beneficiaryData.claimedTokenAmount;
    beneficiary.save();

    let beneficiaries = vestingPool.beneficiaries;
    beneficiaries.push(beneficiary.id.toString());
    vestingPool.beneficiaries = beneficiaries;

    vestingPool.dedicatedPoolTokens = dedicatedPoolTokenAmount.plus(event.params.addedTokenAmount);
    vestingPool;
    vestingPool.save();
}

/**
 * Handles the BeneficiaryRemoved event triggered when a beneficiary is removed from a pool.
 * @param event - The BeneficiaryRemovedEvent containing beneficiary and pool details.
 */
export function handleBeneficiaryRemoved(event: BeneficiaryRemovedEvent): void {
    const beneficiary: Beneficiary = getOrInitBeneficiary(
        event.params.beneficiary,
        BigInt.fromI32(event.params.poolIndex),
    );
    const vestingPool: VestingPool = getOrInitVestingPool(event.params.poolIndex);
    const dedicatedPoolTokenAmount = vestingPool.dedicatedPoolTokens;

    const beneficiariesAmount = vestingPool.beneficiaries.length;
    for (let i = 0; i < beneficiariesAmount; i++) {
        if (vestingPool.beneficiaries[i] == beneficiary.id.toString()) {
            let beneficiaryIds = vestingPool.beneficiaries;
            beneficiaryIds[i] = beneficiaryIds[vestingPool.beneficiaries.length - 1];
            beneficiaryIds.pop();
            vestingPool.beneficiaries = beneficiaryIds;
            vestingPool.save();
            store.remove("Beneficiary", beneficiary.id);
            break;
        }
    }

    vestingPool.dedicatedPoolTokens = dedicatedPoolTokenAmount.minus(event.params.availableAmount);
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
    const vestingContract: VestingContract = getOrInitVestingContract(event.address);

    vestingContract.listingDate = event.params.newDate;
    vestingContract.save();

    const totalPoolAmount = vestingContract.poolAmount;
    for (let i = 0; i < totalPoolAmount; i++) {
        const vestingPool: VestingPool = getOrInitVestingPool(BigInt.fromI32(i));
        const newListingDate = event.params.newDate;
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
    const vestingContract: VestingContract = getOrInitVestingContract(event.address);

    vestingContract.stakingContractAddress = event.params.newContract;

    vestingContract.save();
}

/**
 * Handles the TokensClaimed event triggered when tokens are claimed by a beneficiary.
 * @param event - The TokensClaimedEvent containing beneficiary, pool, and claimed token amount details.
 */
export function handleTokensClaimed(event: TokensClaimedEvent): void {
    const beneficiary: Beneficiary = getOrInitBeneficiary(event.params.user, BigInt.fromI32(event.params.poolIndex));

    // sum claimed amount
    beneficiary.claimedTokens = beneficiary.claimedTokens.plus(event.params.tokenAmount);
    // @note I think also needed total tokens that are claimed removed from total tokens (not sure about that)
    beneficiary.totalTokens = beneficiary.totalTokens.minus(beneficiary.claimedTokens);

    beneficiary.save();
}

/**
 * Handles the VestedTokensStaked event triggered when tokens are staked from vesting contract.
 * @param event - The VestedTokensStakedEvent containing poolIndex, beneficiary and amount details.
 */
export function handleVestedTokensStaked(event: VestedTokensStakedEvent): void {
    const vestingPool: VestingPool = getOrInitVestingPool(event.params.poolIndex);
    const beneficiary: Beneficiary = getOrInitBeneficiary(
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
    const beneficiary: Beneficiary = getOrInitBeneficiary(
        event.params.beneficiary,
        BigInt.fromI32(event.params.poolIndex),
    );
    beneficiary.stakedTokens = beneficiary.stakedTokens.minus(event.params.amount);
    beneficiary.save();
}
