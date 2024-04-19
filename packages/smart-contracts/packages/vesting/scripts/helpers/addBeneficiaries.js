const { ethers } = require("hardhat")
const beneficiaries = require("../data/vestingBeneficiaries.json")

async function addBeneficiaries(tokenAddress, vestingAddress) {
    const vesting = await ethers.getContractAt("Vesting", vestingAddress)
    const poolsCount = await vesting.getPoolCount()
    const DECIMALS = 18

    /*//////////////////////////////////////////////////////////////////////////
                                VALIDATE ALL THE DATA
    //////////////////////////////////////////////////////////////////////////*/

    await validateData(vesting, beneficiaries, Number(poolsCount), DECIMALS)

    /*//////////////////////////////////////////////////////////////////////////
                              ADD VESTING BENEFICIARIES
    //////////////////////////////////////////////////////////////////////////*/

    for (let user of beneficiaries) {
        const tokenAmountInWei = ethers.parseUnits(
            user.tokens_amount_in_wow,
            DECIMALS,
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

        if (
            typeof user.tokens_amount_in_wow !== "string" ||
            isNaN(user.tokens_amount_in_wow)
        ) {
            throw new Error(
                `Invalid tokens amount: ${user.tokens_amount_in_wow}`,
            )
        }

        // Validate token amount
        allBeneficiariesTokensPerPool[user.pool_id] += ethers.parseUnits(
            user.tokens_amount_in_wow,
            decimals,
        )
    }

    // Validate that all beneficiaries tokens add up to the pool's undedicated amount
    for (let poolId = 0; poolId < poolsCount; poolId++) {
        const pool = await vesting.getGeneralPoolData(poolId)
        const totalPoolAmount = BigInt(pool[2])
        const dedicatedPoolAmount = BigInt(pool[3])
        const undedicatedPoolAmount = totalPoolAmount - dedicatedPoolAmount

        // If at least one beneficiary is added to the pool we need to check that pool was filled correctly
        // @todo Not sure if this is actually needed
        if (allBeneficiariesTokensPerPool[poolId] !== undedicatedPoolAmount) {
            throw new Error(
                `Amounts don't add up for pool ${poolId} - expected ${undedicatedPoolAmount} but got ${allBeneficiariesTokensPerPool[poolId]}`,
            )
        }
    }

    console.log("Beneficiaries validated!")
}

module.exports = addBeneficiaries