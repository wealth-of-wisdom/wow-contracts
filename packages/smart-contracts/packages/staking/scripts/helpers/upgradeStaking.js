const { ethers, upgrades } = require("hardhat")

async function upgradeStaking(stakingProxyAddress) {
    /*//////////////////////////////////////////////////////////////////////////
                                  UPGRADE STAKING
    //////////////////////////////////////////////////////////////////////////*/

    const Staking = await ethers.getContractFactory("Staking")
    const staking = await upgrades.upgradeProxy(stakingProxyAddress, Staking)
    await staking.waitForDeployment()

    console.log("Proxy upgraded to new implementation")
}

module.exports = upgradeStaking
