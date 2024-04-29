// scripts/upgrade-box.js
const { ethers, upgrades } = require("hardhat")
const verifyStaking = require("./verifyStaking")

async function deployStakingImplementation() {
    /*//////////////////////////////////////////////////////////////////////////
                                DEPLOY STAKING IMPLEMENTATION
    //////////////////////////////////////////////////////////////////////////*/

    const Staking = await ethers.getContractFactory("Staking")
    const stakingImplementation = await Staking.deploy()
    await stakingImplementation.waitForDeployment()

    const stakingImplementationAddress =
        await stakingImplementation.getAddress()
    console.log(
        "Staking Implementation deployed to: ",
        stakingImplementationAddress,
    )

    /*//////////////////////////////////////////////////////////////////////////
                            VERIFY STAKING IMPLEMENTATION
    //////////////////////////////////////////////////////////////////////////*/

    await verifyStaking(stakingImplementationAddress)

    return stakingImplementationAddress
}

module.exports = deployStakingImplementation
