import { AutomateSDK, TriggerType } from "@gelatonetwork/automate-sdk"
import hre from "hardhat"
import { stakingABI } from "../web3-functions/event-listener/stakingABI"

const { ethers, w3f } = hre

const main = async () => {
    const eventTest = w3f.get("event-listener")
    const userArgs = eventTest.getUserArgs()

    const [deployer] = await ethers.getSigners()
    const chainId = (await ethers.provider.getNetwork()).chainId

    const automate = new AutomateSDK(chainId, deployer)

    // Deploy Web3Function on IPFS
    console.log("Deploying Web3Function on IPFS...")
    const cid = await eventTest.deploy()
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
    .then(() => {
        process.exit()
    })
    .catch((err) => {
        if (err.response) {
            console.error("Error Response:", err.response.body)
        } else {
            console.error("Error:", err.message)
        }
        process.exit(1)
    })
