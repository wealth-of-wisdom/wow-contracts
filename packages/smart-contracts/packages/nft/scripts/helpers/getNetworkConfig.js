const { network, ethers } = require("hardhat")
const networkConfig = require("../data/networkConfig.json")

async function getNetworkConfig() {
    let config = networkConfig[network.name]

    if (!config) {
        throw new Error(`ERROR: No config found for network: ${network.name}`)
    }

    const usdtToken = config.usdt_token
    const usdcToken = config.usdc_token
    const nftName = config.nft_name
    const nftSymbol = config.nft_symbol
    const maxLevel = config.max_level
    const totalProjectTypes = config.total_project_types

    if (
        !usdtToken ||
        !usdcToken ||
        !nftName ||
        !nftSymbol ||
        !maxLevel ||
        !totalProjectTypes
    ) {
        throw new Error("ERROR: Invalid config")
    }

    // If vesting or gelato is not provided using the config,
    // use a zero address which will be replaced later
    const vestingContract = config.vesting_contract || ethers.ZeroAddress
    const vestingPoolId = config.vesting_pool_id // Pool id can be zero
    const shouldSetProjectQuantities = config.set_project_quantities

    return {
        usdtToken,
        usdcToken,
        nftName,
        nftSymbol,
        vestingContract,
        vestingPoolId,
        maxLevel,
        totalProjectTypes,
        shouldSetProjectQuantities,
    }
}

module.exports = getNetworkConfig
