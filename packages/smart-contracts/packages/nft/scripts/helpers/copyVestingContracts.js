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
}

async function copyVestingContracts() {
    const sourceDir = "../vesting/contracts"
    const destinationDir = "./contracts/temp/vesting-contracts"

    // Get the vesting contract
    await copyDirectory(sourceDir, destinationDir)
    console.log("Vesting contracts have been copied successfully.")

    // Compile the vesting contract
    await run("compile")
}

module.exports = copyVestingContracts
