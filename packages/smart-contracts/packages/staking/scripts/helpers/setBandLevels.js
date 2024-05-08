const { ethers } = require("hardhat")
const bandLevelData = require("../data/bandLevelData.json")

async function setBandLevels(stakingAddress) {
    const Staking = await ethers.getContractFactory("Staking")
    const staking = Staking.attach(stakingAddress)

    /*//////////////////////////////////////////////////////////////////////////
                                SET BAND LEVEL DATA
    //////////////////////////////////////////////////////////////////////////*/

    const WOW_DECIMALS = 18

    for (let band of bandLevelData) {
        const priceInWoWTokens = ethers.parseUnits(
            band.price_in_wow,
            WOW_DECIMALS,
        )

        const tx = await staking.setBandLevel(
            band.level,
            priceInWoWTokens,
            band.accessible_pools,
        )
        await tx.wait()

        console.log(`Band level ${band.level} data set`)
    }
}

module.exports = setBandLevels
