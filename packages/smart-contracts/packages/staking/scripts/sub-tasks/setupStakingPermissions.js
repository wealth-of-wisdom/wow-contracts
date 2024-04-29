const setupVestingPermissions = require("../helpers/setupStakingPermissions")
require("dotenv").config()

async function main() {
    await setupVestingPermissions(
        process.env.STAKING_CONTRACT,
        process.env.VESTING_CONTRACT,
    )
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
