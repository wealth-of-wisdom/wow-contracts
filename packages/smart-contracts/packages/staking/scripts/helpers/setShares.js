const sharesData = require("../data/sharesData.json")

async function setShares(stakingAddress) {
    if (!stakingAddress) {
        throw new Error("Please provide parameter: stakingAddress")
    }

    const Staking = await ethers.getContractFactory("Staking")
    const staking = Staking.attach(stakingAddress)

    /*//////////////////////////////////////////////////////////////////////////
                                SET SHARES IN MONTH
    //////////////////////////////////////////////////////////////////////////*/

    const tx = await staking.setSharesInMonth(sharesData)
    await tx.wait()

    console.log(`Shares in month set`)
}

module.exports = setShares
