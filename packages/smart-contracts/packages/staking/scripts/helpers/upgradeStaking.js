const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

async function upgradeStaking() {
    /*//////////////////////////////////////////////////////////////////////////
                                  UPGRADE STAKING
    //////////////////////////////////////////////////////////////////////////*/

    const Staking = await ethers.getContractFactory("Staking")
    const staking = await upgrades.upgradeProxy(
        process.env.STAKING_PROXY_ADDRESS,
        Staking,
    )
    await staking.waitForDeployment()

    console.log("Proxy upgraded to new implementation")
}

module.exports = upgradeStaking
