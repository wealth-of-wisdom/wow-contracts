const { ethers, upgrades } = require("hardhat")
require("dotenv").config()

async function main() {
    // Deploy NFT Token
    const Nft = await ethers.getContractFactory("Nft")
    const nft = await upgrades.deployProxy(Nft, [
        process.env.NFT_NAME,
        process.env.NFT_SYMBOL,
        process.env.VESTING_CONTRACT,
        process.env.MAX_LEVEL,
        process.env.VESTING_POOL_ID,
        process.env.GENESIS_TOKEN_DIVISOR,
    ])
    await nft.waitForDeployment()
    console.log("NFT deployed to:", await nft.getAddress())

    // // Deploy NFT Sale
    // const NftSale = await ethers.getContractFactory("NftSale")
    // const sale = await upgrades.deployProxy(NftSale, [
    //     process.env.USDT_TOKEN,
    //     process.env.USDC_TOKEN,
    //     nft.address,
    // ])
    // await sale.waitForDeployment()
    // console.log("NFT Sale deployed to:", await sale.getAddress())

    // // Get Vesting contract
    // const Vesting = await ethers.getContractFactory("Vesting")
    // const vesting = await Vesting.attach(process.env.VESTING_CONTRACT)

    // Get permissions
    const MINTER_ROLE = await nft.MINTER_ROLE()
    const NFT_DATA_MANAGER = await nft.NFT_DATA_MANAGER()
    const BENEFICIARIES_MANAGER_ROLE =
        await vesting.BENEFICIARIES_MANAGER_ROLE()

    console.log(nft.address)
    console.log(MINTER_ROLE, NFT_DATA_MANAGER, BENEFICIARIES_MANAGER_ROLE)
    // // Grant permissions
    // nft.grantRole(MINTER_ROLE, address(sale))
    // nft.grantRole(NFT_DATA_MANAGER, address(sale))
    // vesting.grantRole(BENEFICIARIES_MANAGER_ROLE, address(sale))
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
