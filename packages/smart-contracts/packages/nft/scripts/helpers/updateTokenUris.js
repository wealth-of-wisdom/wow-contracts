const { ethers } = require("hardhat")
const tokenData = require("../data/tokenUpdateDataV2.json")

// Pre-load and map levels to URIs
const levels = tokenData.levels
const levelToUriMap = levels.reduce((map, levelInfo) => {
    map[levelInfo.level] = levelInfo.uri
    return map
}, {})

async function updateTokenUris(nftAddress) {
    const Nft = await ethers.getContractFactory("Nft")
    const nft = Nft.attach(nftAddress)

    /*//////////////////////////////////////////////////////////////////////////
                                    CHANGE TOKEN URI
    //////////////////////////////////////////////////////////////////////////*/

    for (let token of tokenData.tokens) {
        const baseUri = levelToUriMap[token.level]
        const fullUri = `${baseUri}/${token.idInLevel}.json`

        console.log(
            `Updating token ID ${token.id} at level ${token.level} to new URI ${fullUri}`,
        )

        try {
            const tx = await nft.setTokenURI(token.id, fullUri)
            await tx.wait()
            console.log(`Token ID ${token.id} updated to ${fullUri}`)
        } catch (error) {
            console.error(
                `Failed to update token ID ${token.id} with URI ${fullUri}: ${error.message}`,
            )
        }
    }
}

module.exports = updateTokenUris
