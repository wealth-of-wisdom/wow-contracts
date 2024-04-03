const deployVesting = require("../helpers/deployVesting")
require("dotenv").config()

async function main() {
    await deployVesting(
        process.env.VESTING_TOKEN,
        process.env.STAKING_CONTRACT,
        process.env.LISTING_DATE,
    )
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
