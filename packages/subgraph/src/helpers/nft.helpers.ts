import { Address } from "@graphprotocol/graph-ts";
import { NftContract, Nft, User } from "../../generated/schema"; // Adjust the import path as necessary
import { BIGINT_ZERO } from "../utils/constants";

/**
 * Retrieves or initializes an NFTContract entity.
 * @param contractAddress Nft contract address
 * @returns The NFTContract entity.
 */
export function getOrInitNFTContract(contractAddress: Address): NftContract {
    // @todo Id for singleton NftContract entity should be 0
    const id = contractAddress.toHex();
    let nftContract = NftContract.load(id);

    if (!nftContract) {
        nftContract = new NftContract(id);
        nftContract.nftContractAddress = contractAddress;

        nftContract.save();
    }

    return nftContract;
}

/**
 * Retrieves or initializes an Nft entity with a given tokenId.
 * @param tokenId The tokenId of the Nft.
 * @returns The Nft entity.
 */
export function getOrInitNft(tokenId: string): Nft {
    let nft = Nft.load(tokenId);

    if (!nft) {
        nft = new Nft(tokenId);
        nft.owner = "";
        nft.level = BIGINT_ZERO;
        nft.isGenesis = false;
        nft.idInLevel = BIGINT_ZERO;
        nft.activityEndTimestamp = BIGINT_ZERO;
        nft.extendedActivityEndTimestamp = BIGINT_ZERO;

        nft.save();
    }

    return nft;
}

/**
 * Retrieves or initializes an NFT User entity with a given address.
 * @param userAddress The address of the user.
 * @returns The User entity.
 */
export function getOrInitUser(userAddress: Address): User {
    const userId = userAddress.toHex();
    let user = User.load(userId);

    if (!user) {
        user = new User(userId);

        user.save();
    }

    return user;
}
