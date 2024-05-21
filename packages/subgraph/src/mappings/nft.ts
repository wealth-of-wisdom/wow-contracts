import { BigInt, dataSource } from "@graphprotocol/graph-ts";
import {
    Initialized as InitializedEvent,
    NftDataSet as NftDataSetEvent,
    NftMinted as NftMintedEvent,
    NftDeactivated as NftDeactivatedEvent,
    NftDataActivated as NftDataActivatedEvent,
} from "../../generated/Nft/Nft";
import { Nft, NftContract, User } from "../../generated/schema";
import { getOrInitNftContract, getOrInitNft, getOrInitUser } from "../helpers/nft.helpers";
import { ACTIVITY_STATUS_ACTIVATED, ACTIVITY_STATUS_DEACTIVATED, ARBITRUM_ONE_NETWORK } from "../utils/constants";
import { stringifyActivityStatus } from "../utils/utils";

export function handleInitialized(event: InitializedEvent): void {
    const nftContract: NftContract = getOrInitNftContract();
    nftContract.nftContractAddress = event.address;
    nftContract.save();
}

export function handleNftDataSet(event: NftDataSetEvent): void {
    const nft: Nft = getOrInitNft(event.params.tokenId);

    nft.level = BigInt.fromI32(event.params.level);
    nft.isGenesis = event.params.isGenesis;
    nft.activityStatus = stringifyActivityStatus(event.params.activityType.toI32());
    nft.activityEndTimestamp = event.params.activityEndTimestamp;
    nft.extendedActivityEndTimestamp = event.params.extendedActivityEndTimestamp;

    nft.save();
}

export function handleNftDeactivated(event: NftDeactivatedEvent): void {
    const nft: Nft = getOrInitNft(event.params.tokenId);
    nft.activityStatus = ACTIVITY_STATUS_DEACTIVATED;
    nft.save();
}

export function handleNftMinted(event: NftMintedEvent): void {
    const user: User = getOrInitUser(event.params.receiver);
    const nft: Nft = getOrInitNft(event.params.tokenId);

    nft.idInLevel = event.params.idInLevel;
    nft.level = BigInt.fromI32(event.params.level);
    nft.isGenesis = event.params.isGenesis;
    nft.owner = user.id;

    // This is hardcoded values for the Arbitrum One network to deactivate the old NFTs
    // Because old NFT contract didn't have the NftDeactivated event
    if (dataSource.network() == ARBITRUM_ONE_NETWORK) {
        let oldNft: Nft | null = null;

        if (user.id == "0xdc8d7f971bef8457b00f0d26a7666fa243045cf2" && nft.id == "50") {
            oldNft = getOrInitNft(BigInt.fromString("28"));
        } else if (user.id == "0x6a34916648f981b0ce228b47fb913b4ed9b84b83" && nft.id == "51") {
            oldNft = getOrInitNft(BigInt.fromString("9"));
        } else if (user.id == "0x5adb3f2103df1ee4372001f7829c78683defef94" && nft.id == "52") {
            oldNft = getOrInitNft(BigInt.fromString("3"));
        }

        if (oldNft && oldNft.activityStatus != ACTIVITY_STATUS_DEACTIVATED) {
            oldNft.activityStatus = ACTIVITY_STATUS_DEACTIVATED;
            oldNft.save();
        }
    }

    nft.save();
}

export function handleNftDataActivated(event: NftDataActivatedEvent): void {
    const user: User = getOrInitUser(event.params.receiver);
    const oldNftId: string | null = user.activeNft;
    const newNftId: BigInt = event.params.tokenId;

    // If the user already has an active NFT, deactivate it
    if (oldNftId != null) {
        const oldNft: Nft = getOrInitNft(BigInt.fromString(oldNftId as string));
        oldNft.activityStatus = ACTIVITY_STATUS_DEACTIVATED;
        oldNft.save();
    }

    // Activate the new NFT
    const newNft: Nft = getOrInitNft(newNftId);
    newNft.activityStatus = ACTIVITY_STATUS_ACTIVATED;
    newNft.activityEndTimestamp = event.params.activityEndTimestamp;
    newNft.extendedActivityEndTimestamp = event.params.extendedActivityEndTimestamp;
    newNft.save();

    // Update the user's active NFT
    user.activeNft = newNftId.toString();
    user.save();
}
