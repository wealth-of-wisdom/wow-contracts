const hre = require("hardhat");

async function main() {
  const name = "Wealth-Of-Wisdom";
  const symbol = "WOW";
  const initialAmount = 100;

  const WOWToken = await hre.ethers.getContractFactory("WOWToken");
  const token = await WOWToken.deploy(name, symbol, initialAmount);

  await token.deployed();

  console.log(`WOWToken deployed to ${token.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
