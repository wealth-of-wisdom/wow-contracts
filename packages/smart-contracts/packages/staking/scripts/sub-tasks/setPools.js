const setPools = require("../helpers/setPools")
require("dotenv").config()

async function main() {
    await setPools(process.env.STAKING_ADDRESS)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
