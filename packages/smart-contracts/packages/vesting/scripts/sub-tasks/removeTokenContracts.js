const removeTokenContracts = require("../helpers/removeTokenContracts")

async function main() {
    await removeTokenContracts()
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
