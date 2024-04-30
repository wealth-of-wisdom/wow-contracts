const { ethers, upgrades } = require("hardhat")

async function upgradeStaking(stakingProxyAddress, stakingContractName) {
    /*//////////////////////////////////////////////////////////////////////////
                                  UPGRADE STAKING
    //////////////////////////////////////////////////////////////////////////*/

    const Staking = await ethers.getContractFactory(stakingContractName)
    const staking = await upgrades.upgradeProxy(stakingProxyAddress, Staking)
    await staking.waitForDeployment()

    console.log("Proxy upgraded to new implementation")
}

module.exports = upgradeStaking
