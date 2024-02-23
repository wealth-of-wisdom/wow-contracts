const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

async function main() {
    const Staking = await ethers.getContractFactory("Staking")
    const staking = await upgrades.deployProxy(Staking, [
        process.env.USDT_TOKEN,
        process.env.USDC_TOKEN,
        process.env.WOW_TOKEN,
        process.env.TOTAL_POOLS,
        process.env.TOTAL_BAND_LEVELS,
    ])
    await staking.waitForDeployment()
    console.log("Staking deployed to:", await staking.getAddress())
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
