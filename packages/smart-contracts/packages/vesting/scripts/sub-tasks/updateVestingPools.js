const { updateVestingPoolsFromFile } = require("../helpers/updateVestingPools")
const copyTokenContracts = require("../helpers/copyTokenContracts")
const removeTokenContracts = require("../helpers/removeTokenContracts")
require("dotenv").config()

async function main() {
    // Copy contract from token package to allow access to token functions
    await copyTokenContracts()

    // Update vesting pools
    await updateVestingPoolsFromFile(
        process.env.VESTING_TOKEN,
        process.env.VESTING_CONTRACT,
    )

    // Remove temp folders
    await removeTokenContracts()
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
