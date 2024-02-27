import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url";
import {
  Web3Function,
  Web3FunctionEventContext,
} from "@gelatonetwork/web3-functions-sdk";
import { Contract } from "@ethersproject/contracts";
import { Wallet } from "ethers";
import { main } from "./main";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
// Configure dotenv to load the .env file from the root directory
dotenv.config({ path: path.resolve(__dirname, "../../.env") });
const STAKING_ABI = [
  "event DistributionCreated(IERC20 token, uint256 amount, uint256 totalPools, uint256 totalBandLevels, uint256 totalStakers)",
  "function distributeRewards(IERC20 token, address[] memory stakers, uint256[] memory rewards)",
];

Web3Function.onRun(async (context: Web3FunctionEventContext) => {
  // Get event log from Web3FunctionEventContext
  const { userArgs, multiChainProvider, storage, log } = context;

  const privateKey = await context.secrets.get("PRIVATE_KEY");
  const sepoliaRpcUrl = await context.secrets.get("SEPOLIA_RPC_URL");
  const provider = multiChainProvider.default();
  const stakingAddress = userArgs.staking as string;
  const wallet = new Wallet(privateKey!, provider);
  const staking = new Contract(stakingAddress, STAKING_ABI, wallet);

  // Parse event from ABI
  const event = staking.interface.parseLog(log);
  const currentBlock = await provider.getBlockNumber();
  const distributionTimestamp = (await provider.getBlock(currentBlock))
    .timestamp;

  // Handle event data
  const { token, amount, totalPools, totalBandLevels, totalStakers } =
    event.args;

  await main(
    token,
    amount,
    totalPools,
    totalBandLevels,
    totalStakers,
    distributionTimestamp,
    stakingAddress,
    privateKey!,
    sepoliaRpcUrl!,
  );
  return { canExec: false, message: `Event processed ${log.transactionHash}` };
});