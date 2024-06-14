const { addBeneficiariesFromFile } = require("../helpers/addBeneficiaries")
require("dotenv").config()

async function main() {
    await addBeneficiariesFromFile(process.env.VESTING_CONTRACT)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
