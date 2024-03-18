import { BigNumber } from "ethers"
import { Interface } from "@ethersproject/abi"
import {
    Web3Function,
    Web3FunctionEventContext,
} from "@gelatonetwork/web3-functions-sdk"
import { createClient, fetchExchange, cacheExchange, gql } from "@urql/core"
import { stakingABI } from "../stakingABI"

Web3Function.onRun(async (context: Web3FunctionEventContext) => {
    // Get data from the context
    const { userArgs, storage, log } = context
    const stakingInterface = new Interface(stakingABI)

    try {
        // Parse the event from the log using the provided event ABI
        console.log("Parsing event")
        const event = stakingInterface.parseLog(log)
        console.log(`Event detected: ${event.eventFragment.name}`)

        // Get data from the user arguments
        const stakingAddress: string = userArgs.stakingAddress as string
        const subgraphUrl: string = userArgs.subgraphUrl as string

        // Create a new client for querying the subgraph
        const client = createClient({
            url: subgraphUrl,
            exchanges: [cacheExchange, fetchExchange],
        })

        // Query for the next distribution ID
        const stakingContractQuery = gql`
            query {
                stakingContract(id: "0") {
                    stakingContractAddress
                    nextDistributionId
                }
            }
        `

        // Fetch the next distribution ID from the subgraph
        const stakingQueryResult = await client
            .query(stakingContractQuery, {})
            .toPromise()

        // Get the staking data from the subgraph
        const stakingContractData = stakingQueryResult.data.stakingContract
        const stakingAddressInSubgraph =
            stakingContractData.stakingContractAddress
        const nextDistributionId: number = Number(
            stakingContractData.nextDistributionId,
        )

        // If the staking address in subgraph does not match the provided address
        // It means that gelato function is using wrong staking contract or subgraph
        if (stakingAddressInSubgraph !== stakingAddress) {
            return {
                canExec: false,
                message: `Staking contract address in subgraph (${stakingAddressInSubgraph}) does not match the provided address (${stakingAddress})`,
            }
        }

        // Get the current distribution ID from gelato storage
        const gelatoNextDistributionId: string =
            (await storage.get("nextDistributionId")) ?? "0"
        const distributionId: number = Number(gelatoNextDistributionId)

        // If the next distribution ID in subgraph is greater than in gelato storage
        // It means that a new distribution has been added and we can execute the function
        // Otherwise, all distributions have been processed
        if (nextDistributionId > distributionId) {
            // Increment the distribution ID in gelato storage by one
            // Don't assign it to nextDistributionId to avoid leaving unprocessed distributions
            await storage.set(
                "nextDistributionId",
                (distributionId + 1).toString(),
            )

            // Query for the distribution data
            const fundsDistributionQuery = gql`
                query ($distributionId: String!) {
                    fundsDistribution(id: $distributionId) {
                        token
                        rewards
                        stakers
                    }
                }
            `

            // Fetch the distribution data from the subgraph
            const fundsDistributionQueryResult = await client
                .query(fundsDistributionQuery, {
                    distributionId: gelatoNextDistributionId,
                })
                .toPromise()

            // Get the distribution data
            const fundsDistributionData =
                fundsDistributionQueryResult.data.fundsDistribution

            // Get data for the function call
            const usersArray: string[] = fundsDistributionData.stakers
            const rewardsArray: BigNumber[] = fundsDistributionData.rewards
            const token = fundsDistributionData.token

            console.log("Rewards retrieved successfully")

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
