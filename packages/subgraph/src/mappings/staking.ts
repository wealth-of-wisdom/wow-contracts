import {
    Initialized as InitializedEvent,
    AllRewardsClaimed as AllRewardsClaimedEvent,
    BandDowngraded as BandDowngradedEvent,
    BandStaked as BandStakedEvent,
    BandUnstaked as BandUnstakedEvent,
    BandUpgaded as BandUpgadedEvent,
    FundsDistributed as FundsDistributedEvent,
    RewardsClaimed as RewardsClaimedEvent,
    SharesInMonthSet as SharesInMonthSetEvent,
    Staked as StakedEvent,
    TokensWithdrawn as TokensWithdrawnEvent,
    TotalBandLevelsAmountSet as TokensClaimedAmountSetEvent,
    TotalPoolAmountSet as TotalPoolAmountSetEvent,
    Unstaked as UnstakedEvent,
    VestingUserRemoved as VestingUserRemovedEvent,
} from "../../generated/Staking/Staking";
import { StakingContract, Pool, Band, FundDistribution } from "../../generated/schema";
import {
    getOrInitBand,
    getOrInitFundDistribution,
    getOrInitPool,
    getOrInitStakingContract,
} from "../helpers/staking.helpers";
import { BIGINT_ZERO } from "../utils/constants";
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
// Band add
export function handleBandStaked(event: BandStakedEvent): void {
    const band: Band = getOrInitBand(event.params.bandId);

    // band.stakingType = event.params
    band.bandLevel = event.params.bandLevel;
    band.owner = event.params.user;
    // band.price = event.params.price;
    band.startingSharesAmount = BIGINT_ZERO;
    band.stakingStartTimestamp = event.block.timestamp;
    band.claimableRewardsAmount = BIGINT_ZERO;
    band.usdcRewardsClaimed = BIGINT_ZERO;
    band.usdcRewardsClaimed = BIGINT_ZERO;

    band.save();
}
// Band remove
export function handleBandUnstaked(event: BandUnstakedEvent): void {
    const band: Band = getOrInitBand(event.params.bandId);

    store.remove("Band", band.id);

    band.save();
}

// Band upgrade
export function handleBandUpgaded(event: BandUpgadedEvent): void {
    const band: Band = getOrInitBand(event.params.bandId);

    band.bandLevel = event.params.newBandLevel;
    band.owner = event.params.user;

    band.save();
}

// Band downgrade
export function handleBandDowngraded(event: BandDowngradedEvent): void {
    const band: Band = getOrInitBand(event.params.bandId);

    band.bandLevel = event.params.newBandLevel;
    band.owner = event.params.user;

    band.save();
}

export function handleFundsDistributed(event: FundsDistributedEvent): void {
    const fundsDistribution = getOrInitFundDistribution(event.transaction.hash);

    fundsDistribution.amount = event.params.amount;
    fundsDistribution.timestamp = event.block.timestamp;
    fundsDistribution.token = event.params.token;

    fundsDistribution.save();
}

export function handleRewardsClaimed(event: RewardsClaimedEvent): void {
    // @todo This event should also emit band ID, to track claimed rewards from band
    const band = getOrInitBand(event.params.bandId)

    // @todo add this to constants file
    const usdtAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
    const usdcAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";

    if (event.params.token.toString() === usdtAddress) {
        band.usdtRewardsClaimed = event.params.totalRewards;
    } else if (event.params.token.toString() === usdcAddress) {
        band.usdcRewardsClaimed = event.params.totalRewards;
    }

    band.save();
}

// @note What is the difference between StakedEvent and handleBandStaked???
export function handleStaked(event: StakedEvent): void {
   
    // @todo This event should also emit band ID, to track staked band
    const band = getOrInitBand(event.params.bandId)

    band.bandLevel = event.params.bandLevel;
    band.stakingType = event.params.stakingType;
    band.owner = event.params.user
    
    band.save();
}

