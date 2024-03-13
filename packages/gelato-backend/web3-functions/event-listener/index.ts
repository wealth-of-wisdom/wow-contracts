import { BigNumber } from "ethers"
import { Interface } from "@ethersproject/abi"
import {
    Web3Function,
    Web3FunctionEventContext,
} from "@gelatonetwork/web3-functions-sdk"
import { createClient } from "urql"
import { stakingABI } from "./stakingABI"

Web3Function.onRun(async (context: Web3FunctionEventContext) => {
    const { userArgs, storage, log } = context
    const stakingInterface = new Interface(stakingABI)
    const stakingContractsQuery = `
        query {
            stakingContracts {
                nextDistributionId
            }
        }
    `

    try {
        // Parse the event from the log using the provided event ABI
        console.log("Parsing event")
        const event = stakingInterface.parseLog(log)

        // Handle event data
        console.log(`Event detected: ${event.eventFragment.name}`)

        const client = createClient({
            url: userArgs.subgraph.toString(),
            exchanges: [],
        })
        const stakingQueryResult = await client
            .query(stakingContractsQuery, {})
            .toPromise()

        const distributionId = await storage.get("nextDistributionId")
        const nextDistributionId = stakingQueryResult.data.nextDistributionId

        if (nextDistributionId > distributionId) {
            await storage.set("nextDistributionId", nextDistributionId)

            const fundsDistributionQuery = `
                query {
                    fundsDistribution(id: $distributionId) {
                        token
                        rewards
                        stakers {
                        id
                        }
                    }
                }
            `

            const fundsDistributionQueryResult = await client
                .query(fundsDistributionQuery, {})
                .toPromise()

            const stakingAddress = userArgs.staking as string
            const usersArray: string[] =
                fundsDistributionQueryResult.data.stakers.id
            const rewardsArray: BigNumber[] =
                fundsDistributionQueryResult.data.rewards
            const token = fundsDistributionQueryResult.data.token

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
        }
        return {
            canExec: false,
            message: `No new distribution added`,
        }
    } catch (err) {
        return {
            canExec: false,
            message: `Failed to parse event: ${(err as Error).message}`,
        }
    }
})
