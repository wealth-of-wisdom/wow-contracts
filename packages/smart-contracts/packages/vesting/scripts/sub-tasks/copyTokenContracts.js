const copyTokenContracts = require("../helpers/copyTokenContracts")

async function main() {
    await copyTokenContracts()
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
