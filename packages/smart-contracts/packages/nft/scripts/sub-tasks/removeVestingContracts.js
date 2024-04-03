const removeVestingContracts = require("../helpers/removeVestingContracts")

async function main() {
    await removeVestingContracts()
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
