const { ethers } = require("hardhat")
const poolsData = require("../data/vestingPools.json")

async function addVestingPools(tokenAddress, vestingAddress, totalTokens) {
    const token = await ethers.getContractAt("WOWToken", tokenAddress)
    const vesting = await ethers.getContractAt("Vesting", vestingAddress)
    const tokenDecimals = await token.decimals()

    /*//////////////////////////////////////////////////////////////////////////
                                VALIDATE ALL THE DATA
    //////////////////////////////////////////////////////////////////////////*/

    validateData(poolsData, totalTokens, tokenDecimals)

    /*//////////////////////////////////////////////////////////////////////////
                        APPROVE VESTING TO SPEND TOKENS
    //////////////////////////////////////////////////////////////////////////*/

    const tx1 = await token.approve(vestingAddress, totalTokens)
    await tx1.wait()

    console.log("Approval complete!")

    /*//////////////////////////////////////////////////////////////////////////
                                ADD VESTING POOLS
    //////////////////////////////////////////////////////////////////////////*/

    const DIVISOR = 100
    const DAYS_IN_MONTH = 30
    const DAILY_UNLOCK_TYPE = 0
    const MONTHLY_UNLOCK_TYPE = 1

    for (let pool of poolsData) {
        const tokenAmountInWei = ethers.parseUnits(
            pool.tokens_amount_in_wow,
            tokenDecimals,
        )
        const unlockType =
            pool.unlock_type === "DAILY"
                ? DAILY_UNLOCK_TYPE
                : MONTHLY_UNLOCK_TYPE

        const tx2 = await vesting.addVestingPool(
            pool.name, // Name
            pool.listing_release_percentage, // Listing percentage dividend
            DIVISOR, // Listing percentage divisor
            pool.cliff_in_months * DAYS_IN_MONTH, // Cliff duration in days
            pool.cliff_release_percentage, // Cliff percentage dividend
            DIVISOR, // Cliff percentage divisor
            pool.vesting_in_months, // Vesting duration in months
            unlockType, // Unlock type: DAILY or MONTHLY
            tokenAmountInWei, // Total token amount for vesting pool
        )
        await tx2.wait()

        console.log(`Vesting pool ${pool.name} added!`)
    }
}

async function validateData(data, totalTokens, tokenDecimals) {
    let allPoolsTokens = BigInt(0)

    for (let pool of data) {
        // Validate data types
        if (typeof pool.name !== "string" || pool.name.trim().length === 0) {
            throw new Error(`Invalid name: ${pool.name}`)
        }

        if (
            typeof pool.listing_release_percentage !== "number" ||
            pool.listing_release_percentage < 0 ||
            pool.listing_release_percentage > 100
        ) {
            throw new Error(
                `Invalid listing percentage: ${pool.listing_release_percentage}`,
            )
        }

        if (
            typeof pool.cliff_in_months !== "number" ||
            pool.cliff_in_months < 0
        ) {
            throw new Error(`Invalid cliff duration: ${pool.cliff_in_months}`)
        }

        if (
            typeof pool.cliff_release_percentage !== "number" ||
            pool.cliff_release_percentage < 0 ||
            pool.cliff_release_percentage > 100
        ) {
            throw new Error(
                `Invalid cliff percentage: ${pool.cliff_release_percentage}`,
            )
        }

        if (
            typeof pool.vesting_in_months !== "number" ||
            pool.vesting_in_months < 0
        ) {
            throw new Error(
                `Invalid vesting duration: ${pool.vesting_in_months}`,
            )
        }

        if (
            typeof pool.unlock_type !== "string" ||
            (pool.unlock_type !== "DAILY" && pool.unlock_type !== "MONTHLY")
        ) {
            throw new Error(`Invalid unlock type: ${pool.unlock_type}`)
        }

        if (
            typeof pool.tokens_amount_in_wow !== "string" ||
            isNaN(pool.tokens_amount_in_wow)
        ) {
            throw new Error(
                `Invalid tokens amount: ${pool.tokens_amount_in_wow}`,
            )
        }

        allPoolsTokens += ethers.parseUnits(
            pool.tokens_amount_in_wow,
            tokenDecimals,
        )
    }

    // Validate that the total tokens amount matches the sum of all pools
    if (allPoolsTokens !== BigInt(totalTokens)) {
        throw new Error(
            `Total tokens amount mismatch: ${allPoolsTokens.toString()} !== ${totalTokens}`,
        )
    }

    console.log("Pools validated!")
}

module.exports = addVestingPools
