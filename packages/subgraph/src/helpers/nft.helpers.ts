import { Address, BigInt } from "@graphprotocol/graph-ts";
import { NftContract, Nft, User } from "../../generated/schema"; // Adjust the import path as necessary
import { BIGINT_ZERO, ACTIVITY_STATUS_NOT_ACTIVATED } from "../utils/constants";

/**
 * Retrieves or initializes an NFTContract entity.
 * @returns The NFTContract entity.
 */
export function getOrInitNftContract(): NftContract {
    const id = "0";
    let nftContract = NftContract.load(id);

    if (!nftContract) {
        nftContract = new NftContract(id);
        nftContract.nftContractAddress = Address.zero();

        nftContract.save();
    }

    return nftContract;
}

/**
 * Retrieves or initializes an Nft entity with a given tokenId.
 * @param tokenId The tokenId of the Nft.
 * @returns The Nft entity.
 */
export function getOrInitNft(tokenId: BigInt): Nft {
    const id = tokenId.toString();
    let nft = Nft.load(id);

    if (!nft) {
        nft = new Nft(id);
        nft.idInLevel = BIGINT_ZERO;
        nft.level = BIGINT_ZERO;
        nft.isGenesis = false;
        nft.activityStatus = ACTIVITY_STATUS_NOT_ACTIVATED;
        nft.activityEndTimestamp = BIGINT_ZERO;
        nft.extendedActivityEndTimestamp = BIGINT_ZERO;
        nft.owner = Address.zero().toString();

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
