import {
    Initialized as InitializedEvent,
    NftMinted as NftMintedEvent,
    NftDataActivated as NftDataActivatedEvent,
} from "../../generated/Nft/Nft";
import { Nft, NftContract, User } from "../../generated/schema";
import { getOrInitNftContract, getOrInitNft, getOrInitUser } from "../helpers/nft.helpers";
import { BigInt } from "@graphprotocol/graph-ts";

export function handleInitialized(event: InitializedEvent): void {
    const nftContract: NftContract = getOrInitNftContract();
    nftContract.nftContractAddress = event.address;
    nftContract.save();
}

export function handleNftMinted(event: NftMintedEvent): void {
    const user: User = getOrInitUser(event.params.receiver);
    const nft: Nft = getOrInitNft(event.params.tokenId);

    nft.idInLevel = event.params.idInLevel;
    nft.level = BigInt.fromI32(event.params.level);
    nft.isGenesis = event.params.isGenesis;
    nft.owner = user.id;

    nft.save();
}

export function handleNftDataActivated(event: NftDataActivatedEvent): void {
    const user: User = getOrInitUser(event.params.receiver);
    const oldNftId: string | null = user.activeNft;
    const newNftId: BigInt = event.params.tokenId;

    // If the user already has an active NFT, deactivate it
    if (oldNftId != null) {
        const oldNft: Nft = getOrInitNft(BigInt.fromString(oldNftId as string));
        oldNft.isActive = false;
        oldNft.save();
    }

    // Activate the new NFT
    const newNft: Nft = getOrInitNft(newNftId);
    newNft.isActive = true;
    newNft.activityEndTimestamp = event.params.activityEndTimestamp;
    newNft.extendedActivityEndTimestamp = event.params.extendedActivityEndTimestamp;
    newNft.save();

    // Update the user's active NFT
    user.activeNft = newNftId.toString();
    user.save();
}
