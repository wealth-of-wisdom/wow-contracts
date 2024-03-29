const { ethers, upgrades } = require("hardhat")

async function deployNftSale(nftContractAddress, usdtToken, usdcToken) {
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

    const nftSaleAddress = await nftSale.getAddress()
    console.log("NFT Sale deployed to:", nftSaleAddress)

    return nftSaleAddress
}

module.exports = deployNftSale
