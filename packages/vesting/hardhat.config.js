require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  settings: {
    optimizer: {
      enabled: true,
      runs: 2000,
      details: {
        yul: true,
        yulDetails: {
          stackAllocation: true,
          optimizerSteps: "dhfoDgvulfnTUtnIf",
        },
      },
    },
  },
  etherscan: {
    apiKey: process.env.SEPOLIA_APIE_KEY,
  },
  sourcify: {
    enabled: true,
  },
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_HOST,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
};
