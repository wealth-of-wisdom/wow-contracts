import {
  getDefaultProvider,
  Wallet,
  Contract,
  ethers,
  BigNumber,
} from "ethers";

export enum StakingTypes {
  FLEXI = 0,
  FIX = 1,
}

interface StakerBand {
  stakingStartDate: number;
  fixedShares: number;
  owner: string;
  bandLevel: number;
  stakingType: StakingTypes;
}

//@todo add abi
const stakingABI: any = [];
// __dirname is not available in ES modules, so we need to derive it

export async function main(
  token: string,
  totalAmount: BigNumber,
  totalPools: number,
  totalBandLevels: number,
  usersAmount: number,
  distributionDate: number,
  stakingAddress: string,
  privateKey: string,
  sepoliaRpcUrl: string,
) {
  const provider = getDefaultProvider(sepoliaRpcUrl);
  const wallet = new Wallet(privateKey, provider);
  const staking = new Contract(stakingAddress, stakingABI, wallet);

  const sharesInMonth = await staking.getSharesInMonth();

  // Calculate how many tokens each pool will receive
  const poolAllocations = await calculateAllPoolAllocations(
    staking,
    totalPools,
    totalAmount,
  );
  // Loop through all band levels once to store all accessible pools
  const bandLevelPoolIds = await getBandLevelPoolIds(staking, totalBandLevels);

  // Add shares for each user and pool
  const [sharesForPools, sharesForUsers] = await addPoolsAndUsersShares(
    staking,
    totalPools,
    usersAmount,
    distributionDate,
    bandLevelPoolIds,
    sharesInMonth,
  );

  // Add token rewards for each user
  const userRewards = await addUserRewards(
    poolAllocations,
    sharesForPools,
    sharesForUsers,
  );

  // Call staking contract to distribute tokens to each user
  try {
    const tx = await staking.distributeRewards(
      token,
      userRewards.keys(),
      userRewards.values(),
    );
    await tx.wait();
  } catch (err) {
    console.error("Failed to distribute rewards:", err);
    throw err; // Propagate the error
  }
}

async function addUserRewards(
  poolAllocations: BigNumber[],
  sharesForPools: number[],
  sharesForUsers: Map<string, number[]>,
): Promise<Map<string, number>> {
  const userRewards: Map<string, number> = new Map();
  // Loop through each user and distribute funds
  for (const [user, userShares] of sharesForUsers) {
    let allocation: BigNumber = new BigNumber(0, "");

    // Loop through all pools and distribute funds to the user
    for (let i = 0; i < poolAllocations.length; i++) {
      const userPoolShares: number = userShares[i];
      const totalPoolShares: number = sharesForPools[i];
      const totalAmount: BigNumber = poolAllocations[i];

      allocation = allocation.add(
        totalAmount.mul(userPoolShares).div(totalPoolShares),
      );
    }
    userRewards.set(user, Number(allocation));
  }
  return userRewards;
}

async function addPoolsAndUsersShares(
  staking: Contract,
  totalPools: number,
  usersAmount: number,
  distributionDate: number,
  bandLevelPoolIds: number[][],
  sharesInMonth: number[],
): Promise<[number[], Map<string, number[]>]> {
  // Initialize array with 0 shares for each pool
  const sharesForPools: number[] = new Array(totalPools).fill(0);

  // Map from user address to array of pools shares amount
  const sharesForUsers: Map<string, number[]> = new Map();

  // Loop through all users and set the amount of shares
  for (let i = 0; i < usersAmount; i++) {
    const user = await staking.getUser(i);
    // Loop through all bands and add shares to pools
    const userSharesPerPool: number[] = await addMultipleBandSharesToPools(
      staking,
      user,
      totalPools,
      distributionDate,
      bandLevelPoolIds,
      sharesInMonth,
    );

    // Add shares to the users map
    sharesForUsers.set(user, userSharesPerPool);

    // Loop through all pools and add user shares to the pool
    for (let j = 0; j < totalPools; j++) {
      const poolShare: number = userSharesPerPool[j];
      // Add user shares to the pool
      sharesForPools[j] += poolShare;
    }
  }
  return [sharesForPools, sharesForUsers];
}

async function addMultipleBandSharesToPools(
  staking: Contract,
  user: string,
  totalPools: number,
  distributionDate: number,
  bandLevelPoolIds: number[][],
  sharesInMonth: number[],
): Promise<number[]> {
  const bandIds = await staking.getStakerBands(user);
  const bandsAmount = bandIds.length;

  // Initialize array with 0 shares for each pool
  const userSharesPerPool: number[] = new Array(totalPools).fill(0);

  // Loop through all bands that user owns and set the amount of shares
  for (let i = 0; i < bandsAmount; i++) {
    const bandId = bandIds[i];
    const band = await staking.getStakerBand(bandId);
    const bandShares = await calculateBandShares(
      band,
      distributionDate,
      sharesInMonth,
    );

    // No need to add shares if there is nothing to add
    if (bandShares > 0) {
      const pools = bandLevelPoolIds[band.bandLevel - 1];
      const poolsAmount = pools.length;

      // Loop through all pools and set the amount of shares
      for (let j = 0; j < poolsAmount; j++) {
        const poolId = pools[j];

        // Add shares to the user in the pool
        userSharesPerPool[poolId - 1] += bandShares;
      }
    }
  }

  return userSharesPerPool;
}

async function getBandLevelPoolIds(
  staking: Contract,
  totalBandLevels: number,
): Promise<number[][]> {
  const poolIds: number[][] = [];

  // Loop through all band levels and store all accessible pools
  for (let bandLevel = 1; bandLevel <= totalBandLevels; bandLevel++) {
    const bandLevelData = await staking.getBandLevel(bandLevel);
    poolIds.push(bandLevelData.accessiblePools);
  }

  return poolIds;
}

function calculateCompletedMonths(
  startDateInSeconds: number,
  endDateInSeconds: number,
): number {
  // 60 seconds * 60 minutes * 24 hours * 30 days
  // This is hardcoded because it's a constant value
  const secondsInMonth: number = 60 * 60 * 24 * 30;
  return Math.floor((endDateInSeconds - startDateInSeconds) / secondsInMonth);
}

async function calculateAllPoolAllocations(
  staking: Contract,
  totalPools: number,
  totalAmount: BigNumber,
): Promise<BigNumber[]> {
  // This value is hardcoded because it's a constant value
  const percentagePrecision: number = 10 ** 8;
  const allocations = [];

  // Loop through all pools and set the amount of tokens
  for (let poolId = 1; poolId <= totalPools; poolId++) {
    // Calculate the amount of tokens for the pool
    const poolTokens = await calculatePoolAllocation(
      staking,
      totalAmount,
      percentagePrecision,
      poolId,
    );

    allocations.push(poolTokens);
  }

  return allocations;
}

async function calculatePoolAllocation(
  staking: Contract,
  totalAmount: BigNumber,
  percentagePrecision: number,
  poolId: number,
): Promise<BigNumber> {
  const poolData = await staking.getPool(poolId);

  // totalAmount * (distribution% * 10**6) / (100% * 10**6)
  const poolTokens: BigNumber = totalAmount
    .mul(poolData.distributionPercentage)
    .div(percentagePrecision);

  return poolTokens;
}

async function calculateBandShares(
  band: StakerBand,
  endDateInSeconds: number,
  sharesInMonth: number[],
): Promise<number> {
  let bandShares: number = 0;

  // If staking type is FLEXI calculate shares based on months passed
  if (band.stakingType === StakingTypes.FLEXI) {
    // Calculate months that passed since staking started
    const monthsPassed = calculateCompletedMonths(
      band.stakingStartDate,
      endDateInSeconds,
    );

    // If at least 1 month passed, calculate shares based on months
    if (monthsPassed > 0) {
      bandShares = sharesInMonth[monthsPassed - 1];
    }
  }
  // Else type is FIX
  else {
    // For FIX type, shares are set at the start and do not change over time
    bandShares = band.fixedShares;
  }

  return bandShares;
}

// main().catch((err) => {
//   console.error(err);
// });
