const { ethers, network } = require("hardhat")
const networkConfig = require("../data/networkConfig.json")
require("dotenv").config()

async function getNetworkConfig() {
    let config = networkConfig[network.name]

    if (!config) {
        throw new Error(`ERROR: No config found for network: ${network.name}`)
    }

    const usdtToken = config.usdt_token
    const usdcToken = config.usdc_token
    const wowToken = config.wow_token
    const totalPools = config.total_pools
    const totalBandLevels = config.total_band_levels

    if (
        !usdtToken ||
        !usdcToken ||
        !wowToken ||
        !totalPools ||
        !totalBandLevels
    ) {
        throw new Error("ERROR: Invalid config")
    }

    // If vesting or gelato is not provided using the config,
    // use a dummy address which will be replaced later
    const vestingContract = config.vesting_contract || ethers.ZeroAddress
    const gelatoAddress = process.env.GELATO_ADDRESS || ethers.ZeroAddress

    return {
        usdtToken,
        usdcToken,
        wowToken,
        vestingContract,
        gelatoAddress,
        totalPools,
        totalBandLevels,
    }
}

module.exports = getNetworkConfig
