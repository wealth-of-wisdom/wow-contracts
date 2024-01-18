const { ethers, upgrades } = require("hardhat")
const levelsData = require("./levelsData.json")
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
        process.env.MAX_LEVEL,
        process.env.VESTING_POOL_ID,
        process.env.GENESIS_TOKEN_DIVISOR,
    ])
    await nft.waitForDeployment()
    const nftAddress = await nft.getAddress()
    console.log("NFT deployed to:", await nftAddress)

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
    console.log("NFT Sale deployed to:", await nftSaleAddress)

    /*//////////////////////////////////////////////////////////////////////////
                                GET VESTING CONTRACT
    //////////////////////////////////////////////////////////////////////////*/

    const Vesting = await ethers.getContractFactory("Vesting")
    const vesting = Vesting.attach(process.env.VESTING_CONTRACT)

    /*//////////////////////////////////////////////////////////////////////////
                                GRANT PERMISSIONS
    //////////////////////////////////////////////////////////////////////////*/

    const MINTER_ROLE = await nft.MINTER_ROLE()
    const NFT_DATA_MANAGER_ROLE = await nft.NFT_DATA_MANAGER_ROLE()
    const BENEFICIARIES_MANAGER_ROLE =
        await vesting.BENEFICIARIES_MANAGER_ROLE()

    const tx1 = await nft.grantRole(MINTER_ROLE, nftSaleAddress)
    await tx1.wait()
    console.log("MINTER_ROLE granted to:", nftSaleAddress)

    const tx2 = await nft.grantRole(NFT_DATA_MANAGER_ROLE, nftSaleAddress)
    await tx2.wait()
    console.log("NFT_DATA_MANAGER_ROLE granted to:", nftSaleAddress)

    const tx3 = await vesting.grantRole(
        BENEFICIARIES_MANAGER_ROLE,
        nftSaleAddress,
    )
    await tx3.wait()
    console.log("BENEFICIARIES_MANAGER_ROLE granted to:", nftSaleAddress)

    /*//////////////////////////////////////////////////////////////////////////
                              SET 1-5 LEVELS DATA
    //////////////////////////////////////////////////////////////////////////*/

    for (let i = 0; i < levelsData.length; i++) {
        const data = levelsData[i]
        const price = ethers.parseUnits(data.price_in_usd.toString(), 6)
        const vestingRewards = ethers.parseEther(
            data.vesting_rewards_in_wow.toString(),
        )
        const lifecycleDuration =
            data.lifecycle_duration_in_months == -1
                ? ethers.MaxUint256
                : data.lifecycle_duration_in_months * 30 * 24 * 60 * 60 // seconds
        const extensionDuration =
            data.extension_duration_in_months == -1
                ? ethers.MaxUint256
                : data.extension_duration_in_months * 30 * 24 * 60 * 60 // seconds
        const allocationPerProject = ethers.parseUnits(
            data.allocation_per_project_in_usd.toString(),
            6,
        )

        const tx4 = await nft.setLevelData(
            data.level,
            price,
            vestingRewards,
            lifecycleDuration,
            extensionDuration,
            allocationPerProject,
            data.main_base_uri,
            data.genesis_base_uri,
        )
        await tx4.wait()
        console.log(`Level ${data.level} data set`)
    }

    console.log("Done!")
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
