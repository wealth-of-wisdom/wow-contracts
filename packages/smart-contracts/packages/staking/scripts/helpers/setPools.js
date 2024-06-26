const poolData = require("../data/poolData.json")

async function setPools(stakingAddress) {
    const Staking = await ethers.getContractFactory("Staking")
    const staking = Staking.attach(stakingAddress)

    /*//////////////////////////////////////////////////////////////////////////
                                    SET POOLS
    //////////////////////////////////////////////////////////////////////////*/

    for (let pool of poolData) {
        const tx = await staking.setPoolDistributionPercentage(
            pool.id,
            pool.distribution_percentage,
        )
        await tx.wait()

        console.log(`Pool ${pool.id} data set`)
    }
}

module.exports = setPools
