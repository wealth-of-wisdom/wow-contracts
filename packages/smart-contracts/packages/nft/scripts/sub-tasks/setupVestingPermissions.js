const setupVestingPermissions = require("../helpers/setupVestingPermissions")
require("dotenv").config()

async function main() {
    await setupVestingPermissions(
        process.env.NFT_CONTRACT,
        process.env.VESTING_CONTRACT,
    )
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
