const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

async function main() {
    const NftSale = await ethers.getContractFactory("NftSale")
    const sale = await upgrades.upgradeProxy(
        process.env.NFT_SALE_PROXY,
        NftSale,
    )
    await sale.waitForDeployment()
    console.log("NFT Sale upgraded")
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
