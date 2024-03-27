require("@nomicfoundation/hardhat-toolbox")
require("@openzeppelin/hardhat-upgrades")
require("dotenv").config()

module.exports = {
    solidity: {
        version: "0.8.20",
        settings: {
            viaIR: true,
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    etherscan: {
        apiKey: {
            sepolia: process.env.SEPOLIA_API_KEY,
            mainnet: process.env.ETHEREUM_API_KEY,
            arbitrumSepolia: process.env.ARBITRUM_SEPOLIA_API_KEY,
            arbitrumOne: process.env.ARBITRUM_ONE_API_KEY,
        },
    },
    sourcify: {
        enabled: true,
    },
    networks: {
        sepolia: {
            chainId: 11155111,
            url: process.env.SEPOLIA_HOST,
            accounts: [process.env.PRIVATE_KEY],
        },
        mainnet: {
            chainId: 1,
            url: process.env.ETHEREUM_HOST,
            accounts: [process.env.PRIVATE_KEY],
        },
        arbitrumSepolia: {
            chainId: 421614,
            url: process.env.ARBITRUM_SEPOLIA_HOST,
            accounts: [process.env.PRIVATE_KEY],
        },
        arbitrumOne: {
            chainId: 42161,
            url: process.env.ARBITRUM_ONE_HOST,
            accounts: [process.env.PRIVATE_KEY],
        },
        hardhat: {
            chainId: 31337,
        },
    },
}
