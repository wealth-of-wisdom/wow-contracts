const setProjectQuantities = require("../helpers/setProjectQuantities")
require("dotenv").config()

async function main() {
    await setProjectQuantities(process.env.NFT_CONTRACT)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
