import { AutomateSDK, TriggerType } from "@gelatonetwork/automate-sdk"
import { w3f, network } from "hardhat"
import { HttpNetworkConfig } from "hardhat/types"
import { JsonRpcProvider } from "@ethersproject/providers"
import { Wallet } from "@ethersproject/wallet"

const main = async () => {
    const syncSharesTask = w3f.get("sync-shares-task")
    const userArgs = syncSharesTask.getUserArgs()

    const config = network.config as HttpNetworkConfig
    const chainId = config.chainId as number
    const pk = (config.accounts as string[])[0]
    const provider = new JsonRpcProvider(config.url)
    const signer = new Wallet(pk, provider)

    const automate = new AutomateSDK(chainId, signer)

    // Deploy Web3Function on IPFS
    console.log("Deploying Web3Function on IPFS...")
    const cid = await syncSharesTask.deploy()
    if (!cid) throw new Error("IPFS deployment failed")
    console.log(`Web3Function IPFS CID: ${cid}`)

    console.log("Creating task...")

    // Create task using automate sdk
    const { taskId, tx } = await automate.createBatchExecTask({
        name: "Web3Function - Sync shares",
        web3FunctionHash: cid,
        web3FunctionArgs: {
            stakingAddress: userArgs.stakingAddress as string,
            subgraphUrl: userArgs.subgraphUrl as string,
        },
        trigger: {
            interval: 60 * 60 * 1000, // 1 hour in milliseconds
            type: TriggerType.TIME,
        },
    })

    // Wait for the transaction to be mined
    await tx.wait()
    console.log(`Task created, taskId: ${taskId} (tx hash: ${tx.hash})`)
    console.log(
        `> https://beta.app.gelato.network/task/${taskId}?chainId=${chainId}`,
    )
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
