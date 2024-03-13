import { BigNumber } from "ethers"
import { Interface } from "@ethersproject/abi"
import {
    Web3Function,
    Web3FunctionEventContext,
} from "@gelatonetwork/web3-functions-sdk"
import { ApolloClient, InMemoryCache, gql } from "@apollo/client"
import { stakingABI } from "./stakingABI"

var s_nextDistributionId = 0

Web3Function.onRun(async (context: Web3FunctionEventContext) => {
    const { userArgs, log } = context
    const stakingInterface = new Interface(stakingABI)

    const client = new ApolloClient({
        uri: process.env.SUBGRAPH_API_URL,
        cache: new InMemoryCache(),
    })
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

        const stakingContractsData = await client.query({
            query: gql(stakingContractsQuery),
        })
        const nextDistributionId = stakingContractsData.data.nextDistributionId
        if (nextDistributionId > s_nextDistributionId) {
            s_nextDistributionId = nextDistributionId

            const fundsDistributionQuery = `
                query {
                    fundsDistribution(id: $s_nextDistributionId) {
                        token
                        rewards
                        stakers {
                        id
                        }
                    }
                }
            `

            const fundsDistributionData = await client.query({
                query: gql(fundsDistributionQuery),
            })

            const stakingAddress = userArgs.staking as string
            const usersArray: string[] = fundsDistributionData.data.stakers.id
            const rewardsArray: BigNumber[] = fundsDistributionData.data.rewards
            const token = fundsDistributionData.data.token

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
