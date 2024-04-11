const createDistribution = require("../helpers/createDistribution")
require("dotenv").config()

async function main() {
    await createDistribution(
        process.env.STAKING_ADDRESS,
        process.env.DISTRIBUTION_TOKEN_ADDRESS,
        process.env.DISTRIBUTION_AMOUNT,
    )
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
