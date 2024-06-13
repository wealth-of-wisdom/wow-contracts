// @ts-ignore
const { ethers, upgrades } = require("hardhat")

async function upgradeVesting(vestingProxyAddress) {
    if (!vestingProxyAddress) {
        throw new Error("ERROR: Vesting proxy address not found")
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    UPGRADE VESTING
    //////////////////////////////////////////////////////////////////////////*/

    const Vesting = await ethers.getContractFactory("Vesting")
    const vesting = await upgrades.upgradeProxy(vestingProxyAddress, Vesting)
    await vesting.waitForDeployment()

    console.log("Vesting upgraded with proxy address: ", vestingProxyAddress)
}

module.exports = upgradeVesting
