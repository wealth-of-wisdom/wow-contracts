import { TriggerType } from "@gelatonetwork/automate-sdk"
import { w3f } from "hardhat"
import { getUserArgs, UserArgs } from "./helpers/getUserArgs"
import { deployToIPFS } from "./helpers/deployToIPFS"
import { getAutomateConfig } from "./helpers/getAutomateConfig"
import { setSecrets } from "./helpers/setSecrets"

const main = async () => {
    const syncSharesTask = w3f.get("sync-shares-task")
    const cid: string = await deployToIPFS(syncSharesTask)

    const userArgs: UserArgs = await getUserArgs()
    const { automate, signer, chainId } = getAutomateConfig()

    console.log("Creating task...")

    // Create task using automate sdk
    const { taskId, tx } = await automate.createBatchExecTask({
        name: `Sync shares (cid: ${cid}) (staking: ${userArgs.stakingAddress})`,
        web3FunctionHash: cid,
        web3FunctionArgs: {
            stakingAddress: userArgs.stakingAddress as string,
        },
        trigger: {
            interval: 60 * 60 * 1000, // 1 hour in milliseconds
            type: TriggerType.TIME,
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
    const secrets = syncSharesTask.getSecrets()
    await setSecrets(secrets, signer, chainId, taskId)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
