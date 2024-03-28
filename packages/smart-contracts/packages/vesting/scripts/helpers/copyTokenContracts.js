const { run } = require("hardhat")
const fs = require("fs").promises
const path = require("path")

async function copyDirectory(src, dest) {
    await fs.mkdir(dest, { recursive: true })
    let entries = await fs.readdir(src, { withFileTypes: true })

    for (let entry of entries) {
        let srcPath = path.join(src, entry.name)
        let destPath = path.join(dest, entry.name)

        if (entry.isDirectory()) {
            await copyDirectory(srcPath, destPath)
        } else {
            await fs.copyFile(srcPath, destPath)
        }
    }

    console.log("Token contracts have been copied successfully.")
}

async function copyTokenContracts() {
    // Usage
    const sourceDir = "../token/contracts"
    const destinationDir = "./contracts/temp/token-contracts"

    await copyDirectory(sourceDir, destinationDir)

    await run("compile")
}

module.exports = copyTokenContracts
