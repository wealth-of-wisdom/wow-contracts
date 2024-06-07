import { Web3Function } from "@gelatonetwork/automate-sdk"
import { Wallet } from "@ethersproject/wallet"

type Secrets = {
    [key: string]: string
}

export const setSecrets = async (
    secrets: Secrets,
    signer: Wallet,
    chainId: number,
    taskId: string,
): Promise<void> => {
    const web3Function = new Web3Function(chainId, signer)

    if (Object.keys(secrets).length > 0) {
        await web3Function.secrets.set(secrets, taskId)
        console.log(`Secrets set`)
    }
}
