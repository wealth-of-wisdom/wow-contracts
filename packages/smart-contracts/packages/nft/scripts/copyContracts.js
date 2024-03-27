const fs = require("fs")
const path = require("path")

function copyDirectory(src, dest) {
    fs.mkdirSync(dest, { recursive: true })
    let entries = fs.readdirSync(src, { withFileTypes: true })

    for (let entry of entries) {
        let srcPath = path.join(src, entry.name)
        let destPath = path.join(dest, entry.name)

        entry.isDirectory()
            ? copyDirectory(srcPath, destPath)
            : fs.copyFileSync(srcPath, destPath)
    }
}

function copyContracts() {
    // Usage
    const sourceDir = "../vesting/contracts"
    const destinationDir = "./contracts/temp/vesting-contracts"

    copyDirectory(sourceDir, destinationDir)
}

async function main() {
    copyContracts()
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})

module.exports = { copyContracts: copyContracts }
