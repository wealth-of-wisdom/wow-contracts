const { ethers, upgrades } = require("hardhat")
const poolData = require("./poolData.json")
const sharesData = require("./sharesData.json")
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
        process.env.VESTING_ADDRESS,
        process.env.GELATO_ADDRESS,
        process.env.TOTAL_POOLS,
        process.env.TOTAL_BAND_LEVELS,
    ])
    await staking.waitForDeployment()
    console.log("Staking deployed to:", await staking.getAddress())

    /*//////////////////////////////////////////////////////////////////////////
                              SET POOLS
    //////////////////////////////////////////////////////////////////////////*/
    for (let i = 0; i < poolData.length; i++) {
        const data = poolData[i]
        const tx1 = await staking.setPool(data.id, data.distributionPercentage)
        await tx1.wait()
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
        const tx2 = await staking.setBandLevel(
            data.level,
            bandLevelPriceInWoWTokens,
            data.accessiblePools,
        )
        await tx2.wait()
        console.log(`Band level ${data.level} data set`)
    }

    /*//////////////////////////////////////////////////////////////////////////
                              SET SHARES IN MONTH
    //////////////////////////////////////////////////////////////////////////*/
    const sharesArray = sharesData[0].shares
    const tx3 = await staking.setSharesInMonth(sharesArray)
    await tx3.wait()
    console.log(`Shares in month set`)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
