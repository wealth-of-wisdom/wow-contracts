const addVestingPools = require("../helpers/addVestingPools")
require("dotenv").config()

async function main() {
    await addVestingPools(
        process.env.VESTING_TOKEN,
        process.env.VESTING_CONTRACT,
        process.env.FULL_POOL_TOKEN_AMOUNT,
    )
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
