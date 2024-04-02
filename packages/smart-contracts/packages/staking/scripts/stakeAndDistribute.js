const { ethers, network } = require("hardhat")
const getNetworkConfig = require("./helpers/getNetworkConfig")
const erc20Abi = require("./abis/erc20Abi")
require("dotenv").config()

async function main() {
    const { usdtToken, usdcToken, wowToken } = await getNetworkConfig()

    const provider = network.provider
    const [owner] = await ethers.getSigners()

    const stakingAddress = process.env.STAKING_ADDRESS
    if (!stakingAddress) {
        throw new Error("STAKING_ADDRESS is not set")
    }

    const Staking = await ethers.getContractFactory("Staking")
    const Token = await ethers.getContractFactory(erc20Abi, "0x")

    const ethAmount = ethers.parseEther("0.00001")
    const wowAmount = ethers.parseEther("1000000")
    const distributionAmount = ethers.parseEther("1000000")

    const stakeData = {
        owner,
        provider,
        wowToken,
        Token,
        stakingAddress,
        Staking,
        ethAmount,
        wowAmount,
    }

    // Stake with User A (FIXED) band level 3 for 10 months
    await stake(stakeData, 3, 10, 0)

    // Stake with User A (FIXED) band level 4 for 6 months
    await stake(stakeData, 4, 6, 0)

    // Stake with User B (FIXED) band level 5 for 24 months
    await stake(stakeData, 5, 24, 0)

    // Stake with User C (FLEXI) band level 6
    await stake(stakeData, 6, 0, 1)

    // Create distribution
    createDistribution(
        owner,
        usdtToken,
        Token,
        stakingAddress,
        Staking,
        distributionAmount,
    )
}

async function createDistribution(
    admin,
    tokenAddress,
    Token,
    stakingAddress,
    Staking,
    distributionAmount,
) {
    try {
        const staking = Staking.attach(stakingAddress, admin)
        const adminAddress = await admin.getAddress()

        const token = Token.attach(tokenAddress, admin)

        // Mint USDT/USDC tokens to admin
        const mintTx = await token.mint(adminAddress, distributionAmount)
        await mintTx.wait()
        console.log(`Minted USDT/USDC to admin`)

        // Approve staking contract to spend USDT/USDC tokens
        const approveTx = await token.approve(
            stakingAddress,
            distributionAmount,
        )
        await approveTx.wait()
        console.log(`Approved USDT/USDC tokens to staking contract`)

        // Create distribution
        const distributionTx = await staking.createDistribution(
            tokenAddress,
            distributionAmount,
        )
        await distributionTx.wait()
        console.log(`Created distribution`)
    } catch (error) {
        console.log(error)
    }
}

async function stake(stakeData, bandLevel, fixedMonths, stakingType) {
    try {
        const {
            owner,
            provider,
            wowToken,
            Token,
            stakingAddress,
            Staking,
            ethAmount,
            wowAmount,
        } = stakeData

        const user = ethers.Wallet.createRandom().connect(provider)
        const userAddress = await user.getAddress()
        console.log("User address: ", userAddress)
        console.log("User private key: ", user.privateKey)

        const staking = Staking.attach(stakingAddress, owner)
        const tokenWOW = Token.attach(wowToken, user)

        // Transfer native asset to user
        const transferData = {
            to: userAddress,
            value: ethAmount,
        }
        const transferTx = await owner.sendTransaction(transferData)
        await transferTx.wait()
        console.log(`Transferred ETH to user`)

        // Mint WOW tokens to user
        const mintTx = await tokenWOW.mint(userAddress, wowAmount)
        await mintTx.wait()
        console.log(`Minted WOW to user`)

        // Approve staking contract to spend WOW tokens
        const approveTx = await tokenWOW.approve(stakingAddress, wowAmount)
        await approveTx.wait()
        console.log(`Approved WOW tokens to staking contract`)

        // Stake WOW tokens and purchase band
        const stakeTx = await staking.stake(stakingType, bandLevel, fixedMonths)
        await stakeTx.wait()
        console.log(`Staked WOW tokens`)
    } catch (error) {
        console.log(error)
    }
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
