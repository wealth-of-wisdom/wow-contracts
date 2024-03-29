const deployNft = require("./helpers/deployNft.js")
const deployNftSale = require("./helpers/deployNftSale.js")
const copyVestingContracts = require("./helpers/copyVestingContracts.js")
const removeVestingContracts = require("./helpers/removeVestingContracts.js")
const setupVestingPermissions = require("./helpers/setupVestingPermissions.js")
const setupNftPermissions = require("./helpers/setupNftPermissions.js")
const setLevelsData = require("./helpers/setLevelsData.js")
const setProjectQuantities = require("./helpers/setProjectQuantities.js")
const verifyContracts = require("./helpers/verifyContracts.js")
const getNetworkConfig = require("./helpers/getNetworkConfig.js")
require("dotenv").config()

async function main() {
    const {
        usdtToken,
        usdcToken,
        nftName,
        nftSymbol,
        vestingContract,
        vestingPoolId,
        maxLevel,
        totalProjectTypes,
        shouldSetProjectQuantities,
    } = await getNetworkConfig()

    // Copy contract from token package to allow access to token functions
    await copyVestingContracts()

    /*//////////////////////////////////////////////////////////////////////////
                                  DEPLOY NFT TOKEN
    //////////////////////////////////////////////////////////////////////////*/

    const nftAddress = await deployNft(
        nftName,
        nftSymbol,
        vestingContract,
        vestingPoolId,
        maxLevel,
        totalProjectTypes,
    )

    /*//////////////////////////////////////////////////////////////////////////
                                  DEPLOY NFT SALE
    //////////////////////////////////////////////////////////////////////////*/

    const nftSaleAddress = await deployNftSale(nftAddress, usdtToken, usdcToken)

    /*//////////////////////////////////////////////////////////////////////////
                            GRANT PERMISSIONS IN VESTING
    //////////////////////////////////////////////////////////////////////////*/

    await setupVestingPermissions(nftSaleAddress, vestingContract)

    /*//////////////////////////////////////////////////////////////////////////
                              GRANT PERMISSIONS IN NFT
    //////////////////////////////////////////////////////////////////////////*/

    await setupNftPermissions(nftAddress, nftSaleAddress)

    /*//////////////////////////////////////////////////////////////////////////
                                    SET LEVELS
    //////////////////////////////////////////////////////////////////////////*/

    await setLevelsData(nftAddress)

    /*//////////////////////////////////////////////////////////////////////////
                              SET PROJECTS QUANTITIES
    //////////////////////////////////////////////////////////////////////////*/

    if (shouldSetProjectQuantities) {
        await setProjectQuantities(nftAddress)
    }

    /*//////////////////////////////////////////////////////////////////////////
                                VERIFY CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    await verifyContracts(nftAddress, nftSaleAddress)

    // Remove temp folders
    await removeVestingContracts()
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
