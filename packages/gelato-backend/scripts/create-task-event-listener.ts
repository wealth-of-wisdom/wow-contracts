import { AutomateSDK, TriggerType } from "@gelatonetwork/automate-sdk"
import { ethers, w3f } from "hardhat"
import { JsonRpcProvider } from "@ethersproject/providers"
import { Wallet } from "@ethersproject/wallet"
import { stakingABI } from "../web3-functions/event-listener/stakingABI"
import dotenv from "dotenv"
dotenv.config()

const main = async () => {
    const network = await ethers.provider.getNetwork()
    const chainId = Number(network.chainId)
    const networkName = network.name

    if (!process.env.PRIVATE_KEY) throw new Error("Missing env PRIVATE_KEY")
    const pk = process.env.PRIVATE_KEY

    let providerUrl
    if (networkName === "sepolia" || networkName === "hardhat") {
        if (!process.env.SEPOLIA_RPC_URL)
            throw new Error("Missing env SEPOLIA_RPC_URL")
        providerUrl = process.env.SEPOLIA_RPC_URL
    } else if (networkName === "ethereum") {
        if (!process.env.ETHEREUM_RPC_URL)
            throw new Error("Missing env ETHEREUM_RPC_URL")
        providerUrl = process.env.ETHEREUM_RPC_URL
    }

    console.log("Provider URL:", providerUrl)

    const eventListenerTask = w3f.get("event-listener")
    const userArgs = eventListenerTask.getUserArgs()

    const provider = new JsonRpcProvider(providerUrl)
    const signer = new Wallet(pk as string, provider)

    const automate = new AutomateSDK(chainId, signer)

    // Deploy Web3Function on IPFS
    console.log("Deploying Web3Function on IPFS...")
    const cid = await eventListenerTask.deploy()
    if (!cid) throw new Error("IPFS deployment failed")
    console.log(`Web3Function IPFS CID: ${cid}`)

    // Create task using automate sdk
    console.log("Creating automate task...")

    const stakingInterface = new ethers.utils.Interface(stakingABI)

    const { taskId, tx } = await automate.createBatchExecTask({
        name: "Web3Function - Event listener",
        web3FunctionHash: cid,
        web3FunctionArgs: {
            stakingAddress: userArgs.stakingAddress as string,
            subgraphUrl: userArgs.subgraphUrl as string,
            eventTopic: userArgs.eventTopic as string,
        },
        trigger: {
            type: TriggerType.EVENT,
            filter: {
                address: userArgs.stakingAddress as string,
                topics: [
                    [
                        stakingInterface.getEventTopic(
                            userArgs.eventTopic as string,
                        ),
                    ],
                ],
            },
            blockConfirmations: 0,
        },
    })

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
