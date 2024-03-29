const fs = require("fs").promises // Use the promise-based API

async function removeVestingContracts() {
    const tempDirPath = "./contracts/temp"

    try {
        // Check if the directory exists
        await fs.access(tempDirPath)

        // Recursively remove the temp directory and its contents
        await fs.rm(tempDirPath, { recursive: true, force: true })
        console.log("Temp folder has been removed successfully.")
    } catch (error) {
        if (error.code === "ENOENT") {
            console.log("The specified directory does not exist.")
        } else {
            console.error("Error removing temp folder:", error)
        }
    }
}

module.exports = removeVestingContracts
