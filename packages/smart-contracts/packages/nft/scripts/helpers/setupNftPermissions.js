const { ethers } = require("hardhat")

async function setupNftPermissions(nftAddress, nftSaleAddress) {
    const Nft = await ethers.getContractFactory("Nft")
    const nft = Nft.attach(nftAddress)

    const MINTER_ROLE = await nft.MINTER_ROLE()
    const NFT_DATA_MANAGER_ROLE = await nft.NFT_DATA_MANAGER_ROLE()

    const tx1 = await nft.grantRole(MINTER_ROLE, nftSaleAddress)
    await tx1.wait()
    console.log("MINTER_ROLE granted to:", nftSaleAddress)

    const tx2 = await nft.grantRole(NFT_DATA_MANAGER_ROLE, nftSaleAddress)
    await tx2.wait()
    console.log("NFT_DATA_MANAGER_ROLE granted to:", nftSaleAddress)
}

module.exports = setupNftPermissions
