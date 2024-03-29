const { run, network } = require("hardhat")

async function verifyStaking(stakingAddress) {
    if (network.name === "hardhat") {
        console.log("Skipping contract verification on local node")
        return
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  VERIFY CONTRACT
    //////////////////////////////////////////////////////////////////////////*/

    await run("verify:verify", {
        address: stakingAddress,
        contract: "contracts/Staking.sol:Staking",
    })
}

module.exports = verifyStaking
