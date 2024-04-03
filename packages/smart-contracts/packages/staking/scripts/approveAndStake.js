const { ethers } = require("hardhat")
const erc20Abi = require("./abis/erc20Abi")
const getNetworkConfig = require("./helpers/getNetworkConfig")
const stake = require("./helpers/stake")
require("dotenv").config()

async function main() {
    const { wowToken: wowTokenAddress } = await getNetworkConfig()
    const stakingAddress = process.env.STAKING_ADDRESS
    const stakingType = process.env.STAKING_TYPE
    const bandLevel = process.env.BAND_LEVEL
    const fixedMonths = process.env.FIXED_MONTHS
    const shouldMintWowTokens = JSON.parse(process.env.SHOULD_MINT_TOKENS)

    const tokenWOW = await ethers.getContractAt(erc20Abi, wowTokenAddress)
    const [user] = await ethers.getSigners()
    const userAddress = await user.getAddress()

    const staking = await ethers.getContractAt("Staking", stakingAddress)
    const bandLevelData = await staking.getBandLevel(bandLevel)
    const bandPrice = bandLevelData.price

    if (shouldMintWowTokens) {
        // Mint WOW tokens to user
        const mintTx = await tokenWOW.mint(userAddress, bandPrice)
        await mintTx.wait()
        console.log(`Minted WOW to user`)
    }

    // Approve staking contract to spend WOW tokens
    const approveTx = await tokenWOW.approve(stakingAddress, bandPrice)
    await approveTx.wait()
    console.log(`Approved WOW tokens to staking contract`)

    await stake(stakingAddress, stakingType, bandLevel, fixedMonths)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
