const { ethers, upgrades } = require("hardhat");

async function main() {
  const name = "Wealth-Of-Wisdom";
  const symbol = "WOW";
  const initialAmount = 100;
  const WOWToken = await ethers.getContractFactory("WOWToken");
  const token = await upgrades.deployProxy(WOWToken, [
    name,
    symbol,
    initialAmount,
  ]);
  await token.waitForDeployment();
  console.log("WOWToken deployed to:", await token.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
