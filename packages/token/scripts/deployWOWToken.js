const { ethers, upgrades } = require("hardhat")

async function deployWOWToken(name, symbol, initialAmount) {
    const WOWToken = await ethers.getContractFactory("WOWToken")
    const token = await upgrades.deployProxy(WOWToken, [
        name,
        symbol,
        initialAmount,
    ])
    await token.waitForDeployment()

    const tokenAddress = await token.getAddress()
    console.log("WOWToken deployed to: ", tokenAddress)

    return tokenAddress
}

async function main() {
    await deployWOWToken("Wealth-Of-Wisdom", "WOW", 2_100_000_000)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})

module.exports = {
    deployWOWToken: deployWOWToken,
}
