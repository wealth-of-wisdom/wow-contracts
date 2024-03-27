const bandLevelData = require("./data/bandLevelData.json")
require("dotenv").config()

async function setBandLevels(staking) {
    /*//////////////////////////////////////////////////////////////////////////
                                SET BAND LEVEL DATA
    //////////////////////////////////////////////////////////////////////////*/

    const WOW_DECIMALS = 1e18
    for (let i = 0; i < bandLevelData.length; i++) {
        const data = bandLevelData[i]
        const bandLevelPriceInWoWTokens =
            BigInt(bandLevelData[i].price) * BigInt(WOW_DECIMALS)

        const tx = await staking.setBandLevel(
            data.level,
            bandLevelPriceInWoWTokens,
            data.accessiblePools,
        )
        await tx.wait()

        console.log(`Band level ${data.level} data set`)
    }
}

module.exports = setBandLevels
