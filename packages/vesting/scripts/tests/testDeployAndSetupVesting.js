const { ethers, upgrades } = require("hardhat")
const {
    deployWOWToken,
} = require("@wealth-of-wisdom/token/scripts/deployWOWToken")
const { deployVesting } = require("../deployVesting")
const { addVestingPools } = require("../addVestingPools")
const poolsData = require("../wowTokenSupply.json")

// @fix the script (currently fails)
async function main() {
    // Deploy WOW token
    const name = "Wealth-Of-Wisdom"
    const symbol = "WOW"
    const initialAmount = 2_100_000_000
    const tokenAddress = await deployWOWToken(name, symbol, initialAmount)

    // Deploy Vesting Contract
    const fakeStakingContract = ethers.Wallet.createRandom()
    const currentTimestamp = Math.floor(Date.now() / 1000)
    const listingDate = currentTimestamp + 600 // after 10 minutes
    const vestingAddress = await deployVesting(
        tokenAddress,
        fakeStakingContract,
        listingDate,
    )

    // Add vesting pools
    await addVestingPools(vestingAddress, poolsData)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
