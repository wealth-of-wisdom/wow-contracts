// const { ethers, upgrades } = require("hardhat")
// const {
//     deployWOWToken,
// } = require("@wealth-of-wisdom/token/scripts/deployWOWToken")
// const { deployVesting } = require("../deployVesting")
// const { addVestingPools } = require("../addVestingPools")
// const poolsData = require("../wowTokenSupply.json")

// async function main() {
//     // Deploy WOW token
//     const name = "Wealth-Of-Wisdom"
//     const symbol = "WOW"
//     const initialAmount = 2_100_000_000
//     const tokenAddress = await deployWOWToken(name, symbol, initialAmount)

//     // Deploy Vesting Contract
//     const fakeStakingContract = ethers.Wallet.createRandom()
//     const currentTimestamp = Math.floor(Date.now() / 1000)
//     const listingDate = currentTimestamp + 600 // after 10 minutes
//     const vestingAddress = await deployVesting(
//         tokenAddress,
//         fakeStakingContract,
//         listingDate,
//     )

//     // Add vesting pools
//     await addVestingPools(vestingAddress, poolsData)
// }

// main().catch((error) => {
//     console.error(error)
//     process.exitCode = 1
// })

const { ethers, upgrades } = require("hardhat")

async function main() {
    const name = "Wealth-Of-Wisdom"
    const symbol = "WOW"
    const initialAmount = ethers.parseEther("1")
    const fakeStakingContract = ethers.Wallet.createRandom()
    console.log(fakeStakingContract)
    const currentTimestamp = Math.floor(Date.now() / 1000)
    const listingDate = currentTimestamp + 600

    // Deploy WOW Token
    const WOWToken = await ethers.getContractFactory("WOWToken")
    const token = await upgrades.deployProxy(WOWToken, [
        name,
        symbol,
        initialAmount,
    ])
    await token.waitForDeployment()
    console.log("Token deployed to:", await token.getAddress())

    // Deploy WOW Vesting
    const Vesting = await ethers.getContractFactory("Vesting")
    const vesting = await upgrades.deployProxy(Vesting, [
        token,
        fakeStakingContract,
        listingDate,
    ])
    await vesting.waitForDeployment()

    console.log("Vesting deployed to:", await vesting.getAddress())
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
