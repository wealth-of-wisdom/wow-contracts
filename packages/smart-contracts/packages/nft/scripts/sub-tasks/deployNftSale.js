const deployNftSale = require("../helpers/deployNftSale")
require("dotenv").config()

async function main() {
    await deployNftSale(
        process.env.NFT_CONTRACT,
        process.env.USDT_TOKEN,
        process.env.USDC_TOKEN,
    )
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
