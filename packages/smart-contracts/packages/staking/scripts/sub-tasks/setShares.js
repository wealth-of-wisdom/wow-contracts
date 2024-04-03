const setShares = require("../helpers/setShares")
require("dotenv").config()

async function main() {
    await setShares(process.env.STAKING_ADDRESS)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
