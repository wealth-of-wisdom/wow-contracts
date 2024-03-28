const { ethers } = require("hardhat")
const getNetworkConfig = require("./getNetworkConfig.js")

async function setupVestingPermissions(nftSaleAddress) {
    const { vestingContract } = await getNetworkConfig()

    if (vestingContract === "0x0000000000000000000000000000000000000001") {
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
