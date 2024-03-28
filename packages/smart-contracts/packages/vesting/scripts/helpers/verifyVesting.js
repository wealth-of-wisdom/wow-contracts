const { run, network } = require("hardhat")

async function verifyVesting(vestingAddress) {
    if (network.name === "hardhat") {
        console.log("Skipping contract verification on local node")
        return
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  VERIFY CONTRACT
    //////////////////////////////////////////////////////////////////////////*/

    await run("verify:verify", {
        address: vestingAddress,
        contract: "contracts/Vesting.sol:Vesting",
    })
}

module.exports = verifyVesting
