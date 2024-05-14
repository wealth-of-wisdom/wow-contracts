const { ethers } = require("hardhat")

async function setupVestingContract(nftContract, vestingContract) {
    if (vestingContract === ethers.ZeroAddress) {
        console.log("No vesting contract provided. Skipping vesting setup.")
        return
    }

    /*//////////////////////////////////////////////////////////////////////////
                                SET VESTING IN NFT
    //////////////////////////////////////////////////////////////////////////*/

    const Nft = await ethers.getContractFactory("Nft")
    const nft = Nft.attach(nftContract)

    const tx = await nft.setVestingContract(vestingContract)
    await tx.wait()

    console.log("Vesting contract set:", vestingContract)
}

module.exports = setupVestingContract
