const { ethers, upgrades } = require("hardhat")
const getNetworkConfig = require("./getNetworkConfig.js")

async function deployStaking() {
    const {
        usdtToken,
        usdcToken,
        wowToken,
        vestingContract,
        gelatoAddress,
        totalPools,
        totalBandLevels,
    } = await getNetworkConfig()

    /*//////////////////////////////////////////////////////////////////////////
                                  DEPLOY STAKING
    //////////////////////////////////////////////////////////////////////////*/

    const Staking = await ethers.getContractFactory("Staking")
    const staking = await upgrades.deployProxy(Staking, [
        usdtToken,
        usdcToken,
        wowToken,
        vestingContract,
        gelatoAddress,
        totalPools,
        totalBandLevels,
    ])
    await staking.waitForDeployment()

    const stakingAddress = await staking.getAddress()
    console.log("Staking deployed to: ", stakingAddress)

    return stakingAddress
}

module.exports = deployStaking
