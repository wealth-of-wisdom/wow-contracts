const { run, network } = require("hardhat")

async function verifyContracts(nftAddress, nftSaleAddress) {
    if (network.name === "hardhat") {
        console.log("Skipping contract verification on local node")
        return
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  VERIFY CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    await run("verify:verify", {
        address: nftAddress,
        contract: "contracts/Nft.sol:Nft",
    })

    await run("verify:verify", {
        address: nftSaleAddress,
        contract: "contracts/NftSale.sol:NftSale",
    })
}

module.exports = verifyContracts
