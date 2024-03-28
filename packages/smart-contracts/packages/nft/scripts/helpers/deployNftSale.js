const { ethers, upgrades } = require("hardhat")
const getNetworkConfig = require("./getNetworkConfig.js")

async function deployNftSale(nftContractAddress) {
    const { usdtToken, usdcToken } = await getNetworkConfig()

    /*//////////////////////////////////////////////////////////////////////////
                                  DEPLOY NFT SALE
    //////////////////////////////////////////////////////////////////////////*/

    const NftSale = await ethers.getContractFactory("NftSale")
    const nftSale = await upgrades.deployProxy(NftSale, [
        usdtToken,
        usdcToken,
        nftContractAddress,
    ])
    await nftSale.waitForDeployment()

    const nftSaleAddress = await sale.getAddress()
    console.log("NFT Sale deployed to:", nftSaleAddress)

    return nftSaleAddress
}

module.exports = deployNftSale
