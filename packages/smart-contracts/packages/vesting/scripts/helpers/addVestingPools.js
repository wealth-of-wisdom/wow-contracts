const { network, ethers } = require("hardhat")
const poolsDataDev = require("../data/dev/vestingPools.json")
const poolsDataProd = require("../data/prod/vestingPools.json")
const {
    MAINNET_NETWORKS,
    PERCENTAGE_DIVISOR,
    WOW_TOKEN_DECIMALS,
    DAILY_UNLOCK_TYPE_NUM,
    MONTHLY_UNLOCK_TYPE_NUM,
    DAILY_UNLOCK_TYPE_STR,
    MONTHLY_UNLOCK_TYPE_STR,
} = require("./constants")

async function addVestingPools(tokenAddress, vestingAddress) {
    const token = await ethers.getContractAt("WOWToken", tokenAddress)
    const vesting = await ethers.getContractAt("Vesting", vestingAddress)
    const poolsData = MAINNET_NETWORKS.includes(network.name)
        ? poolsDataProd
        : poolsDataDev

    /*//////////////////////////////////////////////////////////////////////////
                                VALIDATE ALL THE DATA
    //////////////////////////////////////////////////////////////////////////*/

    const totalTokens = await validateData(poolsData, WOW_TOKEN_DECIMALS)

    /*//////////////////////////////////////////////////////////////////////////
                        APPROVE VESTING TO SPEND TOKENS
    //////////////////////////////////////////////////////////////////////////*/

    const tx1 = await token.approve(vestingAddress, totalTokens)
    await tx1.wait()

    console.log("Approval complete!")

    /*//////////////////////////////////////////////////////////////////////////
                                ADD VESTING POOLS
    //////////////////////////////////////////////////////////////////////////*/

    for (let pool of poolsData) {
        const tokenAmountInWei = ethers.parseUnits(
            pool.tokens_amount_in_wow,
            WOW_TOKEN_DECIMALS,
        )
        const unlockType =
            pool.unlock_type === DAILY_UNLOCK_TYPE_STR
                ? DAILY_UNLOCK_TYPE_NUM
                : MONTHLY_UNLOCK_TYPE_NUM

        const tx2 = await vesting.addVestingPool(
            pool.name, // Name
            pool.listing_release_percentage, // Listing percentage dividend
            PERCENTAGE_DIVISOR, // Listing percentage divisor
            pool.cliff_in_days, // Cliff duration in days
            pool.cliff_release_percentage, // Cliff percentage dividend
            PERCENTAGE_DIVISOR, // Cliff percentage divisor
            pool.vesting_in_months, // Vesting duration in months
            unlockType, // Unlock type: DAILY or MONTHLY
            tokenAmountInWei, // Total token amount for vesting pool
        )
        await tx2.wait()

        console.log(`Vesting pool ${pool.name} added!`)
    }
}

async function validateData(data, decimals) {
    let allPoolsTokens = BigInt(0)

    for (let pool of data) {
        // Validate data types
        if (typeof pool.name !== "string" || pool.name.trim().length === 0) {
            throw new Error(`Invalid name: ${pool.name}`)
        }

        if (
            typeof pool.listing_release_percentage !== "number" ||
            pool.listing_release_percentage < 0 ||
            pool.listing_release_percentage > PERCENTAGE_DIVISOR
        ) {
            throw new Error(
                `Invalid listing percentage: ${pool.listing_release_percentage}`,
            )
        }

        if (typeof pool.cliff_in_days !== "number" || pool.cliff_in_days < 0) {
            throw new Error(`Invalid cliff duration: ${pool.cliff_in_days}`)
        }

        if (
            typeof pool.cliff_release_percentage !== "number" ||
            pool.cliff_release_percentage < 0 ||
            pool.cliff_release_percentage > PERCENTAGE_DIVISOR
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
            (pool.unlock_type !== DAILY_UNLOCK_TYPE_STR &&
                pool.unlock_type !== MONTHLY_UNLOCK_TYPE_STR)
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

        allPoolsTokens += ethers.parseUnits(pool.tokens_amount_in_wow, decimals)
    }

    console.log("Total tokens: ", allPoolsTokens.toString())
    console.log("Pools validated!")

    return allPoolsTokens
}

module.exports = addVestingPools
