import {
    Initialized as InitializedEvent,
    NftMinted as NftMintedEvent,
    NftDataActivated as NftDataActivatedEvent,
} from "../../generated/Nft/Nft";
import { Nft, NftContract, User } from "../../generated/schema";
import { getOrInitNFTContract, getOrInitNft, getOrInitUser } from "../helpers/nft.helpers";
import { BigInt } from "@graphprotocol/graph-ts";

export function handleInitialized(event: InitializedEvent): void {
    getOrInitNFTContract(event.address);
}

export function handleNftMinted(event: NftMintedEvent): void {
    const user: User = getOrInitUser(event.params.receiver);
    const nft: Nft = getOrInitNft(event.params.tokenId.toString());

    nft.level = BigInt.fromI32(event.params.level);
    nft.isGenesis = event.params.isGenesis;
    nft.idInLevel = event.params.idInLevel;
    nft.owner = user.id;

    nft.save();
}

export function handleNftActivation(event: NftDataActivatedEvent): void {
    const nft: Nft = getOrInitNft(event.params.tokenId.toString());

    nft.activityEndTimestamp = event.params.activityEndTimestamp;
    nft.extendedActivityEndTimestamp = event.params.extendedActivityEndTimestamp;

    nft.save();
}
