const upgradeStaking = require("./helpers/upgradeStaking")
const verifyStaking = require("./helpers/verifyStaking")
require("dotenv").config()

async function main() {
    /*//////////////////////////////////////////////////////////////////////////
                                UPGRADE STAKING
    //////////////////////////////////////////////////////////////////////////*/

    await upgradeStaking(process.env.STAKING_PROXY_ADDRESS)

    /*//////////////////////////////////////////////////////////////////////////
                                      VERIFY STAKING
    //////////////////////////////////////////////////////////////////////////*/

    await verifyStaking(process.env.STAKING_PROXY_ADDRESS)
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
