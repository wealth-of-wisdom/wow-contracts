import { Address, BigInt } from "@graphprotocol/graph-ts";
import { BIGINT_ZERO, BIGDEC_ZERO, UNLOCK_TYPE_DAILY } from "../utils/constants";
import { VestingContract, VestingPool, VestingPoolAllocation, Beneficiary } from "../../generated/schema";

/**
 * Retrieves or initializes a VestingContract entity.
 * @returns The VestingContract entity.
 */
export function getOrInitVestingContract(): VestingContract {
    const vestingContractId = "0";
    let vestingContract = VestingContract.load(vestingContractId);

    if (!vestingContract) {
        vestingContract = new VestingContract(vestingContractId);

        // Set default Vesting contract entity values
        vestingContract.vestingContractAddress = Address.zero();
        vestingContract.stakingContractAddress = Address.zero();
        vestingContract.tokenContractAddress = Address.zero();
        vestingContract.listingDate = BIGINT_ZERO;
        vestingContract.totalAmountOfPools = 0;

        vestingContract.save();
    }

    return vestingContract;
}

/**
 * Retrieves or initializes a VestingPool entity.
 * @param poolId - The pool ID.
 * @returns The VestingPool entity.
 */
export function getOrInitVestingPool(poolId: BigInt): VestingPool {
    const vestingPoolId = poolId.toString();
    let vestingPool = VestingPool.load(vestingPoolId);

    if (!vestingPool) {
        vestingPool = new VestingPool(vestingPoolId);

        // Set default Vesting pool entity values
        vestingPool.name = "";
        vestingPool.listingPercentage = BIGDEC_ZERO;
        vestingPool.cliffDuration = BIGINT_ZERO;
        vestingPool.cliffEndDate = BIGINT_ZERO;
        vestingPool.cliffPercentage = BIGDEC_ZERO;
        vestingPool.vestingDuration = BIGINT_ZERO;
        vestingPool.vestingEndDate = BIGINT_ZERO;
        vestingPool.vestingPercentage = BIGDEC_ZERO;
        vestingPool.unlockType = UNLOCK_TYPE_DAILY;
        vestingPool.dedicatedPoolTokens = BIGINT_ZERO;
        vestingPool.totalPoolTokens = BIGINT_ZERO;

        vestingPool.save();
    }

    return vestingPool;
}

/**
 * Retrieves or initializes a VestingPoolAllocation entity.
 * @param poolId - The pool ID.
 * @param beneficiaryAddress - The beneficiary address.
 * @returns The VestingPoolAllocation entity.
 */
export function getOrInitVestingPoolAllocation(poolId: BigInt, beneficiaryAddress: Address): VestingPoolAllocation {
    const vestingPoolAllocationId = poolId.toString() + "-" + beneficiaryAddress.toHex();
    let vestingPoolAllocation = VestingPoolAllocation.load(vestingPoolAllocationId);

    if (!vestingPoolAllocation) {
        vestingPoolAllocation = new VestingPoolAllocation(vestingPoolAllocationId);

        // Set default Vesting pool entity values
        vestingPoolAllocation.vestingPool = getOrInitVestingPool(poolId).id;
        vestingPoolAllocation.beneficiary = getOrInitBeneficiary(beneficiaryAddress).id;
        vestingPoolAllocation.totalTokens = BIGINT_ZERO;
        vestingPoolAllocation.listingTokens = BIGINT_ZERO;
        vestingPoolAllocation.cliffTokens = BIGINT_ZERO;
        vestingPoolAllocation.vestedTokens = BIGINT_ZERO;
        vestingPoolAllocation.stakedTokens = BIGINT_ZERO;
        vestingPoolAllocation.unstakedTokens = BIGINT_ZERO;
        vestingPoolAllocation.claimedTokens = BIGINT_ZERO;
        vestingPoolAllocation.unclaimedTokens = BIGINT_ZERO;

        vestingPoolAllocation.save();
    }

    return vestingPoolAllocation;
}

/**
 * Retrieves or initializes a Beneficiary entity.
 * @param vestingContractAddress - The address of the VestingContract.
 * @param beneficiaryAddress - The address of the beneficiary.
 * @returns The Beneficiary entity.
 */
export function getOrInitBeneficiary(beneficiaryAddress: Address): Beneficiary {
    let beneficiaryId = beneficiaryAddress.toHex();

    let beneficiary = Beneficiary.load(beneficiaryId);

    if (!beneficiary) {
        beneficiary = new Beneficiary(beneficiaryId);

        // Set default Vesting pool entity values
        beneficiary.totalTokens = BIGINT_ZERO;
        beneficiary.totalListingTokens = BIGINT_ZERO;
        beneficiary.totalCliffTokens = BIGINT_ZERO;
        beneficiary.totalVestedTokens = BIGINT_ZERO;
        beneficiary.totalStakedTokens = BIGINT_ZERO;
        beneficiary.totalUnstakedTokens = BIGINT_ZERO;
        beneficiary.totalClaimedTokens = BIGINT_ZERO;
        beneficiary.totalUnclaimedTokens = BIGINT_ZERO;
        beneficiary.totalAllocations = 0;

        beneficiary.save();
    }

    return beneficiary;
}
