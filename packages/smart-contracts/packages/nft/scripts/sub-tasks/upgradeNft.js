const upgradeNft = require("../helpers/upgradeNft")
const { verifyNft } = require("./verifyContracts")
require("dotenv").config()

async function main() {
    const nftProxyAddress = process.env.NFT_PROXY_ADDRESS

    await upgradeNft(nftProxyAddress)

    await verifyNft(nftProxyAddress)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
