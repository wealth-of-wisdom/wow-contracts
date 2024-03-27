require("@nomicfoundation/hardhat-toolbox")
require("@openzeppelin/hardhat-upgrades")

const dotenv = require("dotenv")
dotenv.config({ path: "./.env" })
dotenv.config({ path: "../../.env" })

const baseConfig = require("../../hardhat.config.js")
module.exports = {
    ...baseConfig,
}
