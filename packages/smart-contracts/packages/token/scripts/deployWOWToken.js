const deployWOWToken = require("./helpers/deployWOWToken")
const verifyToken = require("./helpers/verifyToken")
const config = require("./data/config")

async function main() {
    if (!config.name || !config.symbol || !config.initial_token_amount_in_eth) {
        throw new Error("Please provide config in data/config.json")
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  DEPLOY TOKEN
    //////////////////////////////////////////////////////////////////////////*/

    const tokenAddress = await deployWOWToken(
        config.name,
        config.symbol,
        config.initial_token_amount_in_eth,
    )

    /*//////////////////////////////////////////////////////////////////////////
                                  VERIFY TOKEN
    //////////////////////////////////////////////////////////////////////////*/

    await verifyToken(tokenAddress)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})

module.exports = deployWOWToken
