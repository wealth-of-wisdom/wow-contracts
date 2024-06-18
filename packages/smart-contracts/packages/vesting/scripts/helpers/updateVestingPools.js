const { ethers, network } = require("hardhat")
const updatedPoolsDataProd = require("../data/prod/updatedVestingPools.json")
const updatedPoolsDataDev = require("../data/dev/updatedVestingPools.json")
const {
    updateGeneralPoolsData,
    updatePoolsListingData,
} = require("../helpers/updatePoolData")
const { MAINNET_NETWORKS, WOW_TOKEN_DECIMALS } = require("../helpers/constants")

async function updateVestingPoolsFromFile(tokenAddress, vestingAddress) {
    const poolsData = MAINNET_NETWORKS.includes(network.name)
        ? updatedPoolsDataProd
        : updatedPoolsDataDev

    await updateVestingPools(tokenAddress, vestingAddress, poolsData)
}

async function updateVestingPools(tokenAddress, vestingAddress, poolsData) {
    const vesting = await ethers.getContractAt("Vesting", vestingAddress)
    const token = await ethers.getContractAt("WOWToken", tokenAddress)
    const amountToApprove = BigInt(0)

    for (let index in poolsData) {
        const pool = poolsData[index]
        const tokenAmountInWei = ethers.parseUnits(
            pool.tokens_amount_in_wow,
            WOW_TOKEN_DECIMALS,
        )

        const currentPoolData = await vesting.getGeneralPoolData(pool.pool_id)

        if (currentPoolData.name !== pool.name) {
            throw new Error(
                `Pool name mismatch for pool with id ${pool.pool_id}`,
            )
        }

        console.log(
            `Updating pool with id ${pool.pool_id} and name ${pool.name}`,
        )
        console.log(
            `Current pool amount: ${currentPoolData.totalTokensAmount} | New pool amount: ${tokenAmountInWei}`,
        )
        console.log(
            `Listing release percentage: ${pool.listing_release_percentage}`,
        )

        poolsData[index].unlock_type = currentPoolData.unlockType
        poolsData[index].tokens_amount_in_wei = tokenAmountInWei

        if (tokenAmountInWei > currentPoolData.totalTokensAmount) {
            amountToApprove +=
                tokenAmountInWei - currentPoolData.totalTokensAmount
        }
    }

    // Approve the vesting contract to spend the tokens if pool amount is increased
    if (amountToApprove > BigInt(0)) {
        const tx = await token.approve(vestingAddress, amountToApprove)
        await tx.wait()
    }

    // Update the pools data
    await updateGeneralPoolsData(vestingAddress, poolsData)
    await updatePoolsListingData(
        vestingAddress,
        poolsData.filter(
            (pool) => pool.listing_release_percentage !== undefined,
        ),
    )
}

module.exports = {
    updateVestingPoolsFromFile,
    updateVestingPools,
}
