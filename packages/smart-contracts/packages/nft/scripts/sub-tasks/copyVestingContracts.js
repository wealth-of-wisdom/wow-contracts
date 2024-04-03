const copyVestingContracts = require("../helpers/copyVestingContracts")

async function main() {
    await copyVestingContracts()
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
