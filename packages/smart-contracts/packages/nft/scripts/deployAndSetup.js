const { ethers } = require("hardhat")
const deployNft = require("./helpers/deployNft.js")
const deployNftSale = require("./helpers/deployNftSale.js")
const setupVestingPermissions = require("./helpers/setupVestingPermissions.js")
const setupNftPermissions = require("./helpers/setupNftPermissions.js")
require("dotenv").config()

async function main() {
    /*//////////////////////////////////////////////////////////////////////////
                                  DEPLOY NFT TOKEN
    //////////////////////////////////////////////////////////////////////////*/

    const nftAddress = await deployNft()

    /*//////////////////////////////////////////////////////////////////////////
                                  DEPLOY NFT SALE
    //////////////////////////////////////////////////////////////////////////*/

    const nftSaleAddress = await deployNftSale(nftAddress)

    /*//////////////////////////////////////////////////////////////////////////
                            GRANT PERMISSIONS IN VESTING
    //////////////////////////////////////////////////////////////////////////*/

    await setupVestingPermissions(nftSaleAddress)

    /*//////////////////////////////////////////////////////////////////////////
                              GRANT PERMISSIONS IN NFT
    //////////////////////////////////////////////////////////////////////////*/

    await setupNftPermissions(nftAddress, nftSaleAddress)

    /*//////////////////////////////////////////////////////////////////////////
                                    SET LEVELS
    //////////////////////////////////////////////////////////////////////////*/

    // levelsData.json contains some numbers that are -1, which means that the
    // value is infinite. In order to set the data in the contract, we need to
    // convert those numbers to very high values.

    const USD_DECIMALS = 6
    const SECONDS_IN_MONTH = 30 * 24 * 60 * 60
    const SECONDS_IN_YEAR = 12 * SECONDS_IN_MONTH
    const MILLION_YEARS = 1_000_000 * SECONDS_IN_YEAR
    const MAX_UINT16 = 65535
    const MAX_UINT256 = ethers.MaxUint256
    const projectsQuantities = [[], [], []]

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

        /*//////////////////////////////////////////////////////////////////////////
                              SET PROJECTS QUANTITY DATA
        //////////////////////////////////////////////////////////////////////////*/
        // NOTE: no projects set for NFT stage
        // const standardQuantity =
        //     data.standard_projects_quantity === -1
        //         ? MAX_UINT16
        //         : data.standard_projects_quantity
        // const premiumQuantity =
        //     data.premium_projects_quantity === -1
        //         ? MAX_UINT16
        //         : data.premium_projects_quantity
        // const limitedQuantity =
        //     data.limited_projects_quantity === -1
        //         ? MAX_UINT16
        //         : data.limited_projects_quantity

        // projectsQuantities[0].push(standardQuantity) // standard
        // projectsQuantities[1].push(premiumQuantity) // premium
        // projectsQuantities[2].push(limitedQuantity) // limited
    }

    /*//////////////////////////////////////////////////////////////////////////
                            SET PROJECTS QUANTITY DATA
    //////////////////////////////////////////////////////////////////////////*/

    // NOTE: no projects set for NFT stage
    // for (let i = 0; i < 3; i++) {
    //     const quantities = projectsQuantities[i]
    //     const tx5 = await nft.setMultipleProjectsQuantity(false, i, quantities)
    //     await tx5.wait()

    //     console.log(`Project type ${i} quantities set`)
    // }
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
