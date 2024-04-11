const { ethers } = require("hardhat")

async function createDistribution(
    stakingAddress,
    tokenAddress,
    distributionAmount,
) {
    const staking = await ethers.getContractAt("Staking", stakingAddress)

    // Create distribution
    const distributionTx = await staking.createDistribution(
        tokenAddress,
        distributionAmount,
    )
    await distributionTx.wait()
    console.log(`Created distribution`)
}

module.exports = createDistribution
