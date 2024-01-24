const { ethers, upgrades } = require("hardhat")
const levelsData = require("./levelsDataTest.json")
require("dotenv").config()

async function main() {
    /*//////////////////////////////////////////////////////////////////////////
                                  DEPLOY NFT TOKEN
    //////////////////////////////////////////////////////////////////////////*/

    const Nft = await ethers.getContractFactory("Nft")
    const nft = await upgrades.deployProxy(Nft, [
        process.env.NFT_NAME,
        process.env.NFT_SYMBOL,
        process.env.VESTING_CONTRACT,
        process.env.LEVEL5_SUPPLY_CAP,
        process.env.VESTING_POOL_ID,
        process.env.MAX_LEVEL,
        process.env.TOTAL_PROJECT_TYPES,
    ])
    await nft.waitForDeployment()
    const nftAddress = await nft.getAddress()
    console.log("NFT deployed to:", nftAddress)

    /*//////////////////////////////////////////////////////////////////////////
                                  DEPLOY NFT SALE
    //////////////////////////////////////////////////////////////////////////*/

    const NftSale = await ethers.getContractFactory("NftSale")
    const nftSale = await upgrades.deployProxy(NftSale, [
        process.env.USDT_TOKEN,
        process.env.USDC_TOKEN,
        nftAddress,
    ])
    await nftSale.waitForDeployment()
    const nftSaleAddress = await nftSale.getAddress()
    console.log("NFT Sale deployed to:", nftSaleAddress)

    /*//////////////////////////////////////////////////////////////////////////
                                GET VESTING CONTRACT
    //////////////////////////////////////////////////////////////////////////*/
    //NOTE: no Vesting deployed for NFT stage
    // const Vesting = await ethers.getContractFactory("Vesting")
    // const vesting = Vesting.attach(process.env.VESTING_CONTRACT)

    /*//////////////////////////////////////////////////////////////////////////
                                GRANT PERMISSIONS
    //////////////////////////////////////////////////////////////////////////*/

    const MINTER_ROLE = await nft.MINTER_ROLE()
    const NFT_DATA_MANAGER_ROLE = await nft.NFT_DATA_MANAGER_ROLE()
    //NOTE: no Vesting deployed for NFT stage
    // const BENEFICIARIES_MANAGER_ROLE =
    //     await vesting.BENEFICIARIES_MANAGER_ROLE()

    const tx1 = await nft.grantRole(MINTER_ROLE, nftSaleAddress)
    await tx1.wait()
    console.log("MINTER_ROLE granted to:", nftSaleAddress)

    const tx2 = await nft.grantRole(NFT_DATA_MANAGER_ROLE, nftSaleAddress)
    await tx2.wait()
    console.log("NFT_DATA_MANAGER_ROLE granted to:", nftSaleAddress)

    //NOTE: no Vesting deployed for NFT stage
    // const tx3 = await vesting.grantRole(
    //     BENEFICIARIES_MANAGER_ROLE,
    //     nftSaleAddress,
    // )
    // await tx3.wait()
    // console.log("BENEFICIARIES_MANAGER_ROLE granted to:", nftSaleAddress)

    // levelsData.json contains some numbers that are -1, which means that the
    // value is infinite. In order to set the data in the contract, we need to
    // convert those numbers to max uint256 or uint16, which is the maximum value that
    // can be stored in a smart contract.

    /*//////////////////////////////////////////////////////////////////////////
                              SET LEVELS
    //////////////////////////////////////////////////////////////////////////*/

    const USD_DECIMALS = 6
    const SECONDS_IN_YEAR = 12 * SECONDS_IN_MONTH
    const SECONDS_IN_MONTH = 30 * 24 * 60 * 60
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
                ? SECONDS_IN_YEAR * 100000
                : data.lifecycle_duration_in_months * SECONDS_IN_MONTH
        const extensionDuration =
            data.extension_duration_in_months === -1
                ? SECONDS_IN_YEAR * 100000
                : data.extension_duration_in_months * SECONDS_IN_MONTH
        const allocationPerProject = ethers.parseUnits(
            data.allocation_per_project_in_usd.toString(),
            USD_DECIMALS,
        )

        const tx4 = await nft.setLevelData(
            data.level,
            data.isGenesis,
            price,
            vestingRewards,
            lifecycleDuration,
            extensionDuration,
            allocationPerProject,
            data.base_uri,
        )

        await tx4.wait()
        console.log(`Level ${data.level} data set`)

        /*//////////////////////////////////////////////////////////////////////////
                              SET PROJECTS QUANTITY DATA
        //////////////////////////////////////////////////////////////////////////*/
        //NOTE: no projects set for NFT stage
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

    //NOTE: no projects set for NFT stage
    // for (let i = 0; i < 3; i++) {
    //     const quantities = projectsQuantities[i]
    //     const tx5 = await nft.setMultipleProjectsQuantity(false, i, quantities)
    //     await tx5.wait()

    //     console.log(`Project type ${i} quantities set`)
    // }

    console.log("Done!")
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
