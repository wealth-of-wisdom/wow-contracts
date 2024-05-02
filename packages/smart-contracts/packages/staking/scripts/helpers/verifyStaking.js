const { run, network } = require("hardhat")
const { TESTNET_NETWORKS, MAINNET_NETWORKS } = require("./constants")

async function verifyStaking(stakingAddress) {
    if (network.name === "hardhat") {
        console.log("Skipping contract verification on local node")
        return
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  VERIFY CONTRACT
    //////////////////////////////////////////////////////////////////////////*/

    if (MAINNET_NETWORKS.includes(network.name)) {
        await run("verify:verify", {
            address: stakingAddress,
            contract: "contracts/Staking.sol:Staking",
        })
    } else if (TESTNET_NETWORKS.includes(network.name)) {
        await run("verify:verify", {
            address: stakingAddress,
            contract: "contracts/mock/StakingMock.sol:StakingMock",
        })
    } else {
        throw new Error("Network not supported")
    }
}

module.exports = verifyStaking
