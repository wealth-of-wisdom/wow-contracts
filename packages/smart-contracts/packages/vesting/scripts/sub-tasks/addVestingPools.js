const addVestingPools = require("../helpers/addVestingPools")
const copyTokenContracts = require("../helpers/copyTokenContracts")
require("dotenv").config()

async function main() {
    // Copy contract from token package to allow access to token functions
    await copyTokenContracts()

    await addVestingPools(
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
