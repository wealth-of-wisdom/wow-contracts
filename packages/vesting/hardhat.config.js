require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

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
      ethereum: process.env.ETHEREUM_API_KEY,
      sepolia: process.env.SEPOLIA_API_KEY,
    },
  },
  sourcify: {
    enabled: true,
  },
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_HOST,
      accounts: [process.env.PRIVATE_KEY],
    },
    ethereum: {
      url: process.env.ETHEREUM_HOST,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
};
