const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

async function deployVesting(vestingToken, stakingContract, listingDate) {
    const Vesting = await ethers.getContractFactory("Vesting")
    const vesting = await upgrades.deployProxy(Vesting, [
        vestingToken,
        stakingContract,
        listingDate,
    ])
    await vesting.waitForDeployment()

    const vestingAddress = await vesting.getAddress()
    console.log("Vesting deployed to: ", vestingAddress)

    return vestingAddress
}

async function main() {
    await deployVesting(
        process.env.VESTING_TOKEN,
        process.env.STAKING_CONTRACT,
        process.env.LISTING_DATE,
    )
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})

module.exports = {
    deployVesting: deployVesting,
}
