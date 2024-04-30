const deployVesting = require("./helpers/deployVesting")
const addVestingPools = require("./helpers/addVestingPools")
const verifyVesting = require("./helpers/verifyVesting")
const copyTokenContracts = require("./helpers/copyTokenContracts")
const removeTokenContracts = require("./helpers/removeTokenContracts")
const getNetworkConfig = require("./helpers/getNetworkConfig")

async function main() {
    // Copy contract from token package to allow access to token functions
    await copyTokenContracts()

    // Get config for the current network
    const { vestingToken, stakingContract, listingDate } =
        await getNetworkConfig()

    /*//////////////////////////////////////////////////////////////////////////
                                  DEPLOY VESTING
    //////////////////////////////////////////////////////////////////////////*/

    const vestingAddress = await deployVesting(
        vestingToken,
        stakingContract,
        listingDate,
    )

    /*//////////////////////////////////////////////////////////////////////////
                                  ADD VESTING POOLS
    //////////////////////////////////////////////////////////////////////////*/

    await addVestingPools(vestingToken, vestingAddress)

    /*//////////////////////////////////////////////////////////////////////////
                                  VERIFY VESTING
    //////////////////////////////////////////////////////////////////////////*/

    await verifyVesting(vestingAddress)

    // Remove temp folders
    await removeTokenContracts()
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
