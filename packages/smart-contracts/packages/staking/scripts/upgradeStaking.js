<<<<<<< HEAD
const { network } = require("hardhat")
=======
const upgradeStaking = require("./helpers/upgradeStaking")
const deployStakingImplementation = require("./helpers/deployStakingImplementation")
>>>>>>> fix/staking-verification
require("dotenv").config()
const upgradeStaking = require("./helpers/upgradeStaking")
const verifyStaking = require("./helpers/verifyStaking")

async function main() {
    /*//////////////////////////////////////////////////////////////////////////
                                CHECK NETWORK
    //////////////////////////////////////////////////////////////////////////*/

    let stakingContractName = ""
    if (network.name === "sepolia" || network.name === "arbitrumSepolia") {
        stakingContractName = "StakingMock"
    } else if (network.name === "ethereum" || network.name === "arbitrumOne") {
        stakingContractName = "Staking"
    } else {
        throw new Error("Network not supported")
    }
    /*//////////////////////////////////////////////////////////////////////////
                                UPGRADE STAKING
    //////////////////////////////////////////////////////////////////////////*/

    await upgradeStaking(process.env.STAKING_PROXY_ADDRESS, stakingContractName)

    /*//////////////////////////////////////////////////////////////////////////
                                      VERIFY STAKING
    //////////////////////////////////////////////////////////////////////////*/

    await verifyStaking(process.env.STAKING_PROXY_ADDRESS)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
