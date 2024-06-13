// @ts-ignore
const { network, ethers } = require("hardhat")
const beneficiariesDataDev = require("../data/dev/vestingBeneficiaries.json")
const beneficiariesDataProd = require("../data/prod/vestingBeneficiaries.json")
const { MAINNET_NETWORKS, WOW_TOKEN_DECIMALS } = require("./constants")
require("dotenv").config()

async function addBeneficiariesFromFile(vestingAddress) {
    const beneficiaries = MAINNET_NETWORKS.includes(network.name)
        ? beneficiariesDataProd
        : beneficiariesDataDev

    await addBeneficiaries(vestingAddress, beneficiaries)
}

async function addBeneficiaries(vestingAddress, beneficiaries) {
    const vesting = await ethers.getContractAt("Vesting", vestingAddress)
    const poolsCount = await vesting.getPoolCount()

    /*//////////////////////////////////////////////////////////////////////////
                                VALIDATE ALL THE DATA
    //////////////////////////////////////////////////////////////////////////*/

    await validateData(
        vesting,
        beneficiaries,
        Number(poolsCount),
        WOW_TOKEN_DECIMALS,
    )

    /*//////////////////////////////////////////////////////////////////////////
                              ADD VESTING BENEFICIARIES
    //////////////////////////////////////////////////////////////////////////*/

    for (let user of beneficiaries) {
        const tokenAmountInWei = ethers.parseUnits(
            user.tokens_amount_in_wow.toString(),
            WOW_TOKEN_DECIMALS,
        )

        const tx = await vesting.addBeneficiary(
            user.pool_id, // Vesting pool ID
            user.beneficiary_address,
            tokenAmountInWei, // Total token amount for vesting pool
        )
        await tx.wait()

        console.log(`Beneficiary ${user.beneficiary_address} added!`)
    }
}

/**
 * @notice It would be helpful to rewrite the functions in typescript
 * @notice To add type checking and better error handling
 * @notice But for now, this will do because all the scripts are in javascript
 */
async function validateData(vesting, data, poolsCount, decimals) {
    const allBeneficiariesTokensPerPool = Array(poolsCount).fill(BigInt(0))

    for (let user of data) {
        // Validate data types
        if (
            typeof user.pool_id !== "number" ||
            user.pool_id < 0 ||
            user.pool_id >= poolsCount
        ) {
            throw new Error(`Invalid pool ID: ${user.pool_id}`)
        }

        if (
            typeof user.beneficiary_address !== "string" ||
            !ethers.isAddress(user.beneficiary_address)
        ) {
            throw new Error(
                `Invalid beneficiary address: ${user.beneficiary_address}`,
            )
        }

        if (typeof user.tokens_amount_in_wow !== "number") {
            throw new Error(
                `Invalid tokens amount: ${user.tokens_amount_in_wow}`,
            )
        }

        // Validate token amount
        allBeneficiariesTokensPerPool[user.pool_id] += ethers.parseUnits(
            user.tokens_amount_in_wow.toString(),
            decimals,
        )
    }

    // Validate that all beneficiaries tokens add up to the pool's undedicated amount
    if (process.env.SHOULD_FILL_VESTING_POOLS === "true") {
        console.log("Checking if all tokens in pools where used")
        for (let poolId = 0; poolId < poolsCount; poolId++) {
            const pool = await vesting.getGeneralPoolData(poolId)
            const totalPoolAmount = BigInt(pool[2])
            const dedicatedPoolAmount = BigInt(pool[3])
            const undedicatedPoolAmount = totalPoolAmount - dedicatedPoolAmount

            // If at least one beneficiary is added to the pool we need to check that pool was filled correctly
            if (
                allBeneficiariesTokensPerPool[poolId] !== undedicatedPoolAmount
            ) {
                throw new Error(
                    `Amounts don't add up for pool ${poolId} - expected ${undedicatedPoolAmount} but got ${allBeneficiariesTokensPerPool[poolId]}`,
                )
            }
        }
    }

    console.log("Beneficiaries validated!")
}

module.exports = { addBeneficiariesFromFile, addBeneficiaries }
