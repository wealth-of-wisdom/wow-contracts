const setVestingContract = require("../helpers/setVestingContract")
require("dotenv").config()

async function main() {
    await setVestingContract(
        process.env.NFT_CONTRACT,
        process.env.VESTING_CONTRACT,
    )
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
