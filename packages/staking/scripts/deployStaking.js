const { ethers, upgrades } = require("hardhat")
const poolData = require("./poolData.json")
const bandLevelData = require("./bandLevelData.json")
require("dotenv").config()

async function main() {
    /*//////////////////////////////////////////////////////////////////////////
                                  DEPLOY STAKING
    //////////////////////////////////////////////////////////////////////////*/

    const Staking = await ethers.getContractFactory("Staking")
    const staking = await upgrades.deployProxy(Staking, [
        process.env.USDT_TOKEN,
        process.env.USDC_TOKEN,
        process.env.WOW_TOKEN,
        process.env.TOTAL_POOLS,
        process.env.TOTAL_BAND_LEVELS,
    ])
    await staking.waitForDeployment()
    console.log("Staking deployed to:", await staking.getAddress())

    /*//////////////////////////////////////////////////////////////////////////
                                GRANT PERMISSIONS
    //////////////////////////////////////////////////////////////////////////*/
    const VESTING_ROLE = await staking.VESTING_ROLE()
    const tx1 = await staking.grantRole(
        VESTING_ROLE,
        process.env.VESTING_ADDRESS,
    )
    await tx1.wait()
    console.log("VESTING_ROLE granted to:", process.env.VESTING_ADDRESS)

    const GELATO_EXECUTOR_ROLE = await staking.GELATO_EXECUTOR_ROLE()
    const tx2 = await staking.grantRole(
        GELATO_EXECUTOR_ROLE,
        process.env.GELATO_ADDRESS,
    )
    await tx2.wait()
    console.log("GELATO_EXECUTOR_ROLE granted to:", process.env.GELATO_ADDRESS)

    /*//////////////////////////////////////////////////////////////////////////
                              SET POOLS
    //////////////////////////////////////////////////////////////////////////*/
    for (let i = 0; i < poolData.length; i++) {
        const data = poolData[i]
        const tx3 = await staking.setPool(data.id, data.distributionPercentage)
        await tx3.wait()
        console.log(`Pool ${data.id} data set`)
    }

    /*//////////////////////////////////////////////////////////////////////////
                              SET BAND LEVEL DATA
    //////////////////////////////////////////////////////////////////////////*/
    const WOW_DECIMALS = 1e18
    for (let i = 0; i < bandLevelData.length; i++) {
        const data = bandLevelData[i]
        const bandLevelPriceInWoWTokens =
            BigInt(bandLevelData[i].price) * BigInt(WOW_DECIMALS)
        const tx4 = await staking.setBandLevel(
            data.level,
            bandLevelPriceInWoWTokens,
            data.accessiblePools,
        )
        await tx4.wait()
        console.log(`Band level ${data.level} data set`)
    }

    /*//////////////////////////////////////////////////////////////////////////
                              SET SHARES IN MONTH
    //////////////////////////////////////////////////////////////////////////*/
    //@todo: move?
    const sharesArray = [
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
        21, 22, 23, 24,
    ]
    const tx5 = await staking.setSharesInMonth(sharesArray)
    await tx5.wait()
    console.log(`Shares in month set`)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
