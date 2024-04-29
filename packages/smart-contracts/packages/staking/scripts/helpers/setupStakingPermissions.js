const { ethers } = require("hardhat")

async function setupStakingPermissions(stakingContract, vestingContract) {
    if (vestingContract === ethers.ZeroAddress) {
        console.log("No vesting contract provided. Skipping vesting setup.")
        return
    }

    /*//////////////////////////////////////////////////////////////////////////
                            GRANT PERMISSIONS IN STAKING
    //////////////////////////////////////////////////////////////////////////*/

    const Staking = await ethers.getContractFactory("Staking")
    const staking = Staking.attach(stakingContract)

    const VESTING_ROLE = await staking.VESTING_ROLE()

    const tx = await staking.grantRole(VESTING_ROLE, vestingContract)
    await tx.wait()

    console.log("VESTING_ROLE granted to:", vestingContract)
}

module.exports = setupStakingPermissions
