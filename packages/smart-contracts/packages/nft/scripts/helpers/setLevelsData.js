const levelsData = require("../data/levelsData.json")

async function setLevelsData() {
    // levelsData.json contains some numbers that are -1, which means that the
    // value is infinite. In order to set the data in the contract, we need to
    // convert those numbers to very high values.

    const USD_DECIMALS = 6
    const SECONDS_IN_MONTH = 30 * 24 * 60 * 60
    const SECONDS_IN_YEAR = 12 * SECONDS_IN_MONTH
    const MILLION_YEARS = 1_000_000 * SECONDS_IN_YEAR
    const MAX_UINT256 = ethers.MaxUint256

    for (let i = 0; i < levelsData.length; i++) {
        /*//////////////////////////////////////////////////////////////////////////
                              SET LEVELS DATA
        //////////////////////////////////////////////////////////////////////////*/

        const data = levelsData[i]

        const price = ethers.parseUnits(
            data.price_in_usd.toString(),
            USD_DECIMALS,
        )

        const vestingRewards = ethers.parseEther(
            data.vesting_rewards_in_wow.toString(),
        )

        const lifecycleDuration =
            data.lifecycle_duration_in_months === -1
                ? MILLION_YEARS
                : data.lifecycle_duration_in_months * SECONDS_IN_MONTH

        const extensionDuration =
            data.extension_duration_in_months === -1
                ? MILLION_YEARS
                : data.extension_duration_in_months * SECONDS_IN_MONTH

        const allocationPerProject = ethers.parseUnits(
            data.allocation_per_project_in_usd.toString(),
            USD_DECIMALS,
        )

        const supplyCap = data.supply_cap === -1 ? MAX_UINT256 : data.supply_cap

        const tx4 = await nft.setLevelData(
            data.level,
            data.isGenesis,
            price,
            vestingRewards,
            lifecycleDuration,
            extensionDuration,
            allocationPerProject,
            supplyCap,
            data.base_uri,
        )

        await tx4.wait()
        console.log(`Level ${data.level} data set`)
    }
}

module.exports = setLevelsData
