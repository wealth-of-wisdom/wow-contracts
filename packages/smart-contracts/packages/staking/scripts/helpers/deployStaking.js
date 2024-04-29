const { ethers, upgrades, network } = require("hardhat")
const { TESTNET_NETWORKS, MAINNET_NETWORKS } = require("./constants")

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

    let StakingContractName = ""
    if (TESTNET_NETWORKS.includes(network.name)) {
        StakingContractName = "StakingMock"
    } else if (MAINNET_NETWORKS.includes(network.name)) {
        StakingContractName = "Staking"
    } else {
        throw new Error("Network not supported")
    }

    const Staking = await ethers.getContractFactory(StakingContractName)
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
