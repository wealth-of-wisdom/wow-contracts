import { HardhatUserConfig } from "hardhat/config";

// PLUGINS
import "@gelatonetwork/web3-functions-sdk/hardhat-plugin";
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-verify";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-deploy";

// ================================= TASKS =========================================

// Process Env Variables
import * as dotenv from "dotenv";
dotenv.config({ path: __dirname + "/.env" });

// Libraries
import assert from "assert";

// Process Env Variables
const ALCHEMY_ID = process.env.ALCHEMY_ID;
assert.ok(ALCHEMY_ID, "no Alchemy ID in process.env");
const INFURA_ID = process.env.INFURA_ID;
assert.ok(INFURA_ID, "no Infura ID in process.env");

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ETHERSCAN_KEY = process.env.ETHERSCAN_KEY;

// ================================= CONFIG =========================================
const config: HardhatUserConfig = {
  w3f: {
    rootDir: "./web3-functions",
    debug: false,
    networks: ["ethereum", "sepolia"], //(multiChainProvider) injects provider for these networks
  },

  namedAccounts: {
    deployer: {
      default: 0,
    },
  },

  defaultNetwork: "hardhat",

  networks: {
    hardhat: {
      chainId: 31337,
      forking: {
        url: `https://polygon-mumbai.g.alchemy.com/v2/${ALCHEMY_ID}`,
        blockNumber: 43781363,
      },
    },

    // Prod
    ethereum: {
      chainId: 1,
      url: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_ID}`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },

    // Staging
    sepolia: {
      chainId: 11155111,
      url: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_ID}`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
  },

  verify: {
    etherscan: {
      apiKey: ETHERSCAN_KEY ? ETHERSCAN_KEY : "",
    },
  },

  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: {
          optimizer: { enabled: true },
        },
      },
    ],
  },

  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
};

export default config;
