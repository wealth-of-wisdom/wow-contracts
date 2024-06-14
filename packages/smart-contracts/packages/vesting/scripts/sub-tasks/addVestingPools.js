const { addVestingPoolsFromFile } = require("../helpers/addVestingPools")
const copyTokenContracts = require("../helpers/copyTokenContracts")
const removeTokenContracts = require("../helpers/removeTokenContracts")
require("dotenv").config()

async function main() {
    // Copy contract from token package to allow access to token functions
    await copyTokenContracts()

    // Add vesting pools
    await addVestingPoolsFromFile(
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
