// @ts-ignore
const { ethers } = require("hardhat")
const copyTokenContracts = require("../helpers/copyTokenContracts")
const removeTokenContracts = require("../helpers/removeTokenContracts")
const { addVestingPools } = require("../helpers/addVestingPools")
const { addBeneficiaries } = require("../helpers/addBeneficiaries")
const { updateGeneralPoolsData } = require("../helpers/updatePoolData")
const {
    DAILY_UNLOCK_TYPE_STR,
    WOW_TOKEN_DECIMALS,
} = require("../helpers/constants")
require("dotenv").config()

/**
 * @notice This test is not updated and should be used as a reference only.
 */

async function main() {
    // Test flow:
    // 1. Create 3 new pools (without beneficiaries) (Treasury, Team, Advisors)
    // 2. Add beneficiary to a treasury pool
    // 3. Decrease tokens for team and advisors pools
    // 4. Create a new pool treasury V2 with amount that were previously in 2 other pools.

    /*//////////////////////////////////////////////////////////////////////////
                                COPY TOKEN CONTRACT
    //////////////////////////////////////////////////////////////////////////*/

    await copyTokenContracts()

    /*//////////////////////////////////////////////////////////////////////////
                            GET TOKEN AND VESTING ADDRESSES
    //////////////////////////////////////////////////////////////////////////*/

    const vestingAddress = process.env.VESTING_CONTRACT
    const wowTokenAddress = process.env.VESTING_TOKEN

    /*//////////////////////////////////////////////////////////////////////////
                                CREATE POOLS TEST DATA
    //////////////////////////////////////////////////////////////////////////*/

    const poolsData = [
        {
            name: "Team",
            tokens_amount_in_wow: "2000000",
            listing_release_percentage: 50,
            cliff_in_days: 60,
            cliff_release_percentage: 20,
            vesting_in_months: 8,
            unlock_type: DAILY_UNLOCK_TYPE_STR,
        },
        {
            name: "Advisors",
            tokens_amount_in_wow: "5000000",
            listing_release_percentage: 11,
            cliff_in_days: 15,
            cliff_release_percentage: 22,
            vesting_in_months: 3,
            unlock_type: DAILY_UNLOCK_TYPE_STR,
        },
        {
            name: "Treasury",
            tokens_amount_in_wow: "1000000",
            listing_release_percentage: 1,
            cliff_in_days: 30,
            cliff_release_percentage: 50,
            vesting_in_months: 6,
            unlock_type: DAILY_UNLOCK_TYPE_STR,
        },
    ]

    /*//////////////////////////////////////////////////////////////////////////
                            CREATE 3 NEW VESTING POOLS
    //////////////////////////////////////////////////////////////////////////*/

    await addVestingPools(wowTokenAddress, vestingAddress, poolsData)

    const vesting = await ethers.getContractAt("Vesting", vestingAddress)
    const poolsCount = Number(await vesting.getPoolCount())
    const teamPoolId = poolsCount - 3
    const advisorsPoolId = poolsCount - 2
    const treasuryPoolId = poolsCount - 1

    /*//////////////////////////////////////////////////////////////////////////
                          CREATE BENEFICIARIES TEST DATA
    //////////////////////////////////////////////////////////////////////////*/

    const beneficiaries = [
        {
            pool_id: treasuryPoolId,
            beneficiary_address: "0xf00dc4F56e2e4f93F3EBd9f54636C3b90DAfFab2",
            tokens_amount_in_wow: 800000,
        },
    ]

    /*//////////////////////////////////////////////////////////////////////////
                          ADD BENEFICIARY TO TREASURY POOL
    //////////////////////////////////////////////////////////////////////////*/

    await addBeneficiaries(vestingAddress, beneficiaries)

    /*//////////////////////////////////////////////////////////////////////////
                            UPDATED POOLS GENERAL DATA
    //////////////////////////////////////////////////////////////////////////*/

    const newGeneralPoolsData = [
        {
            pool_id: teamPoolId,
            tokens_amount_in_wow: "1000000",
        },
        {
            pool_id: advisorsPoolId,
            tokens_amount_in_wow: "2500000",
        },
    ]

    /*//////////////////////////////////////////////////////////////////////////
                            DECREASE TEAM AND ADVISORS POOLS
    //////////////////////////////////////////////////////////////////////////*/

    await updateGeneralPoolsData(vestingAddress, newGeneralPoolsData)

    /*//////////////////////////////////////////////////////////////////////////
                        CALCULATE AMOUNT TO ADD TO TREASURY V2
    //////////////////////////////////////////////////////////////////////////*/

    const initialAmount = poolsData.reduce(
        (acc, pool) =>
            pool.name != "Treasury"
                ? acc +
                  ethers.parseUnits(
                      pool.tokens_amount_in_wow,
                      WOW_TOKEN_DECIMALS,
                  )
                : acc,
        BigInt(0),
    )

    const newAmount = newGeneralPoolsData.reduce(
        (acc, pool) =>
            acc +
            ethers.parseUnits(pool.tokens_amount_in_wow, WOW_TOKEN_DECIMALS),
        BigInt(0),
    )

    const treasuryV2Amount = initialAmount - newAmount

    console.log(`Treasury V2 amount: ${treasuryV2Amount}`)

    /*//////////////////////////////////////////////////////////////////////////
                          CREATE TREASURY V2 POOL TEST DATA
    //////////////////////////////////////////////////////////////////////////*/

    const formattedAmount = ethers.formatUnits(
        treasuryV2Amount,
        WOW_TOKEN_DECIMALS,
    )

    const poolsDataV2 = [
        {
            name: "Treasury V2",
            tokens_amount_in_wow: formattedAmount,
            listing_release_percentage: 25,
            cliff_in_days: 100,
            cliff_release_percentage: 25,
            vesting_in_months: 12,
            unlock_type: DAILY_UNLOCK_TYPE_STR,
        },
    ]

    /*//////////////////////////////////////////////////////////////////////////
                            CREATE TREASURY V2 VESTING POOLS
    //////////////////////////////////////////////////////////////////////////*/

    await addVestingPools(wowTokenAddress, vestingAddress, poolsDataV2)

    /*//////////////////////////////////////////////////////////////////////////
                                REMOVE TEMPORARY FOLDER
    //////////////////////////////////////////////////////////////////////////*/

    await removeTokenContracts()
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
