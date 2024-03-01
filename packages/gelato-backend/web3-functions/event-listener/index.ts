import { BigNumber } from "ethers"
import { Interface } from "@ethersproject/abi"
import {
    Web3Function,
    Web3FunctionEventContext,
} from "@gelatonetwork/web3-functions-sdk"
import { main } from "./main"
import { stakingABI } from "./stakingABI"

Web3Function.onRun(async (context: Web3FunctionEventContext) => {
    const { userArgs, multiChainProvider, log } = context
    const provider = multiChainProvider.default()
    const stakingInterface = new Interface(stakingABI)

    try {
        // Parse the event from the log using the provided event ABI
        console.log("Parsing event")
        const event = stakingInterface.parseLog(log)

        // Handle event data
        console.log(`Event detected: ${event.eventFragment.name}`)

        const [
            token,
            amount,
            totalPools,
            totalBandLevels,
            totalStakers,
            distributionTimestamp,
        ] = event.args

        const stakingAddress = userArgs.staking as string

        const userRewards: Map<string, BigNumber> = await main(
            amount,
            totalPools,
            totalBandLevels,
            totalStakers,
            distributionTimestamp,
            stakingAddress,
            provider,
        )

        const usersArray: string[] = Array.from(userRewards.keys())
        const rewardsArray: BigNumber[] = Array.from(userRewards.values())

        console.log("Rewards calculated successfully")

        return {
            canExec: true,
            callData: [
                {
                    to: stakingAddress,
                    data: stakingInterface.encodeFunctionData(
                        "distributeRewards",
                        [token, usersArray, rewardsArray],
                    ),
                },
            ],
        }
    } catch (err) {
        return {
            canExec: false,
            message: `Failed to parse event: ${(err as Error).message}`,
        }
    }
})
