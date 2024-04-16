const mintGenesisNfts = require("../helpers/mintGenesisNfts")
require("dotenv").config()

async function main() {
    await mintGenesisNfts(process.env.NFT_SALE_CONTRACT)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
