const { run, network } = require("hardhat")

async function verifyToken(tokenAddress) {
    if (network.name === "hardhat") {
        console.log("Skipping contract verification on local node")
        return
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  VERIFY CONTRACT
    //////////////////////////////////////////////////////////////////////////*/

    await run("verify:verify", {
        address: tokenAddress,
        contract: "contracts/WOWToken.sol:WOWToken",
    })
}

module.exports = verifyToken
