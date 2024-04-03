const deployStaking = require("../helpers/deployStaking")
require("dotenv").config()

async function main() {
    await deployStaking(
        process.env.USDT_TOKEN,
        process.env.USDC_TOKEN,
        process.env.WOW_TOKEN,
        process.env.VESTING_ADDRESS,
        process.env.GELATO_ADDRESS,
        process.env.TOTAL_POOLS,
        process.env.TOTAL_BAND_LEVELS,
    )
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
