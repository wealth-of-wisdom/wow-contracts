const { ethers } = require("hardhat")

async function setupVestingPermissions(vestingAddress, nftAddress) {
    if (nftAddress === ethers.ZeroAddress) {
        console.log("No nft contract provided. Skipping vesting setup.")
        return
    }

    /*//////////////////////////////////////////////////////////////////////////
                            GRANT PERMISSIONS IN VESTING
    //////////////////////////////////////////////////////////////////////////*/

    const Vesting = await ethers.getContractFactory("Vesting")
    const vesting = Vesting.attach(vestingAddress)

    const BENEFICIARIES_MANAGER_ROLE =
        await vesting.BENEFICIARIES_MANAGER_ROLE()

    const tx = await vesting.grantRole(BENEFICIARIES_MANAGER_ROLE, nftAddress)
    await tx.wait()

    console.log("BENEFICIARIES_MANAGER_ROLE granted to:", nftAddress)
}

module.exports = setupVestingPermissions
