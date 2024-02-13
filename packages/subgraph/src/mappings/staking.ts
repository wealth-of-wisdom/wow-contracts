import {
    Initialized as InitializedEvent,
    AllRewardsClaimed as AllRewardsClaimedEvent,
    BandDowngraded as BandDowngradedEvent,
    BandStaked as BandStakedEvent,
    BandUnstaked as BandUnstakedEvent,
    BandUpgaded as BandUpgadedEvent,
    FundsDistributed as FundDistributionEvent,
    RewardsClaimed as RewardsClaimedEvent,
    SharesInMonthSet as SharesInMonthSetEvent,
    Staked as StakedEvent,
    TokensWithdrawn as TokensWithdrawnEvent,
    TotalBandLevelsAmountSet as TokensClaimedAmountSetEvent,
    TotalPoolAmountSet as TotalPoolAmountSetEvent,
    Unstaked as UnstakedEvent,
    VestingUserRemoved as VestingUserRemovedEvent
} from "../../generated/Staking/Staking";
import {
    StakingContract,
    Pool,
    Band,
    FundDistribution
} from "../../generated/schema"
import { getOrInitBand, getOrInitFundDistribution, getOrInitPool, getOrInitStakingContract } from "../helpers/staking.helpers"
import { stringifyStakingType } from "../utils/utils";
import { BigInt, store } from "@graphprotocol/graph-ts";


/**
 * Handles the Initialized event triggered when the contract is initialized.
 * @param event - The InitializedEvent containing the contract address.
 */
export function handleInitialized(event: InitializedEvent): void {

    const stakingContract: StakingContract = getOrInitStakingContract(event.address);

    stakingContract.save();

}
