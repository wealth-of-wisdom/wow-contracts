const { ethers, upgrades } = require("hardhat")
const poolsData = require("./wowTokenSupply.json")
require("dotenv").config()

async function addVestingPools(vestingTokenContract, vestingContract, pools) {
    const Token = await ethers.getContractFactory("WOWToken")
    const token = Token.attach(vestingTokenContract)

    const Vesting = await ethers.getContractFactory("Vesting")
    const vesting = Vesting.attach(vestingContract)
    const divisor = 100

    await token.approve(vestingContract, process.env.FULL_POOL_TOKEN_AMOUNT);

    for (var pool of pools) {
        console.log(pool)
        await vesting.addVestingPool(
            pool.name,
            pool.listing_release_percentage,
            divisor,
            pool.cliff_in_months * 30,
            0,
            divisor,
            pool.vesting_in_months,
            0, // DAILY
            pool.tokens_amount)
        console.log("Vesting pool added!")
    }
}

async function main() {
    await addVestingPools(process.env.VESTING_TOKEN, process.env.VESTING_CONTRACT, poolsData)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})

module.exports = {
    addVestingPools: addVestingPools,
}
