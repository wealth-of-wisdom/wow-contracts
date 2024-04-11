const { ethers } = require("hardhat")

async function stake(stakingAddress, stakingType, bandLevel, fixedMonths) {
    const staking = await ethers.getContractAt("Staking", stakingAddress)

    // Stake WOW tokens and purchase band
    const stakeTx = await staking.stake(stakingType, bandLevel, fixedMonths)
    await stakeTx.wait()
    console.log(`Staked WOW tokens`)
}

module.exports = stake
