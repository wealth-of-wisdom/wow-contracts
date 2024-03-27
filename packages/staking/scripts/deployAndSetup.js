const deployStaking = require("./deployStaking")
const setPools = require("./setPools")
const setBandLevels = require("./setBandLevels")
const setShares = require("./setShares")
const verifyStaking = require("./verifyStaking")
require("dotenv").config()

async function main() {
    const staking = await deployStaking()

    await setPools(staking)
    await setBandLevels(staking)
    await setShares(staking)

    await verifyStaking(staking)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
