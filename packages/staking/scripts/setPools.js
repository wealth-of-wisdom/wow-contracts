const poolData = require("./data/poolData.json")
require("dotenv").config()

async function setPools(staking) {
    /*//////////////////////////////////////////////////////////////////////////
                                    SET POOLS
    //////////////////////////////////////////////////////////////////////////*/

    for (let i = 0; i < poolData.length; i++) {
        const data = poolData[i]
        const tx = await staking.setPool(data.id, data.distributionPercentage)
        await tx.wait()

        console.log(`Pool ${data.id} data set`)
    }
}

module.exports = setPools
