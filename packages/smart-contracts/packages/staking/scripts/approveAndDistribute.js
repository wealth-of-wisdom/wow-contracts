const { ethers } = require("hardhat")
const erc20Abi = require("./abis/erc20Abi")
require("dotenv").config()

async function main() {
    const stakingAddress = process.env.STAKING_ADDRESS
    const tokenAddress = process.env.DISTRIBUTION_TOKEN_ADDRESS
    const distributionAmount = process.env.DISTRIBUTION_AMOUNT
    const shouldMintTokens = JSON.parse(process.env.SHOULD_MINT_TOKENS)

    const token = await ethers.getContractAt(erc20Abi, tokenAddress)

    if (shouldMintTokens) {
        // Mint USDT/USDC tokens to admin
        const mintTx = await token.mint(adminAddress, distributionAmount)
        await mintTx.wait()
        console.log(`Minted distribution tokens to admin`)
    }

    // Approve staking contract to spend USDT/USDC tokens
    const approveTx = await token.approve(stakingAddress, distributionAmount)
    await approveTx.wait()
    console.log(`Approved distribution tokens to staking contract`)

    await createDistribution(stakingAddress, tokenAddress, distributionAmount)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
