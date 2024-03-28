const { ethers, upgrades } = require("hardhat")

async function deployWOWToken(name, symbol, initialAmount) {
    const WOWToken = await ethers.getContractFactory("WOWToken")
    const token = await upgrades.deployProxy(WOWToken, [
        name,
        symbol,
        initialAmount, // Contract takes amount in ETH (not WEI)
    ])
    await token.waitForDeployment()

    const tokenAddress = await token.getAddress()
    console.log("WOWToken deployed to: ", tokenAddress)

    return tokenAddress
}

module.exports = deployWOWToken
