const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

async function main() {
    const Vesting = await ethers.getContractFactory("Vesting")
    const vesting = await upgrades.deployProxy(Vesting, [
        process.env.VESTING_TOKEN,
        process.env.STAKING_CONTRACT,
        process.env.LISTING_DATE,
    ])
    await vesting.waitForDeployment()
    console.log("Vesting deployed to:", await vesting.getAddress())
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
