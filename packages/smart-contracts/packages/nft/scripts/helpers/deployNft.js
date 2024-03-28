const { ethers, upgrades } = require("hardhat")
const getNetworkConfig = require("./getNetworkConfig.js")

async function deployNft() {
    const {
        nftName,
        nftSymbol,
        vestingContract,
        vestingPoolId,
        maxLevel,
        totalProjectTypes,
    } = await getNetworkConfig()

    /*//////////////////////////////////////////////////////////////////////////
                                    DEPLOY NFT
    //////////////////////////////////////////////////////////////////////////*/

    const Nft = await ethers.getContractFactory("Nft")
    const nft = await upgrades.deployProxy(Nft, [
        nftName,
        nftSymbol,
        vestingContract,
        vestingPoolId,
        maxLevel,
        totalProjectTypes,
    ])
    await nft.waitForDeployment()

    const nftAddress = await nft.getAddress()
    console.log("NFT deployed to:", nftAddress)

    return nftAddress
}

module.exports = deployNft
