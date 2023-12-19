const { ethers, upgrades } = require("hardhat");
require("dotenv").config();

async function main() {
  const WOW_Vesting = await ethers.getContractFactory("WOW_Vesting");
  const vesting = await upgrades.deployProxy(WOW_Vesting, [
    process.env.VESTING_TOKEN,
    process.env.LISTING_DATE,
  ]);
  await vesting.waitForDeployment();
  console.log("WOW_Vesting deployed to:", await vesting.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
