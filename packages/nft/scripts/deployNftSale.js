const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

async function main() {
    const NftSale = await ethers.getContractFactory("NftSale")
    const sale = await upgrades.deployProxy(NftSale, [
        process.env.USDT_TOKEN,
        process.env.USDC_TOKEN,
        process.env.NFT_CONTRACT,
        process.env.VESTING_CONTRACT,
        process.env.PID
    ])
    await sale.waitForDeployment()
    console.log("NFT Sale deployed to:", await sale.getAddress())
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
