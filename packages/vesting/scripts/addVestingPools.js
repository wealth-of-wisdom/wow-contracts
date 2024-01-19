const { ethers, upgrades } = require("hardhat")
const poolsData = require("./wowTokenSupply.json")
require("dotenv").config()

async function addVestingPools(vestingTokenContract, vestingContract, pools) {
    const Token = await ethers.getContractFactory("WOWToken")
    const token = Token.attach(vestingTokenContract)

    const Vesting = await ethers.getContractFactory("Vesting")
    const vesting = Vesting.attach(vestingContract)
    const DIVISOR = 100

    const tx1 = await token.approve(
        vestingContract,
        process.env.FULL_POOL_TOKEN_AMOUNT,
    )
    await tx1.wait()

    console.log("Approval complete!")

    for (var pool of pools) {
        const tx2 = await vesting.addVestingPool(
            pool.name,
            pool.listing_release_percentage,
            DIVISOR,
            pool.cliff_in_months * 30,
            0,
            DIVISOR,
            pool.vesting_in_months,
            0, // DAILY
            pool.tokens_amount,
        )
        tx2.wait()

        console.log(`Vesting pool ${pool.name} added!`)
    }
}

async function main() {
    await addVestingPools(
        process.env.VESTING_TOKEN,
        process.env.VESTING_CONTRACT,
        poolsData,
    )
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})

module.exports = {
    addVestingPools: addVestingPools,
}
