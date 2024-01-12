import { Address, BigInt, log, Bytes } from "@graphprotocol/graph-ts";
import { BIGINT_ZERO, UnlockType } from "../utils/constants";
import {
    VestingContract,
    VestingPool,
    Beneficiary,
} from "../../generated/schema"
import { stringifyUnlockType } from "../utils/utils";


/**
 * Retrieves or initializes a VestingContract entity.
 * @param vestingContractAddress - The address of the VestingContract.
 * @returns The VestingContract entity.
 */
export function getOrInitVestingContract(vestingContractAddress: Address): VestingContract {

    //  @note: redundant ID and vesting contract address.
    let vestingContractId = vestingContractAddress.toHex();
    let vestingContract = VestingContract.load(vestingContractId);

    if (!vestingContract) {

        vestingContract = new VestingContract(vestingContractId);

        // set default Vesting contract entity values
        vestingContract.vestingContractAddress = vestingContractAddress;
        vestingContract.stakingContractAddress = Address.empty();
        vestingContract.listingDate = BIGINT_ZERO;

        vestingContract.save();
    }

    return vestingContract;
}

/**
 * Retrieves or initializes a VestingPool entity.
 * @param vestingContractAddress - The address of the VestingContract.
 * @param poolId - The pool ID.
 * @returns The VestingPool entity.
 */
export function getOrInitVestingPool(vestingContractAddress: Address, poolId: BigInt): VestingPool {

    let vestingPoolId = vestingContractAddress.toHex() + "-" + poolId.toString();
    let vestingPool = VestingPool.load(vestingPoolId);

    if (!vestingPool) {
        vestingPool = new VestingPool(vestingPoolId);

        // Set default Vesting pool entity values
        vestingPool.poolId = BIGINT_ZERO;
        vestingPool.vestingContract = getOrInitVestingContract(vestingContractAddress).id;
        vestingPool.name = "";
        vestingPool.listingPercentageDividend = BIGINT_ZERO;
        vestingPool.listingPercentageDivisor = BIGINT_ZERO;
        vestingPool.cliffDuration = BIGINT_ZERO;
        vestingPool.cliffEndDate = BIGINT_ZERO;
        vestingPool.cliffPercentageDividend = BIGINT_ZERO;
        vestingPool.cliffPercentageDivisor = BIGINT_ZERO;
        vestingPool.vestingDuration = BIGINT_ZERO;
        vestingPool.vestingEndDate = BIGINT_ZERO;
        vestingPool.unlockType = stringifyUnlockType(UnlockType.DAILY);
        vestingPool.dedicatedPoolTokens = BIGINT_ZERO
        vestingPool.totalPoolTokenAmount = BIGINT_ZERO;


        vestingPool.save();
    }

    return vestingPool;
}

/**
 * Retrieves or initializes a Beneficiary entity.
 * @param vestingContractAddress - The address of the VestingContract.
 * @param beneficiaryAddress - The address of the beneficiary.
 * @param poolId - The pool ID.
 * @returns The Beneficiary entity.
 */
export function getOrInitBeneficiaries(vestingContractAddress: Address, beneficiaryAddress: Address, poolId: BigInt): Beneficiary {

    let beneficiaryId = beneficiaryAddress.toHex() + "-" + poolId.toHex();
    
    let beneficiary = Beneficiary.load(beneficiaryId);

    if (!beneficiary) {

        beneficiary = new Beneficiary(beneficiaryId);

        // Set default Vesting pool entity values
        beneficiary.address = beneficiaryAddress;
        beneficiary.vestingPool = getOrInitVestingPool(vestingContractAddress, poolId).id;
        beneficiary.totalTokens = BIGINT_ZERO;
        beneficiary.vestedTokens = BIGINT_ZERO;
        beneficiary.stakedTokens = BIGINT_ZERO;
        beneficiary.claimedTokens = BIGINT_ZERO;


        beneficiary.save();
    }

    return beneficiary;

}


