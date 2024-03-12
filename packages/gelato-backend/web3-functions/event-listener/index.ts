import { BigNumber } from "ethers"
import { Interface } from "@ethersproject/abi"
import {
    Web3Function,
    Web3FunctionEventContext,
} from "@gelatonetwork/web3-functions-sdk"
import { ApolloClient, InMemoryCache, gql } from "@apollo/client"
import { stakingABI } from "./stakingABI"

Web3Function.onRun(async (context: Web3FunctionEventContext) => {
    const { userArgs, log } = context
    const stakingInterface = new Interface(stakingABI)
    const tokensQuery = `
        query {
            fundsDistribution(id: "0") {
                token
                rewards
                stakers {
                id
                }
            }
        }
    `

    try {
        // Parse the event from the log using the provided event ABI
        console.log("Parsing event")
        const event = stakingInterface.parseLog(log)

        // Handle event data
        console.log(`Event detected: ${event.eventFragment.name}`)

        const client = new ApolloClient({
            uri: process.env.SUBGRAPH_API_URL,
            cache: new InMemoryCache(),
        })
        const clientData = await client.query({
            query: gql(tokensQuery),
        })

        const stakingAddress = userArgs.staking as string
        const usersArray: string[] = clientData.data.stakers.id
        const rewardsArray: BigNumber[] = clientData.data.rewards
        const token = clientData.data.token

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
