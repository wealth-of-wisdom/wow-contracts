import { AutomateSDK } from "@gelatonetwork/automate-sdk"
import { network } from "hardhat"
import { HttpNetworkConfig } from "hardhat/types"
import { JsonRpcProvider } from "@ethersproject/providers"
import { Wallet } from "@ethersproject/wallet"

type AutomateConfig = {
    automate: AutomateSDK
    signer: Wallet
    chainId: number
}

export const getAutomateConfig = (): AutomateConfig => {
    const config = network.config as HttpNetworkConfig
    const chainId = config.chainId as number
    const pk = (config.accounts as string[])[0]
    const provider = new JsonRpcProvider(config.url)
    const signer = new Wallet(pk, provider)

    const automate = new AutomateSDK(chainId, signer)

    return {
        automate,
        signer,
        chainId,
    }
}
