import { createClient, fetchExchange, cacheExchange, gql } from "@urql/core"

export async function validateUserArgs(
    subgraphUrl: string,
    stakingAddress: string,
) {
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
            }
        }
    `

    // Fetch the date from the subgraph
    const stakingQueryResult = await client
        .query(stakingContractQuery, {})
        .toPromise()

    // Get the staking data from the subgraph
    const stakingContractData = stakingQueryResult.data.stakingContract

    const stakingAddressInSubgraph = stakingContractData.stakingContractAddress

    // If the staking address in subgraph does not match the provided address
    // It means that gelato function is using wrong staking contract or subgraph
    if (stakingAddressInSubgraph !== stakingAddress.toLowerCase()) {
        throw new Error(
            `Staking contract address in subgraph (${stakingAddressInSubgraph}) does not match the provided address (${stakingAddress})`,
        )
    }
}
