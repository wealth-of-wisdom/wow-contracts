import { Address } from "@graphprotocol/graph-ts";
import { StakingContract, Staker, StakerRewards } from "../../generated/schema";
import { getOrInitStakerRewards } from "../helpers/staking.helpers";

/*//////////////////////////////////////////////////////////////////////////
                                  MAIN FUNCTION
//////////////////////////////////////////////////////////////////////////*/

export function claimRewardsFromUnclaimedAmount(stakingContract: StakingContract, staker: Staker): void {
    const stakerAddress: Address = Address.fromString(staker.id);

    const usdtToken: Address = Address.fromBytes(stakingContract.usdtToken);
    const usdtRewards: StakerRewards = getOrInitStakerRewards(stakerAddress, usdtToken);
    usdtRewards.claimedAmount = usdtRewards.claimedAmount.plus(usdtRewards.unclaimedAmount);
    usdtRewards.save();

    const usdcToken: Address = Address.fromBytes(stakingContract.usdcToken);
    const usdcRewards: StakerRewards = getOrInitStakerRewards(stakerAddress, usdcToken);
    usdcRewards.claimedAmount = usdcRewards.claimedAmount.plus(usdcRewards.unclaimedAmount);
    usdcRewards.save();
}
