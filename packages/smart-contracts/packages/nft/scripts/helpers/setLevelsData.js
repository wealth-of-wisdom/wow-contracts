const levelsData = require("../data/levelsData.json")
const { ethers } = require("hardhat")

async function setLevelsData(nftAddress) {
    const Nft = await ethers.getContractFactory("Nft")
    const nft = Nft.attach(nftAddress)

    // levelsData.json contains some numbers that are -1, which means that the
    // value is infinite. In order to set the data in the contract, we need to
    // convert those numbers to very high values.

    const USD_DECIMALS = 6
    const WOW_DECIMALS = 18
    const SECONDS_IN_MONTH = 30 * 24 * 60 * 60
    const SECONDS_IN_YEAR = 12 * SECONDS_IN_MONTH
    const MILLION_YEARS = 1_000_000 * SECONDS_IN_YEAR
    const MAX_UINT256 = ethers.MaxUint256

    /*//////////////////////////////////////////////////////////////////////////
                          SET LEVELS DATA
    //////////////////////////////////////////////////////////////////////////*/

    for (let data of levelsData) {
        const price = ethers.parseUnits(data.price_in_usd, USD_DECIMALS)
        const vestingRewards = ethers.parseUnits(
            data.vesting_rewards_in_wow,
            WOW_DECIMALS,
        )
        const allocationPerProject = ethers.parseUnits(
            data.allocation_per_project_in_usd,
            USD_DECIMALS,
        )

        const lifecycleDuration =
            data.lifecycle_duration_in_months === -1
                ? MILLION_YEARS
                : data.lifecycle_duration_in_months * SECONDS_IN_MONTH

        const extensionDuration =
            data.extension_duration_in_months === -1
                ? MILLION_YEARS
                : data.extension_duration_in_months * SECONDS_IN_MONTH

        const supplyCap = data.supply_cap === -1 ? MAX_UINT256 : data.supply_cap

        const tx = await nft.setLevelData(
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

        await tx.wait()
        console.log(`Level ${data.level} data set`)
    }
}

module.exports = setLevelsData
