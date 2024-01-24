require("@nomicfoundation/hardhat-toolbox")
require("@openzeppelin/hardhat-upgrades")
require("dotenv").config()

module.exports = {
    solidity: {
        version: "0.8.20",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    etherscan: {
        apiKey: process.env.SEPOLIA_API_KEY,
        mainnet: process.env.ETHEREUM_API_KEY,
    },
    networks: {
        anvil: {
            url: process.env.ANVIL_HOST,
            accounts: [process.env.ANVIL_PRIVATE_KEY],
        },
        sepolia: {
            url: process.env.SEPOLIA_HOST,
            accounts: [process.env.PRIVATE_KEY],
        },
        mainnet: {
            url: process.env.ETHEREUM_HOST,
            accounts: [process.env.PRIVATE_KEY],
        },
    },
}
