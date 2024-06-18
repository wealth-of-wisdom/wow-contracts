const { network } = require("hardhat")
const treasuryPoolsDataDev = require("../data/dev/treasuryVestingPools.json")
const treasuryPoolsDataProd = require("../data/prod/treasuryVestingPools.json")
const { addVestingPools } = require("../helpers/addVestingPools")
const copyTokenContracts = require("../helpers/copyTokenContracts")
const removeTokenContracts = require("../helpers/removeTokenContracts")
const { MAINNET_NETWORKS } = require("../helpers/constants")
require("dotenv").config()

async function main() {
    // Copy contract from token package to allow access to token functions
    await copyTokenContracts()

    const poolsData = MAINNET_NETWORKS.includes(network.name)
        ? treasuryPoolsDataProd
        : treasuryPoolsDataDev

    // Add vesting pools
    await addVestingPools(
        process.env.VESTING_TOKEN,
        process.env.VESTING_CONTRACT,
        poolsData,
    )

    // Remove temp folders
    await removeTokenContracts()
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
