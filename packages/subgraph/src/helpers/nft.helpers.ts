import { Address } from "@graphprotocol/graph-ts";
import { NftContract, Nft, User } from "../../generated/schema"; // Adjust the import path as necessary
import { BIGINT_ZERO } from "../utils/constants";


export function getOrInitNFTContract(contractAddress: Address): NftContract {
    let id = contractAddress.toHexString()
    let nftContract = NftContract.load(id);

    if (!nftContract) {
        
        nftContract = new NftContract(id);
        nftContract.nftContractAddress = contractAddress;

        nftContract.save();
    }

    return nftContract;
}

/**
 * Retrieves or initializes an NFTContract entity.
 * @param nftContractAddress - The address of the Nft.
 * @returns The NFTContract entity.
 */
export function getOrInitNft(tokenId: string): Nft {
    let id = tokenId;
    let nft = Nft.load(id);

    if (!nft) {
        nft = new Nft(id);
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
 * Retrieves or initializes a User entity with a given address.
 * @param userAddress - The Ethereum address of the user.
 * @returns The User entity.
 */
export function getOrInitUser(userAddress: Address): User {
    let userId = userAddress.toHexString();
    let user = User.load(userId);

    if (!user) {
        user = new User(userId);

        user.save();
    }

    return user;
}