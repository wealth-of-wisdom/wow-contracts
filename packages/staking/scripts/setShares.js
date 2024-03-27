const sharesData = require("../sharesData.json")

async function setShares(staking) {
    /*//////////////////////////////////////////////////////////////////////////
                                SET SHARES IN MONTH
    //////////////////////////////////////////////////////////////////////////*/

    const sharesArray = sharesData[0].shares
    const tx = await staking.setSharesInMonth(sharesArray)
    await tx.wait()

    console.log(`Shares in month set`)
}

module.exports = setShares
