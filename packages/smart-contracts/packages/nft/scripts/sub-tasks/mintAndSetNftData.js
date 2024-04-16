const mintAndSetNftData = require("../helpers/mintAndSetNftData")
require("dotenv").config()

async function main() {
    await mintAndSetNftData(process.env.NFT_CONTRACT)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
