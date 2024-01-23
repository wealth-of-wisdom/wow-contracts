const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

async function main() {
    const Nft = await ethers.getContractFactory("Nft")
    const nft = await upgrades.upgradeProxy(process.env.NFT_PROXY, Nft)
    await nft.waitForDeployment()
    console.log("NFT upgraded")
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
