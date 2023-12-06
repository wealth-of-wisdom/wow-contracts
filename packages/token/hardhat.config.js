require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  etherscan: {
    apiKey: process.env.SEPOLIA_API_KEY,
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
