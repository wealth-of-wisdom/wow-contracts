const genesisNftData = require("../data/genesisNftData.json")
const { ethers } = require("hardhat")

async function mintGenesisNfts(nftSaleAddress) {
    const NftSale = await ethers.getContractFactory("NftSale")
    const nftSale = NftSale.attach(nftSaleAddress)

    let wallets = []
    let levels = []

    /*//////////////////////////////////////////////////////////////////////////
                                    MINT GENESIS NFT
    //////////////////////////////////////////////////////////////////////////*/
    for (let data of genesisNftData) {
        wallets.push(data.wallet)
        levels.push(data.level)

        console.log(`Receiver ${data.wallet} - level ${data.level} data pushed`)
    }
    const tx = await nftSale.mintGenesisNfts(wallets, levels)

    await tx.wait()
    console.log(`Genesis receiver data set`)
}

module.exports = mintGenesisNfts
