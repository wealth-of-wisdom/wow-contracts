const { ethers, upgrades } = require("hardhat")

async function upgradeNft(nftProxyAddress) {
    if (!nftProxyAddress) {
        throw new Error("ERROR: NFT proxy address not found")
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    UPGRADE NFT
    //////////////////////////////////////////////////////////////////////////*/

    const Nft = await ethers.getContractFactory("Nft")
    const nft = await upgrades.upgradeProxy(nftProxyAddress, Nft)
    await nft.waitForDeployment()

    console.log("NFT upgraded with proxy address: ", nftProxyAddress)
}

module.exports = upgradeNft
