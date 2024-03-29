const { network } = require("hardhat")
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

    const vestingContract =
        config.vesting_contract || "0x0000000000000000000000000000000000000001"
    const gelatoAddress =
        process.env.GELATO_ADDRESS ||
        "0x0000000000000000000000000000000000000001"

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
