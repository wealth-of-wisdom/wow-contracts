const deployStaking = require("./helpers/deployStaking")
const setPools = require("./helpers/setPools")
const setBandLevels = require("./helpers/setBandLevels")
const setShares = require("./helpers/setShares")
const verifyStaking = require("./helpers/verifyStaking")

async function main() {
    const {
        usdtToken,
        usdcToken,
        wowToken,
        vestingContract,
        gelatoAddress,
        totalPools,
        totalBandLevels,
    } = await getNetworkConfig()

    /*//////////////////////////////////////////////////////////////////////////
                                    DEPLOY STAKING
    //////////////////////////////////////////////////////////////////////////*/

    const stakingAddress = await deployStaking(
        usdtToken,
        usdcToken,
        wowToken,
        vestingContract,
        gelatoAddress,
        totalPools,
        totalBandLevels,
    )

    /*//////////////////////////////////////////////////////////////////////////
                                      SET POOLS
    //////////////////////////////////////////////////////////////////////////*/

    await setPools(stakingAddress)

    /*//////////////////////////////////////////////////////////////////////////
                                    SET BAND LEVELS
    //////////////////////////////////////////////////////////////////////////*/

    await setBandLevels(stakingAddress)

    /*//////////////////////////////////////////////////////////////////////////
                                SET SHARES PER MONTH
    //////////////////////////////////////////////////////////////////////////*/

    await setShares(stakingAddress)

    /*//////////////////////////////////////////////////////////////////////////
                                    VERIFY STAKING
    //////////////////////////////////////////////////////////////////////////*/

    await verifyStaking(stakingAddress)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
