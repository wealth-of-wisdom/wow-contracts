// @ts-ignore
const { ethers } = require("hardhat")
const {
    PERCENTAGE_DIVISOR,
    WOW_TOKEN_DECIMALS,
    DAILY_UNLOCK_TYPE_NUM,
    MONTHLY_UNLOCK_TYPE_NUM,
    DAILY_UNLOCK_TYPE_STR,
} = require("./constants")

async function updateGeneralPoolsData(vestingAddress, generalPoolData) {
    const vesting = await ethers.getContractAt("Vesting", vestingAddress)

    for (let pool of generalPoolData) {
        const poolId = pool.pool_id
        const tokenAmountInWei = ethers.parseUnits(
            pool.tokens_amount_in_wow,
            WOW_TOKEN_DECIMALS,
        )
        const unlockType =
            pool.unlock_type === DAILY_UNLOCK_TYPE_STR
                ? DAILY_UNLOCK_TYPE_NUM
                : MONTHLY_UNLOCK_TYPE_NUM

        const tx = await vesting.updateGeneralPoolData(
            poolId,
            pool.name,
            unlockType,
            tokenAmountInWei,
        )

        await tx.wait()

        console.log(`Vesting pool's general data with id ${poolId} updated!`)
    }
}

async function updatePoolsListingData(vestingAddress, poolListingData) {
    const vesting = await ethers.getContractAt("Vesting", vestingAddress)

    for (let pool of poolListingData) {
        const poolId = pool.pool_id

        const tx = await vesting.updatePoolListingData(
            poolId,
            pool.listing_release_percentage,
            PERCENTAGE_DIVISOR,
        )

        await tx.wait()

        console.log(`Vesting pool's listing data with id ${poolId} updated!`)
    }
}

async function updatePoolsCliffData(vestingAddress, poolCliffData) {
    const vesting = await ethers.getContractAt("Vesting", vestingAddress)

    for (let pool of poolCliffData) {
        const poolId = pool.pool_id

        const tx = await vesting.updatePoolCliffData(
            poolId,
            pool.cliff_in_days,
            pool.cliff_release_percentage,
            PERCENTAGE_DIVISOR,
        )

        await tx.wait()

        console.log(`Vesting pool's cliff data with id ${poolId} updated!`)
    }
}

async function updatePoolsVestingData(vestingAddress, poolVestingData) {
    const vesting = await ethers.getContractAt("Vesting", vestingAddress)

    for (let pool of poolVestingData) {
        const poolId = pool.pool_id

        const tx = await vesting.updatePoolVestingData(
            poolId,
            pool.vesting_in_months,
        )

        await tx.wait()

        console.log(`Vesting pool's vesting data with id ${poolId} updated!`)
    }
}

module.exports = {
    updateGeneralPoolsData,
    updatePoolsListingData,
    updatePoolsCliffData,
    updatePoolsVestingData,
}
