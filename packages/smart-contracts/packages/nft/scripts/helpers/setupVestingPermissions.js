const { ethers } = require("hardhat")

async function setupVestingPermissions(nftSaleAddress, vestingContract) {
    if (vestingContract === ethers.ZeroAddress) {
        console.log("No vesting contract provided. Skipping vesting setup.")
        return
    }

    /*//////////////////////////////////////////////////////////////////////////
                            GRANT PERMISSIONS IN VESTING
    //////////////////////////////////////////////////////////////////////////*/

    const Vesting = await ethers.getContractFactory("Vesting")
    const vesting = Vesting.attach(vestingContract)

    const BENEFICIARIES_MANAGER_ROLE =
        await vesting.BENEFICIARIES_MANAGER_ROLE()

    const tx = await vesting.grantRole(
        BENEFICIARIES_MANAGER_ROLE,
        nftSaleAddress,
    )
    await tx.wait()

    console.log("BENEFICIARIES_MANAGER_ROLE granted to:", nftSaleAddress)
}

module.exports = setupVestingPermissions
