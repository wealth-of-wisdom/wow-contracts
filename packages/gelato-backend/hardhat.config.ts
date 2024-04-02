import { HardhatUserConfig } from "hardhat/config"

// PLUGINS
import "@gelatonetwork/web3-functions-sdk/hardhat-plugin"
// import "@matterlabs/hardhat-zksync-solc"
// import "@matterlabs/hardhat-zksync-verify"
import "@nomiclabs/hardhat-ethers"
import "@nomiclabs/hardhat-waffle"
import "@typechain/hardhat"
import "hardhat-deploy"

// Process Env Variables
import * as dotenv from "dotenv"
dotenv.config({ path: __dirname + "/.env" })

const PRIVATE_KEY = process.env.PRIVATE_KEY as string
const ETHEREUM_RPC_URL = process.env.ETHEREUM_RPC_URL as string
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL as string
const ARBITURM_ONE_RPC_URL = process.env.ARBITURM_ONE_RPC_URL as string
const ARBITRUM_SEPOLIA_RPC_URL = process.env.ARBITRUM_SEPOLIA_RPC_URL as string

/*//////////////////////////////////////////////////////////////////////////
                                CONFIG
//////////////////////////////////////////////////////////////////////////*/

const config: HardhatUserConfig = {
    w3f: {
        rootDir: "./web3-functions",
        debug: false,
        networks: [
            "hardhat",
            "sepolia",
            "ethereum",
            "arbitrumSepolia",
            "arbitrumOne",
        ], // (multiChainProvider) injects provider for these networks
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
                url: SEPOLIA_RPC_URL,
            },
        },
        ethereum: {
            chainId: 1,
            url: ETHEREUM_RPC_URL,
            accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
        },
        sepolia: {
            chainId: 11155111,
            url: SEPOLIA_RPC_URL,
            accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
        },
        arbitrumSepolia: {
            chainId: 421614,
            url: process.env.ARBITRUM_SEPOLIA_RPC_URL,
            accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
        },
        arbitrumOne: {
            chainId: 42161,
            url: process.env.ARBITRUM_ONE_RPC_URL,
            accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
        },
    },

    typechain: {
        outDir: "typechain",
        target: "ethers-v5",
    },
}

export default config
