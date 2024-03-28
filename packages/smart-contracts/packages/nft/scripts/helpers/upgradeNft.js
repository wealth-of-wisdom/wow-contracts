const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

async function upgradeNft() {
    const nftProxyAddress = process.env.NFT_PROXY

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
