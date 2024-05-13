const setupStakingPermissions = require("../helpers/setupStakingPermissions")
require("dotenv").config()

async function main() {
    await setupStakingPermissions(
        process.env.STAKING_ADDRESS,
        process.env.VESTING_ADDRESS,
    )
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
