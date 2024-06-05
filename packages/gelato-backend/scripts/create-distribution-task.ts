import { TriggerType } from "@gelatonetwork/automate-sdk"
import { ethers, w3f } from "hardhat"
import { getUserArgs, UserArgs } from "./helpers/getUserArgs"
import { setSecrets } from "./helpers/setSecrets"
import { deployToIPFS } from "./helpers/deployToIPFS"
import { getAutomateConfig } from "./helpers/getAutomateConfig"
import stakingABI from "../web3-functions/stakingABI.json"

const main = async () => {
    const distributionTask = w3f.get("distribution-task")

    const cid: string = await deployToIPFS(distributionTask)

    const userArgs: UserArgs = await getUserArgs()
    const { automate, signer, chainId } = getAutomateConfig()

    console.log("Creating task...")

    const stakingInterface = new ethers.utils.Interface(stakingABI)

    // Create task using automate sdk
    const { taskId, tx } = await automate.createBatchExecTask({
        name: `Distribute rewards (cid: ${cid}) (staking: ${userArgs.stakingAddress})`,
        web3FunctionHash: cid,
        web3FunctionArgs: {
            stakingAddress: userArgs.stakingAddress as string,
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

    if (!taskId) throw new Error("Task creation failed")

    // Wait for the transaction to be mined
    await tx.wait()
    console.log(`Task created, taskId: ${taskId} (tx hash: ${tx.hash})`)
    console.log(
        `> https://beta.app.gelato.network/task/${taskId}?chainId=${chainId}`,
    )

    // Set task specific secrets
    const secrets = distributionTask.getSecrets()
    await setSecrets(secrets, signer, chainId, taskId)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
