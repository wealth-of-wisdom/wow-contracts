const nftData = require("../data/nftData.json")
const { ethers } = require("hardhat")

async function mintAndSetNftData(nftAddress) {
    const Nft = await ethers.getContractFactory("Nft")
    const nft = Nft.attach(nftAddress)

    /*//////////////////////////////////////////////////////////////////////////
                                    MINT NFT
    //////////////////////////////////////////////////////////////////////////*/

    for (let data of nftData) {
        const tx = await nft.mintAndSetNftData(data.wallet, data.level, false)

        await tx.wait()
        console.log(`Receiver ${data.wallet} - level ${data.level} data set`)
    }
}

module.exports = mintAndSetNftData
