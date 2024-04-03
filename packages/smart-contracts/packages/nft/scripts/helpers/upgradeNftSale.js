const { ethers, upgrades } = require("hardhat")

async function upgradeNftSale(nftSaleProxyAddress) {
    if (!nftSaleProxyAddress) {
        throw new Error("ERROR: NFT Sale proxy address not found")
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  UPGRADE NFT SALE
    //////////////////////////////////////////////////////////////////////////*/

    const NftSale = await ethers.getContractFactory("NftSale")
    const sale = await upgrades.upgradeProxy(nftSaleProxyAddress, NftSale)
    await sale.waitForDeployment()

    console.log("NFT Sale upgraded with proxy address: ", nftSaleProxyAddress)
}

module.exports = upgradeNftSale
