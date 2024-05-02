const { ethers, upgrades, network } = require("hardhat")
const { TESTNET_NETWORKS, MAINNET_NETWORKS } = require("./constants")

async function upgradeStaking(stakingProxyAddress) {
    /*//////////////////////////////////////////////////////////////////////////
                                  UPGRADE STAKING
    //////////////////////////////////////////////////////////////////////////*/

    let stakingContractName = ""
    if (TESTNET_NETWORKS.includes(network.name)) {
        stakingContractName = "StakingMock"
    } else if (MAINNET_NETWORKS.includes(network.name)) {
        stakingContractName = "Staking"
    } else {
        throw new Error("Network not supported")
    }

    const Staking = await ethers.getContractFactory(stakingContractName)
    const staking = await upgrades.upgradeProxy(stakingProxyAddress, Staking)
    await staking.waitForDeployment()

    console.log("Proxy upgraded to new implementation")
}

module.exports = upgradeStaking
