const addBeneficiaries = require("../helpers/addBeneficiaries")
require("dotenv").config()

async function main() {
    await addBeneficiaries(
        process.env.VESTING_TOKEN,
        process.env.VESTING_CONTRACT,
    )
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
