const { ethers, network } = require("hardhat")
const networkConfig = require("../data/networkConfig.json")
const { TESTNET_NETWORKS, WOW_TOKEN_DECIMALS } = require("./constants")

async function getNetworkConfig() {
    const config = networkConfig[network.name]

    if (!config) {
        throw new Error(`ERROR: No config found for network: ${network.name}`)
    }

    let listingDate = config.listing_date
    if (TESTNET_NETWORKS.includes(network.name) && !listingDate) {
        // Make listing date after 10 minutes from now
        listingDate = Math.floor(Date.now() / 1000) + 600
    }

    const vestingToken = config.vesting_token

    // If staking is not provided using the config,
    // use a dummy address which will be replaced later
    const stakingContract = config.staking_contract || ethers.ZeroAddress

    if (!vestingToken || !listingDate) {
        throw new Error("ERROR: Invalid config")
    }

    return { vestingToken, stakingContract, listingDate }
}

module.exports = getNetworkConfig
