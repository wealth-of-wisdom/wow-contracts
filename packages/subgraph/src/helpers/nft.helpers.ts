import { Address, BigInt, dataSource } from "@graphprotocol/graph-ts";
import { NftContract, Nft, User } from "../../generated/schema"; // Adjust the import path as necessary
import {
    BIGINT_ZERO,
    ACTIVITY_STATUS_NOT_ACTIVATED,
    ACTIVITY_STATUS_DEACTIVATED,
    ARBITRUM_ONE_NETWORK,
} from "../utils/constants";

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

export function updateActiveNft(userAddress: Address, newTokenId: BigInt): void {
    const user: User = getOrInitUser(userAddress);
    const newNftId: string = newTokenId.toString();

    if (newNftId != user.activeNft) {
        // Update the user's active NFT
        user.activeNft = newNftId;
        user.save();
    }
}

export function updateNftStatusForEdgeCases(userAddress: string, nftId: string): void {
    // This is hardcoded values for the Arbitrum One network to deactivate the old NFTs
    // Because old NFT contract didn't have the NftDeactivated event
    if (dataSource.network() == ARBITRUM_ONE_NETWORK) {
        let oldNft: Nft | null = null;

        if (userAddress == "0xdc8d7f971bef8457b00f0d26a7666fa243045cf2" && nftId == "50") {
            // Tx hash: 0x78ed0bf0c9542ad96a94dca9d7437aea2f791b08d26503a6137fd35726bedc9d
            oldNft = getOrInitNft(BigInt.fromString("28"));
        } else if (userAddress == "0x6a34916648f981b0ce228b47fb913b4ed9b84b83" && nftId == "51") {
            // Tx hash: 0x9ddd8944b99d8d511597f85b2df35e522c9d60987f8b85e9e1b15cffa7689b67
            oldNft = getOrInitNft(BigInt.fromString("9"));
        } else if (userAddress == "0x5adb3f2103df1ee4372001f7829c78683defef94" && nftId == "52") {
            // Tx hash: 0x04389ccd908ff57158d1081a78110330255b2d279176472d1774118984e3df2b
            oldNft = getOrInitNft(BigInt.fromString("3"));
        }

        if (oldNft && oldNft.activityStatus != ACTIVITY_STATUS_DEACTIVATED) {
            oldNft.activityStatus = ACTIVITY_STATUS_DEACTIVATED;
            oldNft.save();
        }
    }
}
