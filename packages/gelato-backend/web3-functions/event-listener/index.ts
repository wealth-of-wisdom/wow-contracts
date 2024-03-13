import { BigNumber } from "ethers"
import { Interface } from "@ethersproject/abi"
import {
    Web3Function,
    Web3FunctionEventContext,
} from "@gelatonetwork/web3-functions-sdk"
import { createClient, fetchExchange, gql } from "@urql/core"
import { stakingABI } from "./stakingABI"

Web3Function.onRun(async (context: Web3FunctionEventContext) => {
    const { userArgs, storage, log } = context
    const stakingInterface = new Interface(stakingABI)
    const stakingContractsQuery = gql`
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
            exchanges: [fetchExchange],
        })
        const stakingQueryResult = await client
            .query(stakingContractsQuery, {})
            .toPromise()

        const distributionId = (await storage.get("nextDistributionId")) ?? "0"
        const stakingContractsData = stakingQueryResult.data.stakingContracts[0]
        const nextDistributionId = stakingContractsData.nextDistributionId

        if (nextDistributionId > distributionId) {
            await storage.set("nextDistributionId", nextDistributionId)

            const fundsDistributionQuery = gql`
                query ($distributionId: String!) {
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
                .query(fundsDistributionQuery, { distributionId })
                .toPromise()

            const fundsDistributionData =
                fundsDistributionQueryResult.data.fundsDistribution

            const stakingAddress = userArgs.staking as string
            const usersArray: string[] = fundsDistributionData.stakers.map(
                (staker: any) => staker.id,
            )
            const rewardsArray: BigNumber[] = fundsDistributionData.rewards
            const token = fundsDistributionData.token

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
