import { AutomateSDK, TriggerType } from "@gelatonetwork/automate-sdk"
import { ethers, w3f, network } from "hardhat"
import { HttpNetworkConfig } from "hardhat/types"
import { JsonRpcProvider } from "@ethersproject/providers"
import { Wallet } from "@ethersproject/wallet"
import { getUserArgs } from "./helpers/getUserArgs"
import stakingABI from "../web3-functions/stakingABI.json"

const main = async () => {
    const distributionTask = w3f.get("distribution-task")
    const userArgs = await getUserArgs()

    const config = network.config as HttpNetworkConfig
    const chainId = config.chainId as number
    const pk = (config.accounts as string[])[0]
    const provider = new JsonRpcProvider(config.url)
    const signer = new Wallet(pk, provider)

    const automate = new AutomateSDK(chainId, signer)

    // Deploy Web3Function on IPFS
    console.log("Deploying Web3Function on IPFS...")
    const cid = await distributionTask.deploy()
    if (!cid) throw new Error("IPFS deployment failed")
    console.log(`Web3Function IPFS CID: ${cid}`)

    console.log("Creating task...")

    const stakingInterface = new ethers.utils.Interface(stakingABI)

    // Create task using automate sdk
    const { taskId, tx } = await automate.createBatchExecTask({
        name: `Distribute rewards (cid: ${cid}) (staking: ${userArgs.stakingAddress})`,
        web3FunctionHash: cid,
        web3FunctionArgs: {
            stakingAddress: userArgs.stakingAddress as string
        },
        trigger: {
            type: TriggerType.EVENT,
            filter: {
                address: userArgs.stakingAddress as string,
                topics: [
                    [stakingInterface.getEventTopic("DistributionCreated")],
                ],
            },
            blockConfirmations: userArgs.blockConfirmations as number,
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
