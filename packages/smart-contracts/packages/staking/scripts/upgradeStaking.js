const deployStaking = require("./helpers/deployStaking")
const upgradeStaking = require("./helpers/upgradeStaking")
const deployStakingImplementation = require("./helpers/deployStakingImplementation")
require("dotenv").config()

async function main() {
    newStakingImplementation = await deployStakingImplementation()

    await upgradeStaking(newStakingImplementation)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
