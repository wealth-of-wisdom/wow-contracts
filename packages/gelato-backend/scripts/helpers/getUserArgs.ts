import { network } from "hardhat"
import config from "../config.json"
import { validateUserArgs } from "./validateUserArgs"

type UserArgs = {
    stakingAddress: string
    subgraphUrl: string
    blockConfirmations?: number
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

    if (!args.stakingAddress) {
        throw new Error(
            `getUserArgs ERROR: No stakingAddress found for network: ${network.name}`,
        )
    }

    if (!args.subgraphUrl) {
        throw new Error(
            `getUserArgs ERROR: No subgraphUrl found for network: ${network.name}`,
        )
    }

    await validateUserArgs(
        args.subgraphUrl,
        args.stakingAddress,
        args.blockConfirmations,
    )

    return args
}
