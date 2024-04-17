const { ethers } = require("hardhat")
const beneficiaries = require("../data/vestingBeneficiaries.json")

async function addBeneficiaries(tokenAddress, vestingAddress) {
    const vesting = await ethers.getContractAt("Vesting", vestingAddress)
    const DECIMALS = 18

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

module.exports = addBeneficiaries
