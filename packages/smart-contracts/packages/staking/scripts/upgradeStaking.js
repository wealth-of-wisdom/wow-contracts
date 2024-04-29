const upgradeStaking = require("./sub-tasks/upgradeStaking")
const deployStakingImplementation = require("./helpers/deployStakingImplementation")
require("dotenv").config()

async function main() {
    await deployStakingImplementation()

    await upgradeStaking(process.env.STAKING_PROXY_ADDRESS)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
