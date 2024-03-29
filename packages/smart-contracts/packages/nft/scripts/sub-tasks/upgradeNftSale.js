const upgradeNftSale = require("../helpers/upgradeNftSale")
require("dotenv").config()

async function main() {
    await upgradeNftSale(process.env.NFT_SALE_PROXY_CONTRACT)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
