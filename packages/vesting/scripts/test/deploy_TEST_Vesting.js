const { ethers, upgrades } = require("hardhat");

async function main() {
  const name = "Wealth-Of-Wisdom";
  const symbol = "WOW";
  const initialAmount = 100;
  const listingDate = 1702900798;

  const WOWToken = await ethers.getContractFactory("WOWToken");
  const token = await upgrades.deployProxy(WOWToken, [
    name,
    symbol,
    initialAmount,
  ]);
  await token.waitForDeployment();

  const WOW_Vesting = await ethers.getContractFactory("WOW_Vesting");
  const vesting = await upgrades.deployProxy(WOW_Vesting, [token, listingDate]);
  await vesting.waitForDeployment();
  console.log("WOW_Vesting deployed to:", await vesting.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
