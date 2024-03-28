const { ethers, upgrades } = require("hardhat")

async function deployVesting(vestingToken, stakingContract, listingDate) {
    if (!vestingToken || !stakingContract || !listingDate) {
        throw new Error(
            "Please provide VESTING_TOKEN, STAKING_CONTRACT and LISTING_DATE in .env",
        )
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  DEPLOY VESTING
    //////////////////////////////////////////////////////////////////////////*/

    const Vesting = await ethers.getContractFactory("Vesting")
    const vesting = await upgrades.deployProxy(Vesting, [
        vestingToken,
        stakingContract,
        listingDate,
    ])
    await vesting.waitForDeployment()

    const vestingAddress = await vesting.getAddress()
    console.log("Vesting deployed to: ", vestingAddress)

    return vestingAddress
}

module.exports = deployVesting
