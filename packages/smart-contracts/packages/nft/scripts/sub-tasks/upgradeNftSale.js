const upgradeNftSale = require("../helpers/upgradeNftSale")
const { verifyNftSale } = require("./verifyContracts")
require("dotenv").config()

async function main() {
    const nftSaleProxyAddress = process.env.NFT_SALE_PROXY_CONTRACT

    await upgradeNftSale(nftSaleProxyAddress)

    await verifyNftSale(nftSaleProxyAddress)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
