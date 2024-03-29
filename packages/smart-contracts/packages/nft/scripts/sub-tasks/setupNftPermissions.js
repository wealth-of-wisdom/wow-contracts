const setupNftPermissions = require("../helpers/setupNftPermissions")
require("dotenv").config()

async function main() {
    await setupNftPermissions(
        process.env.NFT_CONTRACT,
        process.env.NFT_SALE_CONTRACT,
    )
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
