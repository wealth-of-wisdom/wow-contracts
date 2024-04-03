const setBandLevels = require("../helpers/setBandLevels")
require("dotenv").config()

async function main() {
    await setBandLevels(process.env.STAKING_ADDRESS)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
