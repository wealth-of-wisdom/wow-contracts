const deployNft = require("../helpers/deployNft")
require("dotenv").config()

async function main() {
    await deployNft(
        process.env.NFT_NAME,
        process.env.NFT_SYMBOL,
        process.env.VESTING_CONTRACT,
        process.env.VESTING_POOL_ID,
        process.env.MAX_LEVEL,
        process.env.TOTAL_PROJECT_TYPES,
    )
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
