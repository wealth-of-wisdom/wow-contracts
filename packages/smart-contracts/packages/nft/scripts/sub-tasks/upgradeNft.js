const upgradeNft = require("../helpers/upgradeNft")
require("dotenv").config()

async function main() {
    await upgradeNft(process.env.NFT_PROXY_CONTRACT)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
