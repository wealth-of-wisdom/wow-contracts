const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

async function main() {
    const Nft = await ethers.getContractFactory("Nft")
    const nft = await upgrades.deployProxy(Nft, [
        process.env.NFT_NAME,
        process.env.NFT_SYMBOL,
        process.env.VESTING_CONTRACT,
        process.env.MAX_LEVEL,
        process.env.VESTING_POOL_ID,
        process.env.GENESIS_TOKEN_DIVISOR,
    ])
    await nft.waitForDeployment()
    console.log("NFT deployed to:", await nft.getAddress())
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
