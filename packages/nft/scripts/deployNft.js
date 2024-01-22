const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

async function main() {
    const Nft = await ethers.getContractFactory("Nft")
    const nft = await upgrades.deployProxy(Nft, [
        process.env.NFT_NAME,
        process.env.NFT_SYMBOL,
        process.env.VESTING_CONTRACT,
        process.env.LEVEL5_SUPPLY_CAP,
        process.env.VESTING_POOL_ID,
        process.env.MAX_LEVEL,
        process.env.TOTAL_PROJECT_TYPES,
    ])
    await nft.waitForDeployment()
    console.log("NFT deployed to:", await nft.getAddress())
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
