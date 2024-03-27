const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

async function deployStaking() {
    /*//////////////////////////////////////////////////////////////////////////
                                  DEPLOY STAKING
    //////////////////////////////////////////////////////////////////////////*/

    const Staking = await ethers.getContractFactory("Staking")
    const staking = await upgrades.deployProxy(Staking, [
        process.env.USDT_TOKEN,
        process.env.USDC_TOKEN,
        process.env.WOW_TOKEN,
        process.env.VESTING_ADDRESS,
        process.env.GELATO_ADDRESS,
        process.env.TOTAL_POOLS,
        process.env.TOTAL_BAND_LEVELS,
    ])
    await staking.waitForDeployment()

    const stakingAddress = await staking.getAddress()
    console.log("Staking deployed to: ", stakingAddress)

    return staking
}

module.exports = deployStaking
