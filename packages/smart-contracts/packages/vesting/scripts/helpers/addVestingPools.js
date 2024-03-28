const { ethers } = require("hardhat")
const poolsData = require("../data/vestingPools.json")

async function addVestingPools(vestingToken, vestingContract, totalTokens) {
    if (!vestingToken || !vestingContract || !totalTokens) {
        throw new Error(
            "Please provide parameters: vestingToken, vestingContract, totalTokens",
        )
    }

    const Token = await ethers.getContractFactory("WOWToken")
    const token = Token.attach(vestingToken)

    const Vesting = await ethers.getContractFactory("Vesting")
    const vesting = Vesting.attach(vestingContract)

    /*//////////////////////////////////////////////////////////////////////////
                        APPROVE VESTING TO SPEND TOKENS
    //////////////////////////////////////////////////////////////////////////*/

    const tx1 = await token.approve(vestingContract, totalTokens)
    await tx1.wait()

    console.log("Approval complete!")

    const tokenDecimals = await token.decimals()

    const DIVISOR = 100
    const DAYS_IN_MONTH = 30
    const DAILY_UNLOCK_TYPE = 0

    /*//////////////////////////////////////////////////////////////////////////
                                ADD VESTING POOLS
    //////////////////////////////////////////////////////////////////////////*/

    for (let pool of poolsData) {
        const tokenAmountInWei = ethers.parseUnits(
            pool.tokens_amount_in_wow,
            tokenDecimals,
        )

        const tx2 = await vesting.addVestingPool(
            pool.name, // Name
            pool.listing_release_percentage, // Listing percentage dividend
            DIVISOR, // Listing percentage divisor
            pool.cliff_in_months * DAYS_IN_MONTH, // Cliff duration in days
            0, // Cliff percentage dividend
            DIVISOR, // Cliff percentage divisor
            pool.vesting_in_months, // Vesting duration in months
            DAILY_UNLOCK_TYPE, // Unlock type: DAILY or MONTHLY
            tokenAmountInWei, // Total token amount for vesting pool
        )
        await tx2.wait()

        console.log(`Vesting pool ${pool.name} added!`)
    }
}

module.exports = addVestingPools
