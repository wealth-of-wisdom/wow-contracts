const upgradeVesting = require("../helpers/upgradeVesting")
const verifyVesting = require("../helpers/verifyVesting")
require("dotenv").config()

async function main() {
    const vestingProxyAddress = process.env.VESTING_PROXY_ADDRESS

    await upgradeVesting(vestingProxyAddress)

    await verifyVesting(vestingProxyAddress)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
