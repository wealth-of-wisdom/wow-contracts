import { network } from "hardhat"
import config from "./config.json"

type UserArgs = {
    stakingAddress: string
    subgraphUrl: string
}

type NetworkConfig = {
    [key: string]: UserArgs
}

export const getUserArgs = async () => {
    const networkConfig: NetworkConfig = config

    let args: UserArgs = networkConfig[network.name]

    if (!args) {
        throw new Error(
            `getUserArgs ERROR: No config found for network: ${network.name}`,
        )
    }

    return args
}
