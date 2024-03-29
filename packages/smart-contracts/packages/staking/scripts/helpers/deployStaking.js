const { ethers, upgrades } = require("hardhat")

async function deployStaking(
    usdtToken,
    usdcToken,
    wowToken,
    vestingContract,
    gelatoAddress,
    totalPools,
    totalBandLevels,
) {
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
