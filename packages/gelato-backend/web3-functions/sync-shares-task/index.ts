import { BigNumber } from "ethers"
import { Interface } from "@ethersproject/abi"
import {
    Web3Function,
    Web3FunctionContext,
} from "@gelatonetwork/web3-functions-sdk"
import { createClient, fetchExchange, cacheExchange, gql } from "@urql/core"
import { stakingABI } from "../stakingABI"

Web3Function.onRun(async (context: Web3FunctionContext) => {
    // Get data from the context
    const { userArgs, storage } = context
    const stakingInterface = new Interface(stakingABI)

    try {
        // Get data from the user arguments
        const stakingAddress: string = userArgs.stakingAddress as string
        const subgraphUrl: string = userArgs.subgraphUrl as string

        // Get data from storage
        const updateInterval: number =
            Number(await storage.get("updateIntervalInSeconds")) ?? 0

        // Create a new client for querying the subgraph
        const client = createClient({
            url: subgraphUrl,
            exchanges: [cacheExchange, fetchExchange],
        })

        // Query for the last date the shares were synced
        const stakingContractQuery = gql`
            query {
                stakingContract(id: "0") {
                    stakingContractAddress
                    lastSharesSyncDate
                }
            }
        `

        // Fetch the date from the subgraph
        const stakingQueryResult = await client
            .query(stakingContractQuery, {})
            .toPromise()

        // Get the staking data from the subgraph
        const stakingContractData = stakingQueryResult.data.stakingContract
        const stakingAddressInSubgraph =
            stakingContractData.stakingContractAddress
        const lastSynced: number = Number(
            stakingContractData.lastSharesSyncDate,
        )

        // If the staking address in subgraph does not match the provided address
        // It means that gelato function is using wrong staking contract or subgraph
        if (stakingAddressInSubgraph !== stakingAddress) {
            return {
                canExec: false,
                message: `Staking contract address in subgraph (${stakingAddressInSubgraph}) does not match the provided address (${stakingAddress})`,
            }
        }

        const timePassed: number = Math.floor(Date.now() / 1000) - lastSynced

        if (timePassed >= updateInterval) {
            console.log(
                `${updateInterval} seconds have passed since the last sync`,
            )

            return {
                canExec: true,
                callData: [
                    {
                        to: stakingAddress,
                        data: stakingInterface.encodeFunctionData(
                            "triggerSharesSync",
                            [],
                        ),
                    },
                ],
            }
        }

        return {
            canExec: false,
            message: `Only ${timePassed} seconds have passed since the last sync. Waiting for ${updateInterval} seconds to pass.`,
        }
    } catch (err) {
        return {
            canExec: false,
            message: `Failed to execute: ${(err as Error).message}`,
        }
    }
})
