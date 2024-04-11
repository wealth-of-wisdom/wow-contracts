const stake = require("../helpers/stake")
require("dotenv").config()

async function main() {
    await stake(
        process.env.STAKING_ADDRESS,
        process.env.STAKING_TYPE,
        process.env.BAND_LEVEL,
        process.env.FIXED_MONTHS,
    )
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
