const { ethers, network } = require("hardhat")
const networkConfig = require("../data/networkConfig.json")

async function getNetworkConfig() {
    const config = networkConfig[network.name]

    if (!config) {
        throw new Error(`ERROR: No config found for network: ${network.name}`)
    }

    const vestingToken = config.vesting_token
    const listingDate = config.listing_date

    const WOW_DECIMALS = 18

    const totalTokens = ethers.parseUnits(
        config.all_pools_token_amount_in_eth,
        WOW_DECIMALS,
    )

    // If staking is not provided using the config,
    // use a dummy address which will be replaced later
    const stakingContract =
        config.staking_contract || "0x0000000000000000000000000000000000000001"

    if (!vestingToken || !listingDate || !totalTokens) {
        throw new Error("ERROR: Invalid config")
    }

    return { vestingToken, stakingContract, listingDate, totalTokens }
}

module.exports = getNetworkConfig
