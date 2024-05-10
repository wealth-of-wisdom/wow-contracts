const { ethers } = require("hardhat");
const tokenData = require("../data/tokenUpdateData.json");

// Pre-load and map levels to URIs
const levels = tokenData.levels;
const levelToUriMap = levels.reduce((map, levelInfo) => {
    map[levelInfo.level] = levelInfo.uri;
    return map;
}, {});

async function updateTokenUris(nftAddress) {
    if (!nftAddress) {
        throw new Error("ERROR: NFT proxy address not found");
    }

    const Nft = await ethers.getContractFactory("Nft");
    const nft = Nft.attach(nftAddress);

    /*//////////////////////////////////////////////////////////////////////////
                                    CHANGE TOKEN URI
    //////////////////////////////////////////////////////////////////////////*/

    for (let token of tokenData.tokens) {


        const baseUri = levelToUriMap[token.level];
        const fullUri = `${baseUri}/${token.id}.json`;

        console.log(`Updating token ID ${token.id} at level ${token.level} to new URI ${uri}`);

        try {
            const tx = await nft.setTokenURI(token.id, fullUri);
            await tx.wait();
            console.log(`Token ID ${token.id} updated to ${fullUri}`);
        } catch (error) {
            console.error(`Failed to update token ID ${token.id} with URI ${fullUri}: ${error.message}`);
        }
    }
}

module.exports = updateTokenUris;