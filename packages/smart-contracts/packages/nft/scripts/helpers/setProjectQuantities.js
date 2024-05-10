const levelsData = require("../data/levelsData.json")

async function setProjectQuantities(nftAddress, totalProjectTypes) {
    const Nft = await ethers.getContractFactory("Nft")
    const nft = Nft.attach(nftAddress)

    const MAX_UINT16 = 65535
    totalProjectTypes = parseInt(totalProjectTypes)

    if (totalProjectTypes !== 3) {
        console.log("Only 3 project types are supported at the moment.")
        return
    }

    const standardProjectsQuantities = Array.from(
        { length: totalProjectTypes },
        () => [],
    )

    const genesisProjectsQuantities = Array.from(
        { length: totalProjectTypes },
        () => [],
    )

    for (let data of levelsData) {
        const standardQuantity =
            data.standard_projects_quantity === -1
                ? MAX_UINT16
                : data.standard_projects_quantity
        const premiumQuantity =
            data.premium_projects_quantity === -1
                ? MAX_UINT16
                : data.premium_projects_quantity
        const limitedQuantity =
            data.limited_projects_quantity === -1
                ? MAX_UINT16
                : data.limited_projects_quantity

        if (data.isGenesis) {
            genesisProjectsQuantities[0].push(standardQuantity) // standard
            genesisProjectsQuantities[1].push(premiumQuantity) // premium
            genesisProjectsQuantities[2].push(limitedQuantity) // limited
        } else {
            standardProjectsQuantities[0].push(standardQuantity) // standard
            standardProjectsQuantities[1].push(premiumQuantity) // premium
            standardProjectsQuantities[2].push(limitedQuantity) // limited
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                              SET PROJECTS QUANTITIES
    //////////////////////////////////////////////////////////////////////////*/

    for (let i = 0; i < totalProjectTypes; i++) {
        const quantities = standardProjectsQuantities[i]
        const tx = await nft.setMultipleProjectsQuantity(false, i, quantities)
        await tx.wait()

        console.log(`Project type ${i} quantities set for standard levels`)
    }

    for (let i = 0; i < totalProjectTypes; i++) {
        const quantities = genesisProjectsQuantities[i]
        const tx = await nft.setMultipleProjectsQuantity(true, i, quantities)
        await tx.wait()

        console.log(`Project type ${i} quantities set for genesis levels`)
    }
}

module.exports = setProjectQuantities
