const { ethers } = require("hardhat")

async function stake(stakingAddress, stakingType, bandLevel, fixedMonths) {
    const staking = await ethers.getContractAt("Staking", stakingAddress)

    const decodedError = staking.interface.parseError("0x29b850ae")
    console.log(decodedError) // "error name"

    // Stake WOW tokens and purchase band
    const stakeTx = await staking.stake(stakingType, bandLevel, fixedMonths)
    console.log(stakeTx.hash)
    await stakeTx.wait()
    console.log(`Staked WOW tokens`)
}

module.exports = stake
