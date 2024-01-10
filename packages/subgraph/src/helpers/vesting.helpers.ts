import { Address, BigInt, log } from "@graphprotocol/graph-ts";
import { BIGDEC_ZERO, BIGINT_ZERO } from "../utils/constants";
import {
    VestingContract,
    VestingPool,
    Beneficiary,
} from "../../generated/schema"
import { getUnlockType } from "../utils/utils";

export enum UnlockType {
    DAILY,
    MONTHLY
}


export function getOrInitVestingContract(vestingContractAddress: Address): VestingContract {

    // TODO: need ID to be unique
    let vestingContractId = vestingContractAddress.toHex();
    let vestingContract = VestingContract.load(vestingContractId);

    if (!vestingContract) {

        vestingContract = new VestingContract(vestingContractId);
        vestingContract.vestingContractAddress = vestingContractAddress;

        vestingContract.save();
    }

    return vestingContract;
}

export function getOrInitVestingPool(vestingContractAddress: Address, poolId: BigInt): VestingPool {

    let vestingPoolId = vestingContractAddress.toHex() + "-" + poolId.toHex();

    let vestingPool = VestingPool.load(vestingPoolId);

    if (!vestingPool) {
        vestingPool = new VestingPool(vestingPoolId);

        vestingPool.poolId = BIGINT_ZERO;
        vestingPool.name = "";
        vestingPool.listingPercentage = BIGINT_ZERO;

        // Cliff details
        vestingPool.cliffDuration = BIGINT_ZERO;
        vestingPool.cliffEndDate = BIGINT_ZERO;
        vestingPool.cliffPercentage = BIGINT_ZERO;

        // Vesting details
        vestingPool.vestingDuration = BIGINT_ZERO;
        vestingPool.vestingEndDate = BIGINT_ZERO;
        vestingPool.unlockType = getUnlockType(UnlockType.DAILY);

        vestingPool.dedicatedPoolTokens = BIGINT_ZERO

        vestingPool.save();

    }

    return vestingPool;
}

export function getOrInitBeneficiaries(vestingContractAddress: Address, beneficiaryAddress: Address, poolId: BigInt): Beneficiary {

    let beneficiaryId = beneficiaryAddress.toHex() + "-" + poolId.toHex();

    let beneficiary = Beneficiary.load(beneficiaryId);

    if (!beneficiary) {

        beneficiary = new Beneficiary(beneficiaryId);
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


