const setLevelsData = require("../helpers/setLevelsData")
require("dotenv").config()

async function main() {
    await setLevelsData(process.env.NFT_CONTRACT)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
